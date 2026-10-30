"""`/espacios` contra la base y el emulador reales."""

from collections.abc import Callable
from concurrent.futures import ThreadPoolExecutor
from datetime import date, timedelta
from typing import Any

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.users.seed_admin import main as sembrar

CONTRASENA = "ClubNahuel1"
DUPLICADO = "Ya existe un espacio deportivo con ese nombre en la sede seleccionada."


def _con(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _espacio(sede_id: str, **cambios: object) -> dict[str, object]:
    return {
        "venue_id": sede_id,
        "sport": "Futbol",
        "kind": "F5",
        "covered": False,
        "lit": True,
        "price_per_hour": 38000,
    } | cambios


def test_el_alta_arma_el_nombre_y_guarda_el_rastro(
    api: TestClient, motor: Engine, token_admin: str, sede: tuple[str, str]
) -> None:
    sede_id, prefijo = sede
    sugerido = api.get(
        "/spaces/name",
        headers=_con(token_admin),
        params={"venue_id": sede_id, "sport": "Futbol", "kind": "F5"},
    )
    assert sugerido.json() == {"name": f"{prefijo}_Futbol_F5_1", "number": 1}

    r = api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id, number=1))

    assert r.status_code == 201
    assert r.json()["name"] == f"{prefijo}_Futbol_F5_1"
    with motor.connect() as conn:
        fila = conn.execute(
            text(
                "SELECT e.active, e.created_by IS NOT NULL, e.price_per_hour"
                " FROM space e WHERE e.id = :id"
            ),
            {"id": r.json()["id"]},
        ).one()
    assert tuple(fila) == (True, True, 38000)


def test_los_numeros_no_se_reutilizan_despues_de_una_baja(
    api: TestClient, motor: Engine, token_admin: str, sede: tuple[str, str]
) -> None:
    sede_id, prefijo = sede
    primero = api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id)).json()
    with motor.begin() as conn:
        conn.execute(
            text("UPDATE space SET active = false, deactivated_at = now() WHERE id = :id"),
            {"id": primero["id"]},
        )
    r = api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id))
    assert r.json()["name"] == f"{prefijo}_Futbol_F5_2"
    # Otro tipo tiene su propia numeración.
    r = api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id, kind="F7"))
    assert r.json()["name"] == f"{prefijo}_Futbol_F7_1"


def test_si_otro_alta_tomo_el_numero_vuelve_con_el_siguiente(
    api: TestClient, token_admin: str, sede: tuple[str, str]
) -> None:
    sede_id, prefijo = sede
    assert api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id)).is_success
    r = api.post(
        "/spaces",
        headers=_con(token_admin),
        json=_espacio(sede_id, number=1, covered=True),
    )
    assert r.status_code == 409
    assert r.json() == {
        "errors": {"name": DUPLICADO},
        "name": f"{prefijo}_Futbol_F5_2",
        "number": 2,
    }


def test_dos_altas_a_la_vez_toman_numeros_distintos(
    api: TestClient, token_admin: str, sede: tuple[str, str]
) -> None:
    sede_id, prefijo = sede
    with ThreadPoolExecutor(max_workers=3) as pool:
        respuestas = list(
            pool.map(
                lambda _: api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id)),
                range(3),
            )
        )
    assert sorted(r.json()["name"] for r in respuestas) == [
        f"{prefijo}_Futbol_F5_{n}" for n in (1, 2, 3)
    ]


def test_los_datos_invalidos_vuelven_con_el_mensaje_de_cada_campo(
    api: TestClient, token_admin: str, sede: tuple[str, str]
) -> None:
    sede_id, _ = sede
    r = api.post(
        "/spaces",
        headers=_con(token_admin),
        json=_espacio(sede_id, kind="PDL", price_per_hour=0),
    )
    assert r.status_code == 422
    assert r.json() == {
        "errors": {
            "kind": "Elegí un tipo de la lista",
            "price_per_hour": "Ingresá un precio entre $ 1 y $ 9.999.999",
        }
    }


