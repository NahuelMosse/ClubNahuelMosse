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
import yaml
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.aplicacion.recuperacion import Mensaje
from app.config import config
from app.infraestructura import correo
from app.interfaz.sembrar_admin import main as sembrar
from app.main import crear_app

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
def cancha(api: TestClient, motor: Engine, unico: Callable[[], str]) -> int:
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
    return int(espacio)


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
    monkeypatch.setattr(config, "correo_modo", "smtp")
    monkeypatch.setattr(config, "smtp_host", "smtp.ejemplo.com")
    monkeypatch.setattr(config, "smtp_usuario", "club-smtp")
    monkeypatch.setattr(config, "smtp_contrasena", "SmtpClave9")
    monkeypatch.setattr(config, "correo_remitente", "club@ejemplo.com")
    return _SmtpFalso


def _mensaje() -> Mensaje:
    return Mensaje(para="ana.rios@ejemplo.com", asunto="Tu enlace", cuerpo="Entrá al enlace")


def test_el_correo_exige_un_certificado_valido_para_el_nombre_del_servidor(
    smtp_falso: type[_SmtpFalso],
) -> None:
    """el envío de correo pide un TLS que verifica certificado y nombre @REV-01-S1"""
    correo.enviar(_mensaje())

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
        correo.enviar(_mensaje())

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
    api: TestClient, token_usuario: str, cancha: int, horas: object
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
    api: TestClient, token_usuario: str, cancha: int
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
    api: TestClient, token_usuario: str, cancha: int, desde: str, horas: int
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
ESPACIO = {"sede_id": 1, "tipo": "F5", "techada": False, "iluminada": True, "precio_por_hora": 1}


@pytest.mark.parametrize(
    ("metodo", "ruta", "cuerpo", "campo"),
    [
        (
            "POST",
            "/registro",
            {
                "nombre": NULO,
                "apellido": "Rios",
                "dni": "30111222",
                "fecha_nacimiento": "1990-01-01",
                "correo": "ana.nulo@correo.com",
                "contrasena": CONTRASENA,
            },
            "nombre",
        ),
        ("POST", "/recuperacion", {"correo": "ana\x00@correo.com"}, "correo"),
        ("POST", "/recuperacion", {"correo": "ana\x07@correo.com"}, "correo"),
        ("POST", "/recuperacion", {"correo": "a" * 250 + "@c.com"}, "correo"),
        ("POST", "/recuperacion/consulta", {"codigo": NULO}, "codigo"),
        ("PUT", "/recuperacion", {"codigo": "cod-1", "nueva": "Clave\x00Nueva1"}, "nueva"),
    ],
)
def test_un_caracter_nulo_sin_sesion_es_un_dato_invalido(
    api: TestClient, metodo: str, ruta: str, cuerpo: dict[str, object], campo: str
) -> None:
    """un carácter nulo en un campo de texto se rechaza como dato inválido @REV-01-S5"""
    r = api.request(metodo, ruta, json=cuerpo)

    assert r.status_code == 422
    assert campo in r.json()["errores"]
    assert "\\u0000" not in r.text


@pytest.mark.parametrize(
    ("metodo", "ruta", "cuerpo", "campo"),
    [
        (
            "PUT",
            "/yo",
            {
                "nombre": NULO,
                "apellido": "Rios",
                "dni": "30111223",
                "fecha_nacimiento": "1990-01-01",
            },
            "nombre",
        ),
        ("PUT", "/yo/contrasena", {"actual": NULO, "nueva": "ClubNahuel2"}, "actual"),
        (
            "PUT",
            "/dispositivos",
            {"token": "fcm\x00token", "plataforma": "android", "permiso": True},
            "token",
        ),
        ("POST", "/dispositivos/baja", {"token": "fcm\x00token"}, "token"),
        (
            "POST",
            "/reservas/999999999/modificar",
            {"espacio_id": 1, "fecha": "2026-12-01", "desde": "10\x00:00"},
            "desde",
        ),
    ],
)
def test_un_caracter_nulo_de_un_socio_es_un_dato_invalido(
    api: TestClient,
    token_usuario: str,
    metodo: str,
    ruta: str,
    cuerpo: dict[str, object],
    campo: str,
) -> None:
    """un carácter nulo en un campo de texto de un socio es un dato inválido @REV-01-S5"""
    r = api.request(metodo, ruta, headers=_con(token_usuario), json=cuerpo)

    assert r.status_code == 422
    assert campo in r.json()["errores"]
    assert "\\u0000" not in r.text


