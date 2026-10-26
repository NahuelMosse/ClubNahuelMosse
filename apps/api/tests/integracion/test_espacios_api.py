"""`/espacios` contra la base y el emulador reales."""

from collections.abc import Callable
from concurrent.futures import ThreadPoolExecutor
from datetime import date, timedelta
from typing import Any

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.usuarios.sembrar_admin import main as sembrar

CONTRASENA = "ClubNahuel1"
DUPLICADO = "Ya existe un espacio deportivo con ese nombre en la sede seleccionada."


def _con(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _espacio(sede_id: int, **cambios: object) -> dict[str, object]:
    return {
        "sede_id": sede_id,
        "deporte": "Futbol",
        "tipo": "F5",
        "techada": False,
        "iluminada": True,
        "precio_por_hora": 38000,
    } | cambios


def test_el_alta_arma_el_nombre_y_guarda_el_rastro(
    api: TestClient, motor: Engine, token_admin: str, sede: tuple[int, str]
) -> None:
    sede_id, prefijo = sede
    sugerido = api.get(
        "/espacios/nombre",
        headers=_con(token_admin),
        params={"sede_id": sede_id, "deporte": "Futbol", "tipo": "F5"},
    )
    assert sugerido.json() == {"nombre": f"{prefijo}_Futbol_F5_1", "numero": 1}

    r = api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id, numero=1))

    assert r.status_code == 201
    assert r.json()["nombre"] == f"{prefijo}_Futbol_F5_1"
    with motor.connect() as conn:
        fila = conn.execute(
            text(
                "SELECT e.activo, e.creado_por IS NOT NULL, e.precio_por_hora"
                " FROM espacio e WHERE e.id = :id"
            ),
            {"id": r.json()["id"]},
        ).one()
    assert tuple(fila) == (True, True, 38000)


def test_los_numeros_no_se_reutilizan_despues_de_una_baja(
    api: TestClient, motor: Engine, token_admin: str, sede: tuple[int, str]
) -> None:
    sede_id, prefijo = sede
    primero = api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id)).json()
    with motor.begin() as conn:
        conn.execute(
            text("UPDATE espacio SET activo = false, dado_de_baja_en = now() WHERE id = :id"),
            {"id": primero["id"]},
        )
    r = api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id))
    assert r.json()["nombre"] == f"{prefijo}_Futbol_F5_2"
    # Otro tipo tiene su propia numeración.
    r = api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id, tipo="F7"))
    assert r.json()["nombre"] == f"{prefijo}_Futbol_F7_1"


def test_si_otro_alta_tomo_el_numero_vuelve_con_el_siguiente(
    api: TestClient, token_admin: str, sede: tuple[int, str]
) -> None:
    sede_id, prefijo = sede
    assert api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id)).is_success
    r = api.post(
        "/espacios",
        headers=_con(token_admin),
        json=_espacio(sede_id, numero=1, techada=True),
    )
    assert r.status_code == 409
    assert r.json() == {
        "errores": {"nombre": DUPLICADO},
        "nombre": f"{prefijo}_Futbol_F5_2",
        "numero": 2,
    }


def test_dos_altas_a_la_vez_toman_numeros_distintos(
    api: TestClient, token_admin: str, sede: tuple[int, str]
) -> None:
    sede_id, prefijo = sede
    with ThreadPoolExecutor(max_workers=3) as pool:
        respuestas = list(
            pool.map(
                lambda _: api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id)),
                range(3),
            )
        )
    assert sorted(r.json()["nombre"] for r in respuestas) == [
        f"{prefijo}_Futbol_F5_{n}" for n in (1, 2, 3)
    ]


def test_los_datos_invalidos_vuelven_con_el_mensaje_de_cada_campo(
    api: TestClient, token_admin: str, sede: tuple[int, str]
) -> None:
    sede_id, _ = sede
    r = api.post(
        "/espacios",
        headers=_con(token_admin),
        json=_espacio(sede_id, tipo="PDL", precio_por_hora=0),
    )
    assert r.status_code == 422
    assert r.json() == {
        "errores": {
            "tipo": "Elegí un tipo de la lista",
            "precio_por_hora": "Ingresá un precio entre $ 1 y $ 9.999.999",
        }
    }