def test_una_sede_dada_de_baja_no_recibe_espacios(
    api: TestClient, motor: Engine, token_admin: str, sede: tuple[str, str]
) -> None:
    sede_id, _ = sede
    with motor.begin() as conn:
        conn.execute(
            text("UPDATE venue SET active = false, deactivated_at = now() WHERE id = :id"),
            {"id": sede_id},
        )
    r = api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id))
    assert r.status_code == 422
    assert r.json() == {"errors": {"venue_id": "La sede ya no está disponible"}}


def test_los_usuarios_ven_los_espacios_activos_y_el_catalogo(
    api: TestClient,
    motor: Engine,
    token_admin: str,
    token_usuario: str,
    sede: tuple[str, str],
) -> None:
    sede_id, prefijo = sede
    f7 = api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id, kind="F7"))
    api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id))
    with motor.begin() as conn:
        conn.execute(
            text("UPDATE space SET active = false, deactivated_at = now() WHERE id = :id"),
            {"id": f7.json()["id"]},
        )

    r = api.get("/spaces", headers=_con(token_usuario))

    assert r.status_code == 200
    propios = [e["name"] for e in r.json()["spaces"] if e["name"].startswith(prefijo)]
    assert propios == [f"{prefijo}_Futbol_F5_1"]
    catalogo = api.get("/spaces/catalog", headers=_con(token_usuario)).json()
    futbol = next(d for d in catalogo["sports"] if d["key"] == "Futbol")
    assert {"key": "F5", "name": "Fútbol 5"} in futbol["kinds"]


def test_un_usuario_no_pide_nombres_de_espacios(
    api: TestClient, token_usuario: str, sede: tuple[str, str]
) -> None:
    r = api.get(
        "/spaces/name",
        headers=_con(token_usuario),
        params={"venue_id": sede[0], "sport": "Futbol", "kind": "F5"},
    )
    assert r.status_code == 403


def test_sin_sesion_no_hay_espacios(api: TestClient) -> None:
    assert api.get("/spaces").status_code == 401
    assert api.get("/spaces/catalog").status_code == 401
    assert api.post("/spaces", json={}).status_code == 401


def test_el_numero_saltea_un_nombre_que_ya_uso_otra_sede(
    api: TestClient, motor: Engine, token_admin: str, sede: tuple[str, str]
) -> None:
    sede_id, prefijo = sede
    assert api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id)).is_success
    with motor.begin() as conn:
        nombre, calle, altura = conn.execute(
            text("SELECT name, street, street_number FROM venue WHERE id = :id"), {"id": sede_id}
        ).one()
        conn.execute(
            text("UPDATE venue SET active = false, deactivated_at = now() WHERE id = :id"),
            {"id": sede_id},
        )
    # La misma sede vuelve a crearse igual: su primer Fútbol 5 no puede llamarse como el
    # de la dada de baja.
    otra = api.post(
        "/venues",
        headers=_con(token_admin),
        json={
            "name": nombre,
            "address": f"{calle} {altura}",
            "opens_at": "08:00",
            "closes_at": "23:00",
            "open_days": [1, 2, 3, 4, 5, 6, 7],
        },
    ).json()["id"]
    sugerido = api.get(
        "/spaces/name",
        headers=_con(token_admin),
        params={"venue_id": otra, "sport": "Futbol", "kind": "F5"},
    ).json()
    assert sugerido == {"name": f"{prefijo}_Futbol_F5_2", "number": 2}
    r = api.post("/spaces", headers=_con(token_admin), json=_espacio(otra, number=2))
    assert r.status_code == 201
    assert r.json()["name"] == f"{prefijo}_Futbol_F5_2"


def test_el_mismo_pedido_repetido_despues_de_un_corte_devuelve_el_espacio_ya_guardado(
    api: TestClient, token_admin: str, sede: tuple[str, str]
) -> None:
    sede_id, _ = sede
    primero = api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id, number=1))
    repetido = api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id, number=1))
    assert repetido.status_code == 201
    assert repetido.json() == primero.json()
    # Con otros datos no es el mismo pedido: el número está ocupado.
    distinto = api.post(
        "/spaces",
        headers=_con(token_admin),
        json=_espacio(sede_id, number=1, price_per_hour=40000),
    )
    assert distinto.status_code == 409
    assert distinto.json()["number"] == 2