@pytest.mark.parametrize(
    ("metodo", "ruta", "cuerpo", "campo"),
    [
        ("POST", "/sedes", {"nombre": NULO, **SEDE}, "nombre"),
        ("PUT", "/sedes/999999999", {"nombre": NULO, **SEDE}, "nombre"),
        ("POST", "/espacios", {"deporte": "Fut\x00bol", **ESPACIO}, "deporte"),
        ("PUT", "/espacios/999999999", {"deporte": "Fut\x00bol", **ESPACIO}, "deporte"),
        ("POST", "/reservas/999999999/anular", {"motivo": "Lluvia\x00fuerte"}, "motivo"),
    ],
)
def test_un_caracter_nulo_del_administrador_es_un_dato_invalido(
    api: TestClient,
    token_admin: str,
    metodo: str,
    ruta: str,
    cuerpo: dict[str, object],
    campo: str,
) -> None:
    """un carácter nulo en un campo de texto del admin es un dato inválido @REV-01-S5"""
    r = api.request(metodo, ruta, headers=_con(token_admin), json=cuerpo)

    assert r.status_code == 422
    assert campo in r.json()["errores"]
    assert "\\u0000" not in r.text


def test_un_caracter_nulo_en_la_busqueda_del_historial_es_un_dato_invalido(
    api: TestClient, token_admin: str
) -> None:
    """un carácter nulo en la búsqueda del historial global es un dato inválido @REV-01-S5"""
    r = api.get("/reservas/todas", headers=_con(token_admin), params={"q": NULO})

    assert r.status_code == 422
    assert "q" in r.json()["errores"]


def test_las_recuperaciones_en_rafaga_quedan_frenadas(api: TestClient) -> None:
    """pedir recuperaciones de contraseña en ráfaga queda frenado por un límite
    @REV-01-S6 @assumption:REV-01-ASM-03
    """
    respuestas = [
        api.post("/recuperacion", json={"correo": "nadie.rafaga@correo.com"}) for _ in range(11)
    ]

    assert [r.status_code for r in respuestas[:10]] == [202] * 10
    assert respuestas[10].status_code == 429
    assert respuestas[10].headers["retry-after"] == "60"
    assert respuestas[10].json() == {
        "mensaje": "Hiciste demasiados intentos. Esperá un minuto y volvé a probar."
    }


def test_un_origen_inventado_no_saltea_el_limite(api: TestClient) -> None:
    """cambiar X-Forwarded-For sin proxy no saltea el límite
    @REV-01-S6 @assumption:REV-01-ASM-11
    """
    codigos = [
        api.post(
            "/recuperacion",
            json={"correo": "nadie.rafaga@correo.com"},
            headers={"X-Forwarded-For": f"203.0.113.{n}"},
        ).status_code
        for n in range(11)
    ]

    assert codigos[10] == 429


def test_los_registros_en_rafaga_quedan_frenados(api: TestClient) -> None:
    """intentar registros en ráfaga queda frenado por un límite de frecuencia @REV-01-S7"""
    codigos = [api.post("/registro", json={"correo": "x"}).status_code for _ in range(11)]

    assert codigos[:10] == [422] * 10
    assert codigos[10] == 429


def test_probar_dni_ajenos_en_el_perfil_queda_frenado(api: TestClient, token_usuario: str) -> None:
    """probar DNI ajenos en el perfil en serie queda frenado
    @REV-01-S8 @assumption:REV-01-ASM-01
    """
    codigos = [
        api.put(
            "/yo",
            headers=_con(token_usuario),
            json={
                "nombre": "Martín",
                "apellido": "Ferreyra",
                "dni": str(31_000_001 + n),
                "fecha_nacimiento": "1994-07-21",
            },
        ).status_code
        for n in range(11)
    ]

    assert 429 not in codigos[:10]
    assert codigos[10] == 429


def test_probar_correos_ajenos_en_el_registro_queda_frenado(
    api: TestClient,
    iniciar_sesion: Callable[[str, str], str | None],
    unico: Callable[[], str],
) -> None:
    """probar correos ajenos en el registro no sirve para saber quién tiene cuenta
    @REV-01-S9 @assumption:REV-01-ASM-01
    """
    _, ajeno = _alta_socio(api, iniciar_sesion, unico)
    codigos = [
        api.post(
            "/registro",
            json={
                "nombre": "Ana",
                "apellido": "Rios",
                "dni": str(32_000_001 + n),
                "fecha_nacimiento": "1990-01-01",
                "correo": ajeno,
                "contrasena": CONTRASENA,
            },
        ).status_code
        for n in range(20)
    ]

    assert codigos[0] == 409
    assert codigos[-1] == 429


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
        correo.enviar(_mensaje())

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


def test_el_log_de_accesos_no_guarda_lo_que_busca_el_administrador(
    servidor: tuple[str, Path],
) -> None:
    """el log de accesos no guarda el correo ni el DNI que busca el administrador
    @REV-01-S12
    """
    base, salida = servidor

    httpx2.get(f"{base}/reservas/todas", params={"q": "ana.rios@ejemplo.com"}, timeout=10)
    httpx2.get(f"{base}/reservas/todas", params={"q": "39222333"}, timeout=10)
    time.sleep(1)

    log = salida.read_text(encoding="utf-8")
    assert "/reservas/todas" in log
    assert "ejemplo.com" not in log
    assert "39222333" not in log


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


