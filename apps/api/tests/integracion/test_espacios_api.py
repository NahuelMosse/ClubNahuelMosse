"""`/espacios` contra la base y el emulador reales."""

from collections.abc import Callable, Iterator
from concurrent.futures import ThreadPoolExecutor

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.interfaz.sembrar_admin import main as sembrar

CONTRASENA = "ClubNahuel1"
DUPLICADO = "Ya existe un espacio deportivo con ese nombre en la sede seleccionada."


@pytest.fixture
def token_admin(
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> Iterator[str]:
    s = unico()
    monkeypatch.setenv("ADMIN_CONTRASENA", CONTRASENA)
    argumentos = [
        "--correo", f"admin.{s}@club.com", "--nombre", "Ana", "--apellido", "Díaz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--nacimiento", "1985-06-01",
    ]  # fmt: skip
    assert sembrar(argumentos) == 0
    token = iniciar_sesion(f"admin.{s}@club.com", CONTRASENA)
    assert token is not None
    yield token


@pytest.fixture
def token_usuario(
    api: TestClient,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> str:
    s = unico()
    pedido = {
        "nombre": "Martín",
        "apellido": "Ferreyra",
        "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        "fecha_nacimiento": "1994-07-21",
        "correo": f"socio.{s}@correo.com",
        "contrasena": CONTRASENA,
    }
    assert api.post("/registro", json=pedido).status_code == 201
    token = iniciar_sesion(f"socio.{s}@correo.com", CONTRASENA)
    assert token is not None
    return token


def _con(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def sede(api: TestClient, token_admin: str, unico: Callable[[], str]) -> tuple[int, str]:
    s = unico()
    r = api.post(
        "/sedes",
        headers=_con(token_admin),
        json={
            "nombre": f"Sede Haedo {s}",
            "direccion": "Av. Vergara 1850",
            "apertura": "08:00",
            "cierre": "23:00",
            "dias": [1, 2, 3, 4, 5, 6, 7],
        },
    )
    assert r.status_code == 201
    # El nombre compuesto junta las palabras con mayúscula inicial: «Haedo b489» → «HaedoB489».
    return r.json()["id"], f"Haedo{s[0].upper()}{s[1:]}_Vergara_1850"


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

    def nombres(**filtro: object) -> list[str]:
        r = api.get("/espacios", headers=_con(token_usuario), params={"sede_id": sede_id} | filtro)
        return [e["nombre"] for e in r.json()["espacios"]]

    assert nombres(deporte="Futbol") == [f"{prefijo}_Futbol_F5_1", f"{prefijo}_Futbol_F7_1"]
    assert nombres(deporte="Futbol", tipo="F7") == [f"{prefijo}_Futbol_F7_1"]
    assert nombres(deporte="Golf") == []
    assert nombres(tipo="F7") == [f"{prefijo}_Futbol_F7_1"]
    for malo in ({"deporte": ""}, {"tipo": ""}, {"deporte": "x" * 41}):
        r = api.get("/espacios", headers=_con(token_usuario), params={"sede_id": sede_id} | malo)
        assert r.status_code == 422
