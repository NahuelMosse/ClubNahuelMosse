"""El endpoint de registro contra la base y el emulador reales."""

from collections.abc import Callable
from concurrent.futures import ThreadPoolExecutor

from fastapi.testclient import TestClient


def _pedido(s: str, **cambios: str) -> dict[str, str]:
    base = {
        "first_name": "Ana",
        "last_name": "Pérez",
        "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        "birth_date": "2000-03-14",
        "email": f"ana.{s}@correo.com",
        "password": "ClubNahuel1",
    }
    base.update(cambios)
    return base


def test_datos_invalidos_devuelven_los_errores_por_campo(
    api: TestClient, unico: Callable[[], str]
) -> None:
    r = api.post("/register", json=_pedido(unico(), dni="123", password="corta"))
    assert r.status_code == 422
    assert r.json() == {
        "errors": {"dni": "El DNI tiene 7 u 8 números", "password": "Al menos 8 caracteres"}
    }


def test_correo_repetido_sin_distinguir_mayusculas(
    api: TestClient, unico: Callable[[], str]
) -> None:
    s = unico()
    assert api.post("/register", json=_pedido(s)).status_code == 201
    r = api.post("/register", json=_pedido(unico(), email=f"  ANA.{s}@Correo.com "))
    assert r.status_code == 409
    assert r.json() == {
        "message": "El usuario ya está registrado. Modificá el correo o el DNI.",
        "fields": ["email"],
        "errors": {"email": "Este correo ya está registrado"},
    }


def test_dni_repetido_aunque_se_escriba_con_puntos(
    api: TestClient, unico: Callable[[], str]
) -> None:
    s = unico()
    dni = str(int(s, 16) % 90_000_000 + 10_000_000)
    assert api.post("/register", json=_pedido(s, dni=dni)).status_code == 201
    con_puntos = f"{dni[:2]}.{dni[2:5]}.{dni[5:]}"
    r = api.post("/register", json=_pedido(unico(), dni=con_puntos))
    assert r.status_code == 409
    assert r.json()["fields"] == ["dni"]


def test_correo_y_dni_repetidos_a_la_vez(api: TestClient, unico: Callable[[], str]) -> None:
    s = unico()
    assert api.post("/register", json=_pedido(s)).status_code == 201
    r = api.post("/register", json=_pedido(s))
    assert r.status_code == 409
    assert r.json()["fields"] == ["email", "dni"]


def test_dos_registros_simultaneos_el_segundo_es_409(
    api: TestClient, unico: Callable[[], str]
) -> None:
    s = unico()
    pedidos = [_pedido(s), _pedido(unico(), dni=_pedido(s)["dni"])]
    with ThreadPoolExecutor(max_workers=2) as pool:
        codigos = sorted(
            r.status_code for r in pool.map(lambda p: api.post("/register", json=p), pedidos)
        )
    assert codigos == [201, 409]


def test_la_documentacion_openapi_describe_el_registro(api: TestClient) -> None:
    esquema = api.get("/openapi.json").json()
    assert "/register" in esquema["paths"]
    assert {"201", "409", "422"} <= set(esquema["paths"]["/register"]["post"]["responses"])


def test_una_cuenta_de_firebase_sin_perfil_no_bloquea_el_registro(
    api: TestClient,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    from firebase_admin import auth

    from app.shared.identity import _firebase_app

    s = unico()
    correo = f"huerfana.{s}@correo.com"
    auth.create_user(email=correo, password="OtraClave9", app=_firebase_app())

    r = api.post("/register", json=_pedido(s, email=correo))
    assert r.status_code == 201, r.text
    assert iniciar_sesion(correo, "ClubNahuel1") is not None
    assert iniciar_sesion(correo, "OtraClave9") is None