def test_una_sede_dada_de_baja_no_recibe_espacios(
    api: TestClient, motor: Engine, token_admin: str, sede: tuple[int, str]
) -> None:
    sede_id, _ = sede
    with motor.begin() as conn:
        conn.execute(
            text("UPDATE sede SET activa = false, dado_de_baja_en = now() WHERE id = :id"),
            {"id": sede_id},
        )
    r = api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id))
    assert r.status_code == 422
    assert r.json() == {"errores": {"sede_id": "La sede ya no está disponible"}}


def test_los_usuarios_ven_los_espacios_activos_y_el_catalogo(
    api: TestClient,
    motor: Engine,
    token_admin: str,
    token_usuario: str,
    sede: tuple[int, str],
) -> None:
    sede_id, prefijo = sede
    f7 = api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id, tipo="F7"))
    api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id))
    with motor.begin() as conn:
        conn.execute(
            text("UPDATE espacio SET activo = false, dado_de_baja_en = now() WHERE id = :id"),
            {"id": f7.json()["id"]},
        )

    r = api.get("/espacios", headers=_con(token_usuario))

    assert r.status_code == 200
    propios = [e["nombre"] for e in r.json()["espacios"] if e["nombre"].startswith(prefijo)]
    assert propios == [f"{prefijo}_Futbol_F5_1"]
    catalogo = api.get("/espacios/catalogo", headers=_con(token_usuario)).json()
    futbol = next(d for d in catalogo["deportes"] if d["clave"] == "Futbol")
    assert {"clave": "F5", "nombre": "Fútbol 5"} in futbol["tipos"]


def test_un_usuario_no_pide_nombres_de_espacios(
    api: TestClient, token_usuario: str, sede: tuple[int, str]
) -> None:
    r = api.get(
        "/espacios/nombre",
        headers=_con(token_usuario),
        params={"sede_id": sede[0], "deporte": "Futbol", "tipo": "F5"},
    )
    assert r.status_code == 403


def test_sin_sesion_no_hay_espacios(api: TestClient) -> None:
    assert api.get("/espacios").status_code == 401
    assert api.get("/espacios/catalogo").status_code == 401
    assert api.post("/espacios", json={}).status_code == 401


def test_el_numero_saltea_un_nombre_que_ya_uso_otra_sede(
    api: TestClient, motor: Engine, token_admin: str, sede: tuple[int, str]
) -> None:
    sede_id, prefijo = sede
    assert api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id)).is_success
    with motor.begin() as conn:
        nombre, calle, altura = conn.execute(
            text("SELECT nombre, calle, altura FROM sede WHERE id = :id"), {"id": sede_id}
        ).one()
        conn.execute(
            text("UPDATE sede SET activa = false, dado_de_baja_en = now() WHERE id = :id"),
            {"id": sede_id},
        )
    # La misma sede vuelve a crearse igual: su primer Fútbol 5 no puede llamarse como el
    # de la dada de baja.
    otra = api.post(
        "/sedes",
        headers=_con(token_admin),
        json={
            "nombre": nombre,
            "direccion": f"{calle} {altura}",
            "apertura": "08:00",
            "cierre": "23:00",
            "dias": [1, 2, 3, 4, 5, 6, 7],
        },
    ).json()["id"]
    sugerido = api.get(
        "/espacios/nombre",
        headers=_con(token_admin),
        params={"sede_id": otra, "deporte": "Futbol", "tipo": "F5"},
    ).json()
    assert sugerido == {"nombre": f"{prefijo}_Futbol_F5_2", "numero": 2}
    r = api.post("/espacios", headers=_con(token_admin), json=_espacio(otra, numero=2))
    assert r.status_code == 201
    assert r.json()["nombre"] == f"{prefijo}_Futbol_F5_2"


