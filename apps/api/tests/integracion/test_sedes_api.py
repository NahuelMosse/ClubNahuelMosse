"""`/sedes` contra la base y el emulador reales."""

from collections.abc import Callable, Iterator
from concurrent.futures import ThreadPoolExecutor

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.interfaz.sembrar_admin import main as sembrar

CONTRASENA = "ClubNahuel1"


@pytest.fixture
def token_admin(
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> Iterator[str]:
    s = unico()
    correo = f"admin.{s}@club.com"
    monkeypatch.setenv("ADMIN_CONTRASENA", CONTRASENA)
    argumentos = [
        "--correo", correo, "--nombre", "Ana", "--apellido", "Díaz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--nacimiento", "1985-06-01",
    ]  # fmt: skip
    assert sembrar(argumentos) == 0
    token = iniciar_sesion(correo, CONTRASENA)
    assert token is not None
    yield token


@pytest.fixture
def token_usuario(
    api: TestClient,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> str:
    s = unico()
    correo = f"socio.{s}@correo.com"
    pedido = {
        "nombre": "Martín",
        "apellido": "Ferreyra",
        "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        "fecha_nacimiento": "1994-07-21",
        "correo": correo,
        "contrasena": CONTRASENA,
    }
    assert api.post("/registro", json=pedido).status_code == 201
    token = iniciar_sesion(correo, CONTRASENA)
    assert token is not None
    return token


def _sede(nombre: str, **cambios: object) -> dict[str, object]:
    return {
        "nombre": nombre,
        "direccion": "Av. Vergara 1850",
        "apertura": "08:00",
        "cierre": "23:00",
        "dias": [1, 2, 3, 4, 5, 6],
    } | cambios


def _con(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def test_el_alta_guarda_la_sede_con_su_rastro_y_la_devuelve(
    api: TestClient, motor: Engine, token_admin: str, unico: Callable[[], str]
) -> None:
    nombre = f"Sede Haedo {unico()}"
    r = api.post("/sedes", headers=_con(token_admin), json=_sede(nombre))
    assert r.status_code == 201
    assert r.json() | {"id": 0} == {
        "id": 0,
        "nombre": nombre,
        "direccion": "Av. Vergara 1850",
        "apertura": "08:00",
        "cierre": "23:00",
        "dias": [1, 2, 3, 4, 5, 6],
        "canchas": 0,
        "deportes": [],
    }
    with motor.connect() as conn:
        fila = conn.execute(
            text(
                "SELECT s.calle, s.altura, s.activa, s.creado_en IS NOT NULL AS con_fecha,"
                " u.correo LIKE 'admin.%' AS por_admin"
                " FROM sede s JOIN usuario u ON u.id = s.creado_por WHERE s.id = :id"
            ),
            {"id": r.json()["id"]},
        ).one()
    assert tuple(fila) == ("Av. Vergara", 1850, True, True, True)


def test_los_usuarios_ven_las_sedes_por_nombre_con_sus_canchas(
    api: TestClient,
    motor: Engine,
    token_admin: str,
    token_usuario: str,
    unico: Callable[[], str],
) -> None:
    s = unico()
    zeta = api.post("/sedes", headers=_con(token_admin), json=_sede(f"zz Sede {s}")).json()
    api.post("/sedes", headers=_con(token_admin), json=_sede(f"ZY Sede {s}"))
    with motor.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO espacio (sede_id, deporte, tipo, numero, nombre, precio_por_hora,"
                " techada, iluminada) VALUES (:sede, 'Padel', 'PAD', 1, :n, 30000, true, true)"
            ),
            {"sede": zeta["id"], "n": f"Zz_Vergara_1850_Padel_PAD_1_{s}"},
        )

    r = api.get("/sedes", headers=_con(token_usuario))

    assert r.status_code == 200
    propias = [x for x in r.json()["sedes"] if x["nombre"].endswith(s)]
    assert [(x["nombre"], x["canchas"]) for x in propias] == [
        (f"ZY Sede {s}", 0),
        (f"zz Sede {s}", 1),
    ]


def test_no_hay_dos_sedes_activas_con_el_mismo_nombre(
    api: TestClient, token_admin: str, unico: Callable[[], str]
) -> None:
    nombre = f"Sede Haedo {unico()}"
    assert api.post("/sedes", headers=_con(token_admin), json=_sede(nombre)).status_code == 201
    r = api.post(
        "/sedes", headers=_con(token_admin), json=_sede(nombre.upper(), direccion="Otra 1")
    )
    assert r.status_code == 409
    assert r.json() == {"errores": {"nombre": "Ya existe una sede con ese nombre"}}


def test_dos_altas_iguales_a_la_vez_guardan_una_sola(
    api: TestClient, motor: Engine, token_admin: str, unico: Callable[[], str]
) -> None:
    nombre = f"Sede Haedo {unico()}"
    with ThreadPoolExecutor(max_workers=2) as pool:
        codigos = sorted(
            pool.map(
                lambda _: (
                    api.post("/sedes", headers=_con(token_admin), json=_sede(nombre)).status_code
                ),
                range(2),
            )
        )
    assert codigos == [201, 409]
    with motor.connect() as conn:
        n = conn.execute(
            text("SELECT count(*) FROM sede WHERE nombre = :n"), {"n": nombre}
        ).scalar_one()
    assert n == 1


def test_los_datos_invalidos_vuelven_con_el_mensaje_de_cada_campo(
    api: TestClient, token_admin: str, unico: Callable[[], str]
) -> None:
    r = api.post(
        "/sedes",
        headers=_con(token_admin),
        json=_sede(f"Sede {unico()}", direccion="Vergara", apertura="22:00", cierre="21:00"),
    )
    assert r.status_code == 422
    assert r.json() == {
        "errores": {
            "direccion": "Escribí la calle y la altura",
            "cierre": "El cierre tiene que ser después de la apertura",
        }
    }
    r = api.post("/sedes", headers=_con(token_admin), json={})
    assert r.status_code == 422
    assert set(r.json()["errores"]) == {"nombre", "direccion", "apertura", "cierre", "dias"}


def test_sin_sesion_no_hay_sedes(api: TestClient) -> None:
    assert api.get("/sedes").status_code == 401
    assert api.post("/sedes", json=_sede("Sede Haedo")).status_code == 401


@pytest.mark.parametrize("hora", ["23:00+00:00", "00:00Z", "08", "0800", "T08:00", "8:00"])
def test_una_hora_que_no_es_hh_mm_es_un_error_del_campo(
    api: TestClient, token_admin: str, unico: Callable[[], str], hora: str
) -> None:
    r = api.post("/sedes", headers=_con(token_admin), json=_sede(f"Sede {unico()}", cierre=hora))
    assert r.status_code == 422
    assert r.json() == {"errores": {"cierre": "El horario de cierre es obligatorio"}}