def test_el_pedido_de_otro_administrador_no_se_toma_como_propio(
    api: TestClient,
    token_admin: str,
    sede: tuple[str, str],
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    sede_id, _ = sede
    s = unico()
    monkeypatch.setenv("ADMIN_CONTRASENA", CONTRASENA)
    argumentos = [
        "--correo", f"otro.{s}@club.com", "--nombre", "Luis", "--apellido", "Paz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--nacimiento", "1980-02-02",
    ]  # fmt: skip
    assert sembrar(argumentos) == 0
    otro = iniciar_sesion(f"otro.{s}@club.com", CONTRASENA)
    assert otro is not None
    assert api.post("/spaces", headers=_con(otro), json=_espacio(sede_id, number=1)).is_success
    r = api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id, number=1))
    assert r.status_code == 409


def test_se_filtran_los_espacios_de_una_sede_y_la_sede_dice_sus_deportes(
    api: TestClient,
    token_admin: str,
    token_usuario: str,
    sede: tuple[str, str],
    unico: Callable[[], str],
) -> None:
    sede_id, prefijo = sede
    otra = api.post(
        "/venues",
        headers=_con(token_admin),
        json={
            "name": f"Sede Castelar {unico()}",
            "address": "Av. Rivadavia 23500",
            "opens_at": "08:00",
            "closes_at": "22:00",
            "open_days": [1, 2, 3, 4, 5, 6, 7],
        },
    ).json()["id"]
    api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id, kind="F7"))
    api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id))
    api.post(
        "/spaces",
        headers=_con(token_admin),
        json=_espacio(sede_id, sport="Tenis", kind="PDL"),
    )
    api.post("/spaces", headers=_con(token_admin), json=_espacio(otra))

    r = api.get("/spaces", headers=_con(token_usuario), params={"venue_id": sede_id})

    assert [e["name"] for e in r.json()["spaces"]] == [
        f"{prefijo}_Futbol_F5_1",
        f"{prefijo}_Futbol_F7_1",
        f"{prefijo}_Tenis_PDL_1",
    ]
    sedes = {s["id"]: s for s in api.get("/venues", headers=_con(token_usuario)).json()["venues"]}
    assert (sedes[sede_id]["space_count"], sedes[sede_id]["sports"]) == (3, ["Futbol", "Tenis"])
    assert sedes[otra]["sports"] == ["Futbol"]


def test_se_filtran_los_espacios_por_deporte_y_tipo(
    api: TestClient, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> None:
    sede_id, prefijo = sede
    for cambios in ({}, {"kind": "F7"}, {"sport": "Hockey", "kind": "H7"}):
        api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id, **cambios))

    def nombres(**filtro: str) -> list[str]:
        params: dict[str, str | int] = {"venue_id": sede_id, **filtro}
        r = api.get("/spaces", headers=_con(token_usuario), params=params)
        return [e["name"] for e in r.json()["spaces"]]

    assert nombres(sport="Futbol") == [f"{prefijo}_Futbol_F5_1", f"{prefijo}_Futbol_F7_1"]
    assert nombres(sport="Futbol", kind="F7") == [f"{prefijo}_Futbol_F7_1"]
    assert nombres(sport="Golf") == []
    assert nombres(kind="F7") == [f"{prefijo}_Futbol_F7_1"]
    for malo in ({"sport": ""}, {"kind": ""}):
        params: dict[str, str | int] = {"venue_id": sede_id, **malo}
        r = api.get("/spaces", headers=_con(token_usuario), params=params)
        assert r.status_code == 422