def test_el_mismo_pedido_repetido_despues_de_un_corte_devuelve_el_espacio_ya_guardado(
    api: TestClient, token_admin: str, sede: tuple[int, str]
) -> None:
    sede_id, _ = sede
    primero = api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id, numero=1))
    repetido = api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id, numero=1))
    assert repetido.status_code == 201
    assert repetido.json() == primero.json()
    # Con otros datos no es el mismo pedido: el número está ocupado.
    distinto = api.post(
        "/espacios",
        headers=_con(token_admin),
        json=_espacio(sede_id, numero=1, precio_por_hora=40000),
    )
    assert distinto.status_code == 409
    assert distinto.json()["numero"] == 2


def test_el_pedido_de_otro_administrador_no_se_toma_como_propio(
    api: TestClient,
    token_admin: str,
    sede: tuple[int, str],
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
    assert api.post("/espacios", headers=_con(otro), json=_espacio(sede_id, numero=1)).is_success
    r = api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id, numero=1))
    assert r.status_code == 409


def test_se_filtran_los_espacios_de_una_sede_y_la_sede_dice_sus_deportes(
    api: TestClient,
    token_admin: str,
    token_usuario: str,
    sede: tuple[int, str],
    unico: Callable[[], str],
) -> None:
    sede_id, prefijo = sede
    otra = api.post(
        "/sedes",
        headers=_con(token_admin),
        json={
            "nombre": f"Sede Castelar {unico()}",
            "direccion": "Av. Rivadavia 23500",
            "apertura": "08:00",
            "cierre": "22:00",
            "dias": [1, 2, 3, 4, 5, 6, 7],
        },
    ).json()["id"]
    api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id, tipo="F7"))
    api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id))
    api.post(
        "/espacios",
        headers=_con(token_admin),
        json=_espacio(sede_id, deporte="Tenis", tipo="PDL"),
    )
    api.post("/espacios", headers=_con(token_admin), json=_espacio(otra))

    r = api.get("/espacios", headers=_con(token_usuario), params={"sede_id": sede_id})

    assert [e["nombre"] for e in r.json()["espacios"]] == [
        f"{prefijo}_Futbol_F5_1",
        f"{prefijo}_Futbol_F7_1",
        f"{prefijo}_Tenis_PDL_1",
    ]
    sedes = {s["id"]: s for s in api.get("/sedes", headers=_con(token_usuario)).json()["sedes"]}
    assert (sedes[sede_id]["canchas"], sedes[sede_id]["deportes"]) == (3, ["Futbol", "Tenis"])
    assert sedes[otra]["deportes"] == ["Futbol"]


def test_se_filtran_los_espacios_por_deporte_y_tipo(
    api: TestClient, token_admin: str, token_usuario: str, sede: tuple[int, str]
) -> None:
    sede_id, prefijo = sede
    for cambios in ({}, {"tipo": "F7"}, {"deporte": "Hockey", "tipo": "H7"}):
        api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id, **cambios))

    def nombres(**filtro: str) -> list[str]:
        params: dict[str, str | int] = {"sede_id": sede_id, **filtro}
        r = api.get("/espacios", headers=_con(token_usuario), params=params)
        return [e["nombre"] for e in r.json()["espacios"]]

    assert nombres(deporte="Futbol") == [f"{prefijo}_Futbol_F5_1", f"{prefijo}_Futbol_F7_1"]
    assert nombres(deporte="Futbol", tipo="F7") == [f"{prefijo}_Futbol_F7_1"]
    assert nombres(deporte="Golf") == []
    assert nombres(tipo="F7") == [f"{prefijo}_Futbol_F7_1"]
    for malo in ({"deporte": ""}, {"tipo": ""}):
        params: dict[str, str | int] = {"sede_id": sede_id, **malo}
        r = api.get("/espacios", headers=_con(token_usuario), params=params)
        assert r.status_code == 422


