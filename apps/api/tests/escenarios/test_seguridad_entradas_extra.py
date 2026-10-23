"""Seguridad de la API: entradas, proxy, registro de rechazos, correo y contrato (T1 a T4)."""

import logging
import ssl
from collections.abc import Callable
from pathlib import Path
from types import TracebackType

import pytest
import yaml
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.aplicacion.recuperacion import Mensaje
from app.config import config
from app.infraestructura import correo

RAIZ_REPO = Path(__file__).resolve().parents[4]
CONTRASENA = "ClubNahuel1"


def _socio(
    api: TestClient,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> dict[str, str]:
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
    return {"Authorization": f"Bearer {token}"}


def _registro(**cambios: str) -> dict[str, str]:
    base = {
        "nombre": "Martín",
        "apellido": "Ferreyra",
        "dni": "31000001",
        "fecha_nacimiento": "1994-07-21",
        "correo": "nadie@correo.com",
        "contrasena": CONTRASENA,
    }
    return {**base, **cambios}


def test_un_nulo_en_el_correo_de_registro_es_un_dato_invalido(api: TestClient) -> None:
    """un carácter nulo en el correo de /registro es un dato inválido @REV-01-S5"""
    r = api.post("/registro", json=_registro(correo="ana\u0000@correo.com"))

    assert r.status_code == 422
    assert "correo" in r.json()["errores"]


def test_un_nulo_en_el_correo_de_recuperacion_es_un_dato_invalido(api: TestClient) -> None:
    """un carácter nulo en el correo de /recuperacion es un dato inválido @REV-01-S5"""
    r = api.post("/recuperacion", json={"correo": "ana\u0000@correo.com"})

    assert r.status_code == 422
    assert "correo" in r.json()["errores"]


def test_un_nulo_en_el_token_de_dispositivo_es_un_dato_invalido(
    api: TestClient,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """un carácter nulo en el token de /dispositivos es un dato inválido @REV-01-S5"""
    sesion = _socio(api, iniciar_sesion, unico)

    r = api.put(
        "/dispositivos",
        headers=sesion,
        json={"token": "fcm\u0000x", "plataforma": "android", "permiso": True},
    )

    assert r.status_code == 422
    assert "token" in r.json()["errores"]


def test_un_texto_demasiado_largo_se_rechaza_sin_repetir_el_valor(api: TestClient) -> None:
    """un texto más largo que su máximo es un dato inválido y el error no repite el valor
    @REV-01-S5 @assumption:REV-01-ASM-02
    """
    largo = "a" * 300 + "@correo.com"

    r = api.post("/registro", json=_registro(correo=largo))

    assert r.status_code == 422
    assert "correo" in r.json()["errores"]
    assert largo not in r.text
    assert "a" * 50 not in r.text


def test_un_caracter_de_control_distinto_del_nulo_se_rechaza(api: TestClient) -> None:
    """un carácter de control distinto del nulo es un dato inválido
    @REV-01-S5 @assumption:REV-01-ASM-02
    """
    r = api.post("/recuperacion", json={"correo": "ana\u0007@correo.com"})

    assert r.status_code == 422
    assert r.json()["errores"]["correo"] == "Tiene caracteres no permitidos"


def test_detras_del_proxy_un_origen_falsificado_delante_no_saltea_el_limite(
    api: TestClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    """detrás del proxy un X-Forwarded-For falsificado delante no saltea el límite
    @REV-01-S6 @assumption:REV-01-ASM-15
    """
    monkeypatch.setattr(config, "detras_de_proxy", True)

    codigos = [
        api.post(
            "/recuperacion",
            json={"correo": "nadie.proxy@correo.com"},
            headers={"X-Forwarded-For": f"203.0.113.{n}, 198.51.100.7"},
        ).status_code
        for n in range(12)
    ]
    otro = api.post(
        "/recuperacion",
        json={"correo": "nadie.proxy@correo.com"},
        headers={"X-Forwarded-For": "198.51.100.8"},
    )

    assert codigos[0] == 202
    assert codigos[-1] == 429
    assert otro.status_code == 202


def test_el_blueprint_de_render_define_que_esta_detras_de_un_proxy() -> None:
    """el blueprint de Render define DETRAS_DE_PROXY=true @REV-01-S6 @assumption:REV-01-ASM-15"""
    blueprint = yaml.safe_load((RAIZ_REPO / "render.yaml").read_text(encoding="utf-8"))
    variables = {v["key"]: v.get("value") for v in blueprint["services"][0]["envVars"]}

    assert variables["DETRAS_DE_PROXY"] == "true"


def test_un_429_y_un_host_ajeno_quedan_registrados_sin_datos_personales(
    api: TestClient, caplog: pytest.LogCaptureFixture
) -> None:
    """un 429 o un Host ajeno queda registrado con método, ruta escapada, código y usuario, sin IP
    ni datos personales @REV-01-S17 @assumption:REV-01-ASM-09
    """
    with caplog.at_level(logging.INFO):
        api.get("/yo", headers={"Host": "attacker.example"})
        for _ in range(12):
            api.post("/recuperacion", json={"correo": "privado.log@correo.com"})

    mensajes = [r.getMessage() for r in caplog.records if r.name == "clubnahuelmosse.errores"]
    assert "GET /yo 400 usuario=anónimo" in mensajes
    assert "POST /recuperacion 429 usuario=anónimo" in mensajes
    assert "privado.log" not in caplog.text
    assert "testclient" not in caplog.text
    assert "127.0.0.1" not in caplog.text


def test_la_baja_de_un_token_ajeno_no_hace_nada_y_responde_204(
    api: TestClient,
    motor: Engine,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """dar de baja un token ajeno no hace nada y responde 204
    @REV-01-S19 @assumption:REV-01-ASM-04
    """
    duenia = _socio(api, iniciar_sesion, unico)
    intruso = _socio(api, iniciar_sesion, unico)
    token = f"fcm-{unico()}"
    pedido = {"token": token, "plataforma": "android", "permiso": True}
    assert api.put("/dispositivos", headers=duenia, json=pedido).status_code == 204

    baja = api.post("/dispositivos/baja", headers=intruso, json={"token": token})

    with motor.connect() as conn:
        activo = conn.execute(
            text("SELECT activo FROM dispositivo WHERE token = :t"), {"t": token}
        ).scalar_one()
    assert baja.status_code == 204
    assert activo is True


class _SmtpSinConfianza:
    def __init__(self, host: str, puerto: int, timeout: float) -> None:
        pass

    def __enter__(self) -> "_SmtpSinConfianza":
        return self

    def __exit__(
        self, tipo: type[BaseException] | None, e: BaseException | None, tb: TracebackType | None
    ) -> None:
        return None

    def starttls(self, context: ssl.SSLContext | None = None) -> None:
        raise ssl.SSLCertVerificationError("certificate verify failed: ana.rios@ejemplo.com")


def test_un_fallo_de_tls_del_correo_no_deja_la_direccion_en_el_log(
    monkeypatch: pytest.MonkeyPatch, caplog: pytest.LogCaptureFixture
) -> None:
    """un fallo de TLS del correo no deja la dirección en el log
    @REV-01-S11 @assumption:REV-01-ASM-06
    """
    monkeypatch.setattr(correo.smtplib, "SMTP", _SmtpSinConfianza)
    monkeypatch.setattr(config, "correo_modo", "smtp")
    monkeypatch.setattr(config, "smtp_host", "smtp.ejemplo.com")
    monkeypatch.setattr(config, "correo_remitente", "club@ejemplo.com")

    with caplog.at_level(logging.DEBUG):
        correo.enviar(Mensaje(para="ana.rios@ejemplo.com", asunto="Tu enlace", cuerpo="Hola"))

    assert caplog.records
    assert "ana.rios@ejemplo.com" not in caplog.text


def test_el_contrato_documenta_el_429_el_400_por_host_y_el_422(api: TestClient) -> None:
    """el contrato OpenAPI documenta el 429, el 400 por Host ajeno y el 422 de forma
    @REV-01-S15
    """
    rutas = api.get("/openapi.json").json()["paths"]

    for ruta in ("/registro", "/recuperacion"):
        assert {"422", "429"} <= set(rutas[ruta]["post"]["responses"])
    assert "429" in rutas["/yo"]["put"]["responses"]
    for ruta, operaciones in rutas.items():
        if ruta == "/health":
            continue
        for operacion in operaciones.values():
            assert "400" in operacion["responses"], ruta