def test_los_horarios_de_un_espacio_marcan_las_reservas_activas(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> None:
    sede_id, _ = sede
    espacio = api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id)).json()
    hoy = api.get(f"/spaces/{espacio['id']}/slots", headers=_con(token_usuario)).json()
    manana = date.fromisoformat(hoy["today"]) + timedelta(days=1)
    with motor.begin() as conn:
        for hora, estado in ((10, "active"), (12, "canceled")):
            conn.execute(
                text(
                    "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour,"
                    " total, status, canceled_at)"
                    " SELECT (SELECT id FROM app_user ORDER BY id LIMIT 1), :e, x.i,"
                    " x.i + interval '1 hour', 38000, 38000, :status,"
                    " CASE WHEN :status = 'canceled' THEN now() END FROM"
                    " (SELECT (CAST(:dia AS date) + make_interval(hours => :hora))"
                    " AT TIME ZONE 'America/Argentina/Buenos_Aires' AS i) x"
                ),
                {"e": espacio["id"], "dia": manana, "hora": hora, "status": estado},
            )

    r = api.get(
        f"/spaces/{espacio['id']}/slots",
        headers=_con(token_usuario),
        params={"date": manana.isoformat()},
    )

    assert r.status_code == 200
    franjas = {f["starts_at"]: f["available"] for f in r.json()["slots"]}
    assert (franjas["10:00"], franjas["11:00"], franjas["12:00"]) == (False, True, True)
    assert (r.json()["opens"], r.json()["unavailable"]) == (True, 1)
    assert r.json()["slots"][-1] == {"starts_at": "22:00", "ends_at": "23:00", "available": True}


def test_los_horarios_se_piden_con_sesion_y_dentro_de_la_semana(
    api: TestClient, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> None:
    sede_id, _ = sede
    espacio = api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id)).json()
    ruta = f"/spaces/{espacio['id']}/slots"
    hoy = date.fromisoformat(api.get(ruta, headers=_con(token_usuario)).json()["today"])

    assert api.get(ruta).status_code == 401
    lejos = {"date": (hoy + timedelta(days=7)).isoformat()}
    assert api.get(ruta, headers=_con(token_usuario), params=lejos).status_code == 422
    assert api.get(ruta, headers=_con(token_usuario), params={"hours": 5}).status_code == 422
    inexistente = "/spaces/00000000-0000-7000-8000-0000000000ff/slots"
    assert api.get(inexistente, headers=_con(token_usuario)).status_code == 404


def test_las_canchas_disponibles_son_las_libres_en_todo_el_rango(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> None:
    sede_id, prefijo = sede
    ids = [
        api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id, **c)).json()["id"]
        for c in ({}, {}, {"kind": "F7"})
    ]
    hoy = date.fromisoformat(
        api.get(f"/spaces/{ids[0]}/slots", headers=_con(token_usuario)).json()["today"]
    )
    manana = hoy + timedelta(days=1)
    with motor.begin() as conn:
        for espacio, hora in ((ids[0], 9), (ids[1], 11)):
            conn.execute(
                text(
                    "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour,"
                    " total) SELECT (SELECT id FROM app_user ORDER BY id LIMIT 1), :e, x.i,"
                    " x.i + interval '1 hour', 38000, 38000"
                    " FROM (SELECT (CAST(:dia AS date) + make_interval(hours => :h))"
                    " AT TIME ZONE 'America/Argentina/Buenos_Aires' AS i) x"
                ),
                {"e": espacio, "dia": manana, "h": hora},
            )
    consulta: dict[str, str | int] = {
        "venue_id": sede_id,
        "sport": "Futbol",
        "date": manana.isoformat(),
    }

    def nombres(**cambios: str) -> list[str]:
        r = api.get(
            "/spaces/available",
            headers=_con(token_usuario),
            params={**consulta, "since": "10:00", "until": "12:00", **cambios},
        )
        assert r.status_code == 200, r.text
        return [e["name"] for e in r.json()["spaces"]]

    assert nombres(kind="F5") == [f"{prefijo}_Futbol_F5_1"]
    assert nombres() == [f"{prefijo}_Futbol_F5_1", f"{prefijo}_Futbol_F7_1"]
    assert nombres(kind="F5", since="09:00", until="12:00") == []
    assert len(nombres(kind="F5", since="12:00", until="14:00")) == 2