def test_los_horarios_de_un_espacio_marcan_las_reservas_activas(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[int, str]
) -> None:
    sede_id, _ = sede
    espacio = api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id)).json()
    hoy = api.get(f"/espacios/{espacio['id']}/horarios", headers=_con(token_usuario)).json()
    manana = date.fromisoformat(hoy["hoy"]) + timedelta(days=1)
    with motor.begin() as conn:
        for hora, estado in ((10, "activa"), (12, "cancelada")):
            conn.execute(
                text(
                    "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora,"
                    " total, estado, cancelada_en)"
                    " SELECT min(id), :e, x.i, x.i + interval '1 hour', 38000, 38000, :estado,"
                    " CASE WHEN :estado = 'cancelada' THEN now() END FROM usuario,"
                    " (SELECT (CAST(:dia AS date) + make_interval(hours => :hora))"
                    " AT TIME ZONE 'America/Argentina/Buenos_Aires' AS i) x GROUP BY x.i"
                ),
                {"e": espacio["id"], "dia": manana, "hora": hora, "estado": estado},
            )

    r = api.get(
        f"/espacios/{espacio['id']}/horarios",
        headers=_con(token_usuario),
        params={"fecha": manana.isoformat()},
    )

    assert r.status_code == 200
    franjas = {f["inicio"]: f["disponible"] for f in r.json()["franjas"]}
    assert (franjas["10:00"], franjas["11:00"], franjas["12:00"]) == (False, True, True)
    assert (r.json()["abre"], r.json()["no_disponibles"]) == (True, 1)
    assert r.json()["franjas"][-1] == {"inicio": "22:00", "fin": "23:00", "disponible": True}


def test_los_horarios_se_piden_con_sesion_y_dentro_de_la_semana(
    api: TestClient, token_admin: str, token_usuario: str, sede: tuple[int, str]
) -> None:
    sede_id, _ = sede
    espacio = api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id)).json()
    ruta = f"/espacios/{espacio['id']}/horarios"
    hoy = date.fromisoformat(api.get(ruta, headers=_con(token_usuario)).json()["hoy"])

    assert api.get(ruta).status_code == 401
    lejos = {"fecha": (hoy + timedelta(days=7)).isoformat()}
    assert api.get(ruta, headers=_con(token_usuario), params=lejos).status_code == 422
    assert api.get(ruta, headers=_con(token_usuario), params={"horas": 5}).status_code == 422
    assert api.get("/espacios/999999999/horarios", headers=_con(token_usuario)).status_code == 404


def test_las_canchas_disponibles_son_las_libres_en_todo_el_rango(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[int, str]
) -> None:
    sede_id, prefijo = sede
    ids = [
        api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id, **c)).json()["id"]
        for c in ({}, {}, {"tipo": "F7"})
    ]
    hoy = date.fromisoformat(
        api.get(f"/espacios/{ids[0]}/horarios", headers=_con(token_usuario)).json()["hoy"]
    )
    manana = hoy + timedelta(days=1)
    with motor.begin() as conn:
        for espacio, hora in ((ids[0], 9), (ids[1], 11)):
            conn.execute(
                text(
                    "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora,"
                    " total) SELECT min(id), :e, x.i, x.i + interval '1 hour', 38000, 38000"
                    " FROM usuario, (SELECT (CAST(:dia AS date) + make_interval(hours => :h))"
                    " AT TIME ZONE 'America/Argentina/Buenos_Aires' AS i) x GROUP BY x.i"
                ),
                {"e": espacio, "dia": manana, "h": hora},
            )
    consulta: dict[str, str | int] = {
        "sede_id": sede_id,
        "deporte": "Futbol",
        "fecha": manana.isoformat(),
    }

    def nombres(**cambios: str) -> list[str]:
        r = api.get(
            "/espacios/disponibles",
            headers=_con(token_usuario),
            params={**consulta, "desde": "10:00", "hasta": "12:00", **cambios},
        )
        assert r.status_code == 200, r.text
        return [e["nombre"] for e in r.json()["espacios"]]

    assert nombres(tipo="F5") == [f"{prefijo}_Futbol_F5_1"]
    assert nombres() == [f"{prefijo}_Futbol_F5_1", f"{prefijo}_Futbol_F7_1"]
    assert nombres(tipo="F5", desde="09:00", hasta="12:00") == []
    assert len(nombres(tipo="F5", desde="12:00", hasta="14:00")) == 2


