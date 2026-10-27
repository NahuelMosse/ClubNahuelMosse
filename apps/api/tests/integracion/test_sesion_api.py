"""`GET /yo` y la siembra del administrador contra la base y el emulador reales."""

from collections.abc import Callable

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.users.seed_admin import main as sembrar

CONTRASENA = "ClubNahuel1"


def _registrar(api: TestClient, s: str) -> str:
    correo = f"socia.{s}@correo.com"
    pedido = {
        "nombre": "Lucía",
        "apellido": "Gómez",
        "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        "fecha_nacimiento": "1998-11-02",
        "correo": correo,
        "contrasena": CONTRASENA,
    }
    assert api.post("/registro", json=pedido).status_code == 201
    return correo


def _yo(api: TestClient, token: str | None) -> tuple[int, dict[str, object]]:
    cabeceras = {"Authorization": f"Bearer {token}"} if token else {}
    r = api.get("/yo", headers=cabeceras)
    return r.status_code, r.json()


def test_con_el_token_de_la_cuenta_devuelve_su_perfil_y_su_rol(
    api: TestClient, iniciar_sesion: Callable[[str, str], str | None], unico: Callable[[], str]
) -> None:
    correo = _registrar(api, unico())
    codigo, cuerpo = _yo(api, iniciar_sesion(correo, CONTRASENA))
    assert codigo == 200
    assert cuerpo == {
        "nombre": "Lucía",
        "apellido": "Gómez",
        "correo": correo,
        "rol": "usuario",
        "dni": cuerpo["dni"],
        "fecha_nacimiento": "1998-11-02",
    }
    assert isinstance(cuerpo["dni"], str) and len(cuerpo["dni"]) == 8


@pytest.mark.parametrize("cabecera", [None, "Bearer ", "Bearer basura", "Basic dXNlcjpwYXNz"])
def test_sin_un_token_valido_no_hay_sesion(api: TestClient, cabecera: str | None) -> None:
    r = api.get("/yo", headers={"Authorization": cabecera} if cabecera is not None else {})
    assert r.status_code == 401
    assert r.headers["www-authenticate"] == "Bearer"
    assert r.json() == {"detail": "Sesión inválida o vencida"}


def test_una_cuenta_dada_de_baja_no_tiene_sesion_aunque_el_token_sea_valido(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """Verifica CU-01-SUP-05."""
    correo = _registrar(api, unico())
    token = iniciar_sesion(correo, CONTRASENA)
    with motor.begin() as conn:
        conn.execute(
            text("UPDATE usuario SET activo = false, dado_de_baja_en = now() WHERE correo = :c"),
            {"c": correo},
        )
    assert _yo(api, token)[0] == 401


def test_una_cuenta_deshabilitada_en_firebase_no_tiene_sesion(
    api: TestClient, iniciar_sesion: Callable[[str, str], str | None], unico: Callable[[], str]
) -> None:
    from firebase_admin import auth

    from app.shared.identity import FirebaseProvider, _firebase_app

    correo = _registrar(api, unico())
    token = iniciar_sesion(correo, CONTRASENA)
    uid = FirebaseProvider().uid_of(correo)
    assert uid is not None
    auth.update_user(uid, disabled=True, app=_firebase_app())
    assert _yo(api, token)[0] == 401


def test_la_siembra_crea_un_admin_que_inicia_sesion_con_rol_admin(
    api: TestClient,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    s = unico()
    correo = f"admin.{s}@club.com"
    monkeypatch.setenv("ADMIN_CONTRASENA", CONTRASENA)
    argumentos = [
        "--correo", correo, "--nombre", "Ana", "--apellido", "Díaz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--nacimiento", "1985-06-01",
    ]  # fmt: skip
    assert sembrar(argumentos) == 0
    # Sembrar otra vez no duplica: la cuenta ya existe y sólo se asciende si se pide.
    assert sembrar(argumentos) == 1
    assert sembrar([*argumentos, "--promover"]) == 0
    codigo, cuerpo = _yo(api, iniciar_sesion(correo, CONTRASENA))
    assert (codigo, cuerpo["rol"]) == (200, "admin")


def test_la_siembra_no_asciende_una_cuenta_ajena_sin_pedirlo(
    api: TestClient,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    correo = _registrar(api, unico())
    monkeypatch.setenv("ADMIN_CONTRASENA", "OtraClave9")
    argumentos = [
        "--correo", correo, "--nombre", "Ana", "--apellido", "Díaz",
        "--dni", "30111224", "--nacimiento", "1985-06-01",
    ]  # fmt: skip
    assert sembrar(argumentos) == 1
    assert _yo(api, iniciar_sesion(correo, CONTRASENA))[1]["rol"] == "usuario"


def test_la_siembra_promueve_una_cuenta_que_ya_existe(
    api: TestClient,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    correo = _registrar(api, unico())
    monkeypatch.setenv("ADMIN_CONTRASENA", "OtraClave9")
    argumentos = [
        "--correo", correo.upper(), "--nombre", "Lucía", "--apellido", "Gómez",
        "--dni", "30111222", "--nacimiento", "1998-11-02", "--promover",
    ]  # fmt: skip
    assert sembrar(argumentos) == 0
    # La cuenta conserva su contraseña: la siembra sólo le cambia el rol.
    assert _yo(api, iniciar_sesion(correo, CONTRASENA))[1]["rol"] == "admin"


def test_la_siembra_sin_contrasena_no_toca_nada(
    motor: Engine, unico: Callable[[], str], monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.delenv("ADMIN_CONTRASENA", raising=False)
    correo = f"admin.{unico()}@club.com"
    argumentos = [
        "--correo", correo, "--nombre", "Ana", "--apellido", "Díaz",
        "--dni", "30111223", "--nacimiento", "1985-06-01",
    ]  # fmt: skip
    assert sembrar(argumentos) == 2
    with motor.connect() as conn:
        fila = conn.execute(text("SELECT 1 FROM usuario WHERE correo = :c"), {"c": correo})
        assert fila.first() is None