def test_las_canchas_disponibles_rechazan_un_rango_invalido(
    api: TestClient, token_usuario: str, sede: tuple[str, str]
) -> None:
    sede_id, _ = sede
    base: dict[str, str | int] = {"venue_id": sede_id, "sport": "Futbol", "date": "2020-01-01"}

    r = api.get(
        "/spaces/available",
        headers=_con(token_usuario),
        params=base | {"since": "10:00", "until": "10:00"},
    )
    assert r.status_code == 422
    assert r.json()["errors"] == {
        "date": "La fecha tiene que ser futura",
        "until": "La duración mínima es de una hora",
    }
    r = api.get(
        "/spaces/available",
        headers=_con(token_usuario),
        params=base | {"since": "10", "until": "11:00"},
    )
    assert r.json()["errors"] == {"start_hour": "Elegí una hora en punto"}
    r = api.get(
        "/spaces/available",
        headers=_con(token_usuario),
        params=base
        | {"venue_id": "00000000-0000-7000-8000-000000000000", "since": "10:00", "until": "11:00"},
    )
    assert r.json()["errors"] == {"venue_id": "La sede ya no está disponible"}
    assert api.get("/spaces/available", params=base).status_code in (401, 422)


def test_editar_cambia_condicion_iluminacion_y_precio_sin_tocar_el_nombre_ni_las_reservas(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> None:
    sede_id, _ = sede
    alta = api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id)).json()
    with motor.begin() as conn:
        dueno: Any = conn.execute(text("SELECT id FROM app_user ORDER BY id LIMIT 1")).scalar_one()
        conn.execute(
            text(
                "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
                " SELECT :u, :e, i, i + interval '1 hour', :p, :p"
                " FROM (SELECT date_trunc('hour', now()) + interval '1 day' AS i) x"
            ),
            {"u": dueno, "e": alta["id"], "p": alta["price_per_hour"]},
        )
    cambio = {"covered": not alta["covered"], "lit": False, "price_per_hour": 45000}

    r = api.put(f"/spaces/{alta['id']}", headers=_con(token_admin), json=cambio)

    assert r.status_code == 200
    assert r.json() == alta | cambio
    with motor.connect() as conn:
        fila = conn.execute(
            text(
                "SELECT e.updated_by IS NOT NULL, r.total FROM space e"
                " JOIN booking r ON r.space_id = e.id WHERE e.id = :id"
            ),
            {"id": alta["id"]},
        ).one()
    assert tuple(fila) == (True, alta["price_per_hour"])
    assert (
        api.put(f"/spaces/{alta['id']}", headers=_con(token_usuario), json=cambio).status_code
        == 403
    )


def test_editar_rechaza_un_precio_invalido_y_un_espacio_dado_de_baja(
    api: TestClient, motor: Engine, token_admin: str, sede: tuple[str, str]
) -> None:
    sede_id, _ = sede
    alta = api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id)).json()
    ruta = f"/spaces/{alta['id']}"

    for precio, mensaje in [
        (None, "Este campo es obligatorio"),
        (0, "Ingresá un precio entre $ 1 y $ 9.999.999"),
        (10_000_000, "Ingresá un precio entre $ 1 y $ 9.999.999"),
    ]:
        r = api.put(
            ruta,
            headers=_con(token_admin),
            json={"covered": True, "lit": True, "price_per_hour": precio},
        )
        assert r.status_code == 422
        assert r.json()["errors"] == {"price_per_hour": mensaje}
    with motor.begin() as conn:
        conn.execute(
            text("UPDATE space SET active = false, deactivated_at = now() WHERE id = :id"),
            {"id": alta["id"]},
        )
    valido = {"covered": True, "lit": True, "price_per_hour": 45000}
    assert api.put(ruta, headers=_con(token_admin), json=valido).status_code == 404


def test_editar_sin_un_campo_lo_deja_como_estaba(
    api: TestClient, token_admin: str, sede: tuple[str, str]
) -> None:
    sede_id, _ = sede
    alta = api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id)).json()
    ruta = f"/spaces/{alta['id']}"

    # Otro administrador cambió el precio; éste sólo cambia la condición.
    assert (
        api.put(ruta, headers=_con(token_admin), json={"price_per_hour": 50000}).status_code == 200
    )
    r = api.put(ruta, headers=_con(token_admin), json={"covered": not alta["covered"]})

    assert r.status_code == 200
    assert (r.json()["price_per_hour"], r.json()["covered"]) == (50000, not alta["covered"])
    vacio = api.put(ruta, headers=_con(token_admin), json={})
    assert vacio.status_code == 422
    assert vacio.json()["errors"] == {"change": "No hay nada que cambiar"}