def test_la_documentacion_interactiva_se_apaga_por_configuracion(
    monkeypatch: pytest.MonkeyPatch, motor: Engine
) -> None:
    """la documentación interactiva no se publica en producción
    @REV-01-S15 @assumption:REV-01-ASM-05
    """
    monkeypatch.setattr(config, "documentacion_interactiva", False)

    with TestClient(crear_app()) as cliente:
        docs = cliente.get("/docs")
        redoc = cliente.get("/redoc")
        contrato = cliente.get("/openapi.json")
        salud = cliente.get("/health")

    assert docs.status_code == 404
    assert redoc.status_code == 404
    assert contrato.status_code == 200
    assert salud.status_code == 200


def test_el_despliegue_en_render_apaga_la_documentacion_interactiva() -> None:
    """el blueprint de producción apaga la documentación interactiva y se chequea por /health
    @REV-01-S15 @assumption:REV-01-ASM-05 @assumption:REV-01-ASM-07
    """
    blueprint = yaml.safe_load((RAIZ_REPO / "render.yaml").read_text(encoding="utf-8"))
    web = blueprint["services"][0]
    variables = {v["key"]: v.get("value") for v in web["envVars"]}

    assert variables["DOCUMENTACION_INTERACTIVA"] == "false"
    assert web["healthCheckPath"] == "/health"


def test_el_contrato_versionado_coincide_con_la_api() -> None:
    """el contrato OpenAPI versionado coincide con lo que la API publica @REV-01-S15"""
    versionado = json.loads((RAIZ_API / "openapi.json").read_text(encoding="utf-8"))

    assert versionado == crear_app().openapi()


def test_las_respuestas_impiden_que_las_incrusten(api: TestClient) -> None:
    """las respuestas llevan una política de contenido que impide incrustarlas @REV-01-S16"""
    datos = api.get("/yo")
    pagina = api.get("/enlace/recuperar")

    assert "frame-ancestors 'none'" in datos.headers["content-security-policy"]
    assert "default-src 'none'" in datos.headers["content-security-policy"]
    assert "frame-ancestors 'none'" in pagina.headers["content-security-policy"]


def test_un_host_ajeno_se_rechaza(api: TestClient) -> None:
    """un pedido con un Host ajeno se rechaza @REV-01-S17 @assumption:REV-01-ASM-12"""
    ajeno = api.get("/yo", headers={"Host": "attacker.example"})
    propio = api.get("/yo")

    assert ajeno.status_code == 400
    assert propio.status_code == 401


def test_una_escritura_con_un_host_ajeno_se_rechaza(
    api: TestClient, token_usuario: str, cancha: int
) -> None:
    """una reserva con sesión y Host ajeno se rechaza @REV-01-S17"""
    r = api.post(
        "/reservas",
        headers={**_con(token_usuario), "Host": "attacker.example"},
        json={"espacio_id": cancha, "fecha": _manana().isoformat(), "desde": "10:00", "horas": 1},
    )

    assert r.status_code == 400


def test_la_api_no_arranca_con_el_emulador_y_credenciales_reales(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """la API se niega a arrancar con el emulador junto a credenciales reales @REV-01-S18"""
    monkeypatch.setenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
    monkeypatch.setattr(config, "firebase_credenciales_json", '{"type": "service_account"}')

    with pytest.raises(RuntimeError, match="emulador"):
        crear_app()


def test_la_api_no_arranca_con_el_emulador_y_un_archivo_de_credenciales(
    monkeypatch: pytest.MonkeyPatch, tmp_path: Path
) -> None:
    """la API se niega a arrancar con el emulador y un archivo de credenciales @REV-01-S18"""
    monkeypatch.setenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
    monkeypatch.setenv("GOOGLE_APPLICATION_CREDENTIALS", str(tmp_path / "cuenta.json"))

    with pytest.raises(RuntimeError, match="emulador"):
        crear_app()


def test_la_api_no_arranca_con_el_emulador_y_un_proyecto_real(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """la API se niega a arrancar con el emulador y un proyecto que no es de demo @REV-01-S18"""
    monkeypatch.setenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
    monkeypatch.setattr(config, "firebase_project_id", "clubnahuelmosse-prod")

    with pytest.raises(RuntimeError, match="emulador"):
        crear_app()


def test_la_api_arranca_con_el_emulador_y_un_proyecto_de_demo(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """con el emulador, un proyecto de demo y sin credenciales la API arranca
    @REV-01-S18 @assumption:REV-01-ASM-10
    """
    monkeypatch.setenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
    monkeypatch.delenv("GOOGLE_APPLICATION_CREDENTIALS", raising=False)
    monkeypatch.setattr(config, "firebase_project_id", "demo-clubnahuelmosse")
    monkeypatch.setattr(config, "firebase_credenciales_json", "")

    assert isinstance(crear_app(), FastAPI)


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
