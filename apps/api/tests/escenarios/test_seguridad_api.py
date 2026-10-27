"""Seguridad de la API: entradas, límites de frecuencia, registro, cabeceras y configuración."""

import json
import logging
import os
import smtplib
import socket
import ssl
import subprocess
import sys
import time
import tomllib
from collections.abc import Callable, Iterator
from datetime import date, datetime, timedelta
from pathlib import Path
from types import TracebackType
from zoneinfo import ZoneInfo

import httpx2
import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.modules.password_recovery.rules import Message as Mensaje
from app.shared.config import config
from app.shared import email as correo
from app.modules.users.seed_admin import main as sembrar
from app.main import create_app

RAIZ_API = Path(__file__).resolve().parents[2]
RAIZ_REPO = RAIZ_API.parents[1]
CONTRASENA = "ClubNahuel1"
ZONA = ZoneInfo("America/Argentina/Buenos_Aires")


def _con(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _manana() -> date:
    return datetime.now(ZONA).date() + timedelta(days=1)


def _alta_socio(
    api: TestClient,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> tuple[dict[str, str], str]:
    s = unico()
    correo_socio = f"socio.{s}@correo.com"
    alta = api.post(
        "/registro",
        json={
            "nombre": "Martín",
            "apellido": "Ferreyra",
            "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
            "fecha_nacimiento": "1994-07-21",
            "correo": correo_socio,
            "contrasena": CONTRASENA,
        },
    )
    assert alta.status_code == 201
    token = iniciar_sesion(correo_socio, CONTRASENA)
    assert token is not None
    return _con(token), correo_socio


@pytest.fixture
def token_usuario(
    api: TestClient,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> str:
    return _alta_socio(api, iniciar_sesion, unico)[0]["Authorization"].removeprefix("Bearer ")


@pytest.fixture
def token_admin(
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
    monkeypatch: pytest.MonkeyPatch,
) -> str:
    s = unico()
    monkeypatch.setenv("ADMIN_CONTRASENA", CONTRASENA)
    argumentos = [
        "--correo", f"admin.{s}@club.com", "--nombre", "Ana", "--apellido", "Díaz",
        "--dni", str(int(s, 16) % 90_000_000 + 10_000_000), "--nacimiento", "1985-06-01",
    ]  # fmt: skip
    assert sembrar(argumentos) == 0
    token = iniciar_sesion(f"admin.{s}@club.com", CONTRASENA)
    assert token is not None
    return token


@pytest.fixture
def cancha(api: TestClient, motor: Engine, unico: Callable[[], str]) -> str:
    """Un Fútbol 5 en una sede abierta de 08:00 a 23:00 todos los días."""
    s = unico()
    with motor.begin() as conn:
        espacio = conn.execute(
            text(
                "WITH s AS (INSERT INTO sede (nombre, calle, altura, apertura, cierre, dias)"
                " VALUES (:n, 'Av. Vergara', 1850, '08:00', '23:00', ARRAY[1,2,3,4,5,6,7])"
                " RETURNING id)"
                " INSERT INTO espacio (sede_id, deporte, tipo, numero, nombre, techada,"
                " iluminada, precio_por_hora) SELECT id, 'Futbol', 'F5', 1, :e, false, true,"
                " 38000 FROM s RETURNING id"
            ),
            {"n": f"Sede Haedo {s}", "e": f"Haedo{s}_Vergara_1850_Futbol_F5_1"},
        ).scalar_one()
    return str(espacio)


class _SmtpFalso:
    """Un servidor SMTP que anota el contexto TLS que pide el cliente y si llegó a loguearse.

    Con `certificado_invalido`, el TLS falla como falla contra un certificado que no es del servidor.
    """

    contextos: list[ssl.SSLContext | None] = []
    logins: list[str] = []
    rechazar: bool = False
    certificado_invalido: bool = False

    def __init__(self, host: str, puerto: int, timeout: float) -> None:
        self.host = host

    def __enter__(self) -> "_SmtpFalso":
        return self

    def __exit__(
        self, tipo: type[BaseException] | None, e: BaseException | None, tb: TracebackType | None
    ) -> None:
        return None

    def starttls(self, context: ssl.SSLContext | None = None) -> None:
        _SmtpFalso.contextos.append(context)
        if _SmtpFalso.certificado_invalido:
            raise ssl.SSLCertVerificationError("certificate verify failed: atacante.invalid")

    def login(self, usuario: str, contrasena: str) -> None:
        _SmtpFalso.logins.append(usuario)

    def send_message(self, mensaje: object) -> None:
        if _SmtpFalso.rechazar:
            raise smtplib.SMTPRecipientsRefused({"ana.rios@ejemplo.com": (550, b"no existe")})


@pytest.fixture
def smtp_falso(monkeypatch: pytest.MonkeyPatch) -> type[_SmtpFalso]:
    _SmtpFalso.contextos = []
    _SmtpFalso.logins = []
    _SmtpFalso.rechazar = False
    _SmtpFalso.certificado_invalido = False
    monkeypatch.setattr(correo.smtplib, "SMTP", _SmtpFalso)
    monkeypatch.setattr(config, "email_mode", "smtp")
    monkeypatch.setattr(config, "smtp_host", "smtp.ejemplo.com")
    monkeypatch.setattr(config, "smtp_user", "club-smtp")
    monkeypatch.setattr(config, "smtp_password", "SmtpClave9")
    monkeypatch.setattr(config, "email_sender", "club@ejemplo.com")
    return _SmtpFalso


def _mensaje() -> Mensaje:
    return Mensaje(recipient="ana.rios@ejemplo.com", subject="Tu enlace", body="Entrá al enlace")


def test_el_correo_exige_un_certificado_valido_para_el_nombre_del_servidor(
    smtp_falso: type[_SmtpFalso],
) -> None:
    """el envío de correo pide un TLS que verifica certificado y nombre @REV-01-S1"""
    correo.send(_mensaje())

    contexto = smtp_falso.contextos[0]
    assert isinstance(contexto, ssl.SSLContext)
    assert contexto.verify_mode == ssl.CERT_REQUIRED
    assert contexto.check_hostname is True


def test_con_un_certificado_invalido_no_se_mandan_las_credenciales(
    smtp_falso: type[_SmtpFalso], caplog: pytest.LogCaptureFixture
) -> None:
    """con un certificado inválido no se entregan usuario ni contraseña SMTP
    @REV-01-S1 @assumption:REV-01-ASM-06
    """
    smtp_falso.certificado_invalido = True

    with caplog.at_level(logging.DEBUG):
        correo.send(_mensaje())

    assert smtp_falso.logins == []
    assert caplog.records
    assert "ana.rios@ejemplo.com" not in caplog.text


def test_la_recuperacion_responde_igual_aunque_el_correo_no_salga(
    api: TestClient, smtp_falso: type[_SmtpFalso]
) -> None:
    """quien pide recuperar ve lo mismo aunque el TLS del correo falle
    @REV-01-S1 @assumption:REV-01-ASM-06
    """
    smtp_falso.certificado_invalido = True

    r = api.post("/recuperacion", json={"correo": "nadie.tls@correo.com"})

    assert r.status_code == 202


@pytest.mark.parametrize("horas", [10**12, 5, 0, -1, None, "x"])
def test_una_reserva_con_horas_fuera_de_rango_es_un_dato_invalido(
    api: TestClient, token_usuario: str, cancha: str, horas: object
) -> None:
    """una reserva con horas desmesuradas se rechaza como dato inválido @REV-01-S2"""
    r = api.post(
        "/reservas",
        headers=_con(token_usuario),
        json={
            "espacio_id": cancha,
            "fecha": _manana().isoformat(),
            "desde": "10:00",
            "horas": horas,
        },
    )

    assert r.status_code == 422
    assert "horas" in r.json()["errores"]


def test_una_reserva_de_cuatro_horas_se_acepta(
    api: TestClient, token_usuario: str, cancha: str
) -> None:
    """el borde de cuatro horas sigue aceptándose @REV-01-S2"""
    r = api.post(
        "/reservas",
        headers=_con(token_usuario),
        json={"espacio_id": cancha, "fecha": _manana().isoformat(), "desde": "10:00", "horas": 4},
    )

    assert r.status_code == 201


@pytest.mark.parametrize(("desde", "horas"), [("23:00", 4), ("23:00", 1), ("10:00", 1)])
def test_una_reserva_al_final_del_calendario_es_un_dato_invalido(
    api: TestClient, token_usuario: str, cancha: str, desde: str, horas: int
) -> None:
    """una reserva que termina después del último día representable es inválida @REV-01-S3"""
    r = api.post(
        "/reservas",
        headers=_con(token_usuario),
        json={"espacio_id": cancha, "fecha": "9999-12-31", "desde": desde, "horas": horas},
    )

    assert r.status_code == 422
    assert "fecha" in r.json()["errores"]


@pytest.mark.parametrize("pagina", [2**70, 10_001, 0, "x"])
def test_una_pagina_fuera_de_rango_del_historial_global_es_un_dato_invalido(
    api: TestClient, token_admin: str, pagina: object
) -> None:
    """pedir una página enorme del historial global se rechaza como dato inválido @REV-01-S4"""
    r = api.get("/reservas/todas", headers=_con(token_admin), params={"pagina": pagina})

    assert r.status_code == 422
    assert "pagina" in r.json()["errores"]


def test_la_ultima_pagina_permitida_del_historial_global_responde(
    api: TestClient, token_admin: str
) -> None:
    """el borde de la página 10000 sigue respondiendo @REV-01-S4 @assumption:REV-01-ASM-02"""
    r = api.get("/reservas/todas", headers=_con(token_admin), params={"pagina": 10_000})

    assert r.status_code == 200
    assert r.json()["reservas"] == []


NULO = "Ana\x00Rios"
SEDE = {"direccion": "Av. Vergara 1850", "apertura": "08:00", "cierre": "23:00", "dias": [1]}
ESPACIO = {
    "sede_id": "00000000-0000-7000-8000-000000000001",
    "tipo": "F5",
    "techada": False,
    "iluminada": True,
    "precio_por_hora": 1,
}


def test_la_api_no_usa_un_certifi_con_vulnerabilidad_conocida() -> None:
    """la API no depende de una versión de certifi con vulnerabilidad conocida @REV-01-S10"""
    lock = tomllib.loads((RAIZ_API / "uv.lock").read_text(encoding="utf-8"))
    version = next(p["version"] for p in lock["package"] if p["name"] == "certifi")

    assert tuple(int(n) for n in version.split(".")) >= (2026, 10, 18)


def test_un_rechazo_del_servidor_de_correo_no_deja_la_direccion_en_el_log(
    smtp_falso: type[_SmtpFalso], caplog: pytest.LogCaptureFixture
) -> None:
    """un rechazo del servidor de correo no deja la dirección de la persona en el log
    @REV-01-S11
    """
    smtp_falso.rechazar = True

    with caplog.at_level(logging.DEBUG):
        correo.send(_mensaje())

    assert caplog.records
    assert "ana.rios@ejemplo.com" not in caplog.text
    assert "SmtpClave9" not in caplog.text


def _puerto_libre() -> int:
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return int(s.getsockname()[1])


@pytest.fixture
def servidor(api: TestClient, tmp_path: Path) -> Iterator[tuple[str, Path]]:
    """La API servida por uvicorn como en Render, con su salida en un archivo."""
    puerto = _puerto_libre()
    salida = tmp_path / "uvicorn.log"
    with salida.open("w", encoding="utf-8") as archivo:
        proceso = subprocess.Popen(
            [sys.executable, "-m", "uvicorn", "app.main:app", "--host", "127.0.0.1"]
            + ["--port", str(puerto)],
            cwd=RAIZ_API,
            stdout=archivo,
            stderr=subprocess.STDOUT,
            env={**os.environ, "PYTHONUTF8": "1"},
        )
        base = f"http://127.0.0.1:{puerto}"
        limite = time.monotonic() + 60
        while time.monotonic() < limite and proceso.poll() is None:
            try:
                httpx2.get(f"{base}/yo", timeout=2)
                break
            except httpx2.HTTPError:
                time.sleep(0.5)
        yield base, salida
        proceso.terminate()
        proceso.wait(timeout=30)


@pytest.mark.parametrize("salto", ["%0a", "%0d"])
def test_una_ruta_con_saltos_de_linea_no_falsifica_el_log(
    api: TestClient, caplog: pytest.LogCaptureFixture, salto: str
) -> None:
    """una ruta con saltos de línea no puede falsificar una línea del log @REV-01-S13"""
    falsa = (
        f"/reservas/1{salto}2026-10-20 00:00:00,000 ERROR clubnahuelmosse.errores FALSO/cancelar"
    )

    with caplog.at_level(logging.INFO):
        api.post(falsa)

    mensajes = [r.getMessage() for r in caplog.records]
    assert any("/reservas/1" in m for m in mensajes)
    assert not any("\n" in m or "\r" in m for m in mensajes)


def test_los_secretos_no_llegan_al_log_ni_a_las_respuestas(
    api: TestClient, token_usuario: str, caplog: pytest.LogCaptureFixture
) -> None:
    """contraseñas, tokens y códigos de recuperación no llegan al log @REV-01-S14"""
    with caplog.at_level(logging.DEBUG):
        respuestas = [
            api.put("/recuperacion", json={"codigo": "cod-secreto-7Q", "nueva": ["Clave9Secreta"]}),
            api.post("/recuperacion/consulta", json={"codigo": "cod-secreto-7Q"}),
            api.get("/yo", headers={"Authorization": "Bearer token-secreto-9Z"}),
            api.post(
                "/registro", json={"correo": "ana@correo.com", "contrasena": ["Clave9Secreta"]}
            ),
            api.put(
                "/yo/contrasena",
                headers=_con(token_usuario),
                json={"actual": ["Clave9Secreta"], "nueva": ["Clave9Secreta"]},
            ),
        ]

    textos = caplog.text + "".join(r.text for r in respuestas)
    assert "Clave9Secreta" not in textos
    assert "cod-secreto-7Q" not in textos
    assert "token-secreto-9Z" not in textos


def test_el_contrato_versionado_coincide_con_la_api() -> None:
    """el contrato OpenAPI versionado coincide con lo que la API publica @REV-01-S15"""
    versionado = json.loads((RAIZ_API / "openapi.json").read_text(encoding="utf-8"))

    assert versionado == create_app().openapi()


def test_la_api_arranca_con_el_emulador_y_un_proyecto_de_demo(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """con el emulador, un proyecto de demo y sin credenciales la API arranca
    @REV-01-S18 @assumption:REV-01-ASM-10
    """
    monkeypatch.setenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
    monkeypatch.delenv("GOOGLE_APPLICATION_CREDENTIALS", raising=False)
    monkeypatch.setattr(config, "firebase_project_id", "demo-clubnahuelmosse")
    monkeypatch.setattr(config, "firebase_credentials_json", "")

    assert isinstance(create_app(), FastAPI)


def _duenio(motor: Engine, token: str) -> str:
    with motor.connect() as conn:
        return str(
            conn.execute(
                text(
                    "SELECT u.correo FROM dispositivo d JOIN usuario u ON u.id = d.usuario_id"
                    " WHERE d.token = :t AND d.activo"
                ),
                {"t": token},
            ).scalar_one()
        )


def test_el_token_de_otra_persona_no_cambia_de_duenio(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """registrar el token de dispositivo de otra persona no se lo quita
    @REV-01-S19 @assumption:REV-01-ASM-04
    """
    duenia, correo_duenia = _alta_socio(api, iniciar_sesion, unico)
    intruso, _ = _alta_socio(api, iniciar_sesion, unico)
    token = f"fcm-{unico()}"
    pedido = {"token": token, "plataforma": "android", "permiso": True}

    assert api.put("/dispositivos", headers=duenia, json=pedido).status_code == 204
    intento = api.put("/dispositivos", headers=intruso, json=pedido)
    baja = api.post("/dispositivos/baja", headers=intruso, json={"token": token})

    assert intento.status_code == 204
    assert baja.status_code == 204
    assert _duenio(motor, token) == correo_duenia


def test_un_token_dado_de_baja_pasa_a_quien_lo_registra(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """un teléfono que cerró sesión pasa a la siguiente persona
    @REV-01-S19 @assumption:REV-01-ASM-04
    """
    primera, _ = _alta_socio(api, iniciar_sesion, unico)
    segunda, correo_segunda = _alta_socio(api, iniciar_sesion, unico)
    token = f"fcm-{unico()}"
    pedido = {"token": token, "plataforma": "android", "permiso": True}

    assert api.put("/dispositivos", headers=primera, json=pedido).status_code == 204
    assert api.post("/dispositivos/baja", headers=primera, json={"token": token}).status_code == 204
    assert api.put("/dispositivos", headers=segunda, json=pedido).status_code == 204

    assert _duenio(motor, token) == correo_segunda