def test_la_baja_deja_el_espacio_inactivo_con_su_rastro_y_la_sede_con_uno_menos(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> None:
    sede_id, _ = sede
    uno = api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id)).json()
    ruta = f"/spaces/{uno['id']}"
    assert api.delete(ruta, headers=_con(token_usuario)).status_code == 403
    assert api.delete(ruta).status_code == 401

    assert api.delete(ruta, headers=_con(token_admin)).status_code == 204

    with motor.connect() as conn:
        fila = conn.execute(
            text(
                "SELECT active, deactivated_at IS NOT NULL, deactivated_by IS NOT NULL"
                " FROM space WHERE id = :id"
            ),
            {"id": uno["id"]},
        ).one()
    assert tuple(fila) == (False, True, True)
    espacios = api.get("/spaces", headers=_con(token_usuario)).json()["spaces"]
    assert uno["id"] not in [e["id"] for e in espacios]
    assert api.delete(ruta, headers=_con(token_admin)).status_code == 404


def test_no_se_da_de_baja_un_espacio_con_una_reserva_sin_terminar(
    api: TestClient, motor: Engine, token_admin: str, sede: tuple[str, str]
) -> None:
    sede_id, _ = sede
    uno = api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id)).json()
    with motor.begin() as conn:
        dueno: Any = conn.execute(text("SELECT id FROM app_user ORDER BY id LIMIT 1")).scalar_one()
        # Una en curso: empezó en esta hora y termina en dos.
        conn.execute(
            text(
                "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour, total)"
                " SELECT :u, :e, i, i + interval '2 hours', 38000, 76000"
                " FROM (SELECT date_trunc('hour', now()) AS i) x"
            ),
            {"u": dueno, "e": uno["id"]},
        )

    r = api.delete(f"/spaces/{uno['id']}", headers=_con(token_admin))

    assert r.status_code == 409
    assert r.json() == {
        "errors": {"space": "No se puede dar de baja el espacio porque posee reservas futuras."}
    }
    with motor.connect() as conn:
        assert conn.execute(
            text("SELECT active FROM space WHERE id = :id"), {"id": uno["id"]}
        ).scalar_one()


def test_la_baja_mira_solo_reservas_activas_que_no_terminaron(
    api: TestClient, motor: Engine, token_admin: str, sede: tuple[str, str]
) -> None:
    sede_id, _ = sede

    def con_reserva(desde: str, estado: str) -> str:
        espacio = api.post("/spaces", headers=_con(token_admin), json=_espacio(sede_id)).json()
        with motor.begin() as conn:
            dueno: Any = conn.execute(
                text("SELECT id FROM app_user ORDER BY id LIMIT 1")
            ).scalar_one()
            conn.execute(
                text(
                    "INSERT INTO booking (user_id, space_id, starts_at, ends_at, price_per_hour,"
                    " total, status, canceled_at)"
                    " SELECT :u, :e, i, i + interval '1 hour', 38000, 38000, :status,"
                    " CASE WHEN :status <> 'active' THEN now() END"
                    f" FROM (SELECT date_trunc('hour', now()) + interval '{desde}' AS i) x"
                ),
                {"u": dueno, "e": espacio["id"], "status": estado},
            )
        return str(espacio["id"])

    futura = con_reserva("1 day", "active")
    terminada = con_reserva("-1 day", "active")
    cancelada = con_reserva("1 day", "canceled")

    assert api.delete(f"/spaces/{futura}", headers=_con(token_admin)).status_code == 409
    assert api.delete(f"/spaces/{terminada}", headers=_con(token_admin)).status_code == 204
    assert api.delete(f"/spaces/{cancelada}", headers=_con(token_admin)).status_code == 204