def test_las_canchas_disponibles_rechazan_un_rango_invalido(
    api: TestClient, token_usuario: str, sede: tuple[int, str]
) -> None:
    sede_id, _ = sede
    base: dict[str, str | int] = {"sede_id": sede_id, "deporte": "Futbol", "fecha": "2020-01-01"}

    r = api.get(
        "/espacios/disponibles",
        headers=_con(token_usuario),
        params=base | {"desde": "10:00", "hasta": "10:00"},
    )
    assert r.status_code == 422
    assert r.json()["errores"] == {
        "fecha": "La fecha tiene que ser futura",
        "hasta": "La duración mínima es de una hora",
    }
    r = api.get(
        "/espacios/disponibles",
        headers=_con(token_usuario),
        params=base | {"desde": "10", "hasta": "11:00"},
    )
    assert r.json()["errores"] == {"desde": "Elegí una hora en punto"}
    r = api.get(
        "/espacios/disponibles",
        headers=_con(token_usuario),
        params=base | {"sede_id": 999999999, "desde": "10:00", "hasta": "11:00"},
    )
    assert r.json()["errores"] == {"sede_id": "La sede ya no está disponible"}
    assert api.get("/espacios/disponibles", params=base).status_code in (401, 422)


def test_editar_cambia_condicion_iluminacion_y_precio_sin_tocar_el_nombre_ni_las_reservas(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[int, str]
) -> None:
    sede_id, _ = sede
    alta = api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id)).json()
    with motor.begin() as conn:
        dueno: Any = conn.execute(text("SELECT min(id) FROM usuario")).scalar_one()
        conn.execute(
            text(
                "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total)"
                " SELECT :u, :e, i, i + interval '1 hour', :p, :p"
                " FROM (SELECT date_trunc('hour', now()) + interval '1 day' AS i) x"
            ),
            {"u": dueno, "e": alta["id"], "p": alta["precio_por_hora"]},
        )
    cambio = {"techada": not alta["techada"], "iluminada": False, "precio_por_hora": 45000}

    r = api.put(f"/espacios/{alta['id']}", headers=_con(token_admin), json=cambio)

    assert r.status_code == 200
    assert r.json() == alta | cambio
    with motor.connect() as conn:
        fila = conn.execute(
            text(
                "SELECT e.modificado_por IS NOT NULL, r.total FROM espacio e"
                " JOIN reserva r ON r.espacio_id = e.id WHERE e.id = :id"
            ),
            {"id": alta["id"]},
        ).one()
    assert tuple(fila) == (True, alta["precio_por_hora"])
    assert (
        api.put(f"/espacios/{alta['id']}", headers=_con(token_usuario), json=cambio).status_code
        == 403
    )


def test_editar_rechaza_un_precio_invalido_y_un_espacio_dado_de_baja(
    api: TestClient, motor: Engine, token_admin: str, sede: tuple[int, str]
) -> None:
    sede_id, _ = sede
    alta = api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id)).json()
    ruta = f"/espacios/{alta['id']}"

    for precio, mensaje in [
        (None, "Este campo es obligatorio"),
        (0, "Ingresá un precio entre $ 1 y $ 9.999.999"),
        (10_000_000, "Ingresá un precio entre $ 1 y $ 9.999.999"),
    ]:
        r = api.put(
            ruta,
            headers=_con(token_admin),
            json={"techada": True, "iluminada": True, "precio_por_hora": precio},
        )
        assert r.status_code == 422
        assert r.json()["errores"] == {"precio_por_hora": mensaje}
    with motor.begin() as conn:
        conn.execute(
            text("UPDATE espacio SET activo = false, dado_de_baja_en = now() WHERE id = :id"),
            {"id": alta["id"]},
        )
    valido = {"techada": True, "iluminada": True, "precio_por_hora": 45000}
    assert api.put(ruta, headers=_con(token_admin), json=valido).status_code == 404


def test_editar_sin_un_campo_lo_deja_como_estaba(
    api: TestClient, token_admin: str, sede: tuple[int, str]
) -> None:
    sede_id, _ = sede
    alta = api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id)).json()
    ruta = f"/espacios/{alta['id']}"

    # Otro administrador cambió el precio; éste sólo cambia la condición.
    assert (
        api.put(ruta, headers=_con(token_admin), json={"precio_por_hora": 50000}).status_code == 200
    )
    r = api.put(ruta, headers=_con(token_admin), json={"techada": not alta["techada"]})

    assert r.status_code == 200
    assert (r.json()["precio_por_hora"], r.json()["techada"]) == (50000, not alta["techada"])
    vacio = api.put(ruta, headers=_con(token_admin), json={})
    assert vacio.status_code == 422
    assert vacio.json()["errores"] == {"cambio": "No hay nada que cambiar"}


def test_la_baja_deja_el_espacio_inactivo_con_su_rastro_y_la_sede_con_uno_menos(
    api: TestClient, motor: Engine, token_admin: str, token_usuario: str, sede: tuple[int, str]
) -> None:
    sede_id, _ = sede
    uno = api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id)).json()
    ruta = f"/espacios/{uno['id']}"
    assert api.delete(ruta, headers=_con(token_usuario)).status_code == 403
    assert api.delete(ruta).status_code == 401

    assert api.delete(ruta, headers=_con(token_admin)).status_code == 204

    with motor.connect() as conn:
        fila = conn.execute(
            text(
                "SELECT activo, dado_de_baja_en IS NOT NULL, dado_de_baja_por IS NOT NULL"
                " FROM espacio WHERE id = :id"
            ),
            {"id": uno["id"]},
        ).one()
    assert tuple(fila) == (False, True, True)
    espacios = api.get("/espacios", headers=_con(token_usuario)).json()["espacios"]
    assert uno["id"] not in [e["id"] for e in espacios]
    assert api.delete(ruta, headers=_con(token_admin)).status_code == 404


def test_no_se_da_de_baja_un_espacio_con_una_reserva_sin_terminar(
    api: TestClient, motor: Engine, token_admin: str, sede: tuple[int, str]
) -> None:
    sede_id, _ = sede
    uno = api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id)).json()
    with motor.begin() as conn:
        dueno: Any = conn.execute(text("SELECT min(id) FROM usuario")).scalar_one()
        # Una en curso: empezó en esta hora y termina en dos.
        conn.execute(
            text(
                "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total)"
                " SELECT :u, :e, i, i + interval '2 hours', 38000, 76000"
                " FROM (SELECT date_trunc('hour', now()) AS i) x"
            ),
            {"u": dueno, "e": uno["id"]},
        )

    r = api.delete(f"/espacios/{uno['id']}", headers=_con(token_admin))

    assert r.status_code == 409
    assert r.json() == {
        "errores": {"espacio": "No se puede dar de baja el espacio porque posee reservas futuras."}
    }
    with motor.connect() as conn:
        assert conn.execute(
            text("SELECT activo FROM espacio WHERE id = :id"), {"id": uno["id"]}
        ).scalar_one()


def test_la_baja_mira_solo_reservas_activas_que_no_terminaron(
    api: TestClient, motor: Engine, token_admin: str, sede: tuple[int, str]
) -> None:
    sede_id, _ = sede

    def con_reserva(desde: str, estado: str) -> int:
        espacio = api.post("/espacios", headers=_con(token_admin), json=_espacio(sede_id)).json()
        with motor.begin() as conn:
            dueno: Any = conn.execute(text("SELECT min(id) FROM usuario")).scalar_one()
            conn.execute(
                text(
                    "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora,"
                    " total, estado, cancelada_en)"
                    " SELECT :u, :e, i, i + interval '1 hour', 38000, 38000, :estado,"
                    " CASE WHEN :estado <> 'activa' THEN now() END"
                    f" FROM (SELECT date_trunc('hour', now()) + interval '{desde}' AS i) x"
                ),
                {"u": dueno, "e": espacio["id"], "estado": estado},
            )
        return int(espacio["id"])

    futura = con_reserva("1 day", "activa")
    terminada = con_reserva("-1 day", "activa")
    cancelada = con_reserva("1 day", "cancelada")

    assert api.delete(f"/espacios/{futura}", headers=_con(token_admin)).status_code == 409
    assert api.delete(f"/espacios/{terminada}", headers=_con(token_admin)).status_code == 204
    assert api.delete(f"/espacios/{cancelada}", headers=_con(token_admin)).status_code == 204
