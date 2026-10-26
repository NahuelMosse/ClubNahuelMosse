"""Operación: recordatorios fuera del proceso web, avisos que no salen, versión y configuración."""

import logging
import os
import subprocess
import sys
import tomllib
from collections.abc import Callable
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text

from app.config import Config, config

RAIZ_API = Path(__file__).resolve().parents[2]
CONTRASENA = "ClubNahuel1"
VERSION = tomllib.loads((RAIZ_API / "pyproject.toml").read_text(encoding="utf-8"))["project"][
    "version"
]


def _datos_de_alta(s: str) -> dict[str, str]:
    return {
        "nombre": "Martín",
        "apellido": "Ferreyra",
        "dni": str(int(s, 16) % 90_000_000 + 10_000_000),
        "fecha_nacimiento": "1994-07-21",
        "correo": f"socio.{s}@correo.com",
        "contrasena": CONTRASENA,
    }


def _reserva_en_la_proxima_hora(motor: Engine, correo: str, s: str) -> int:
    with motor.begin() as conn:
        return int(
            conn.execute(
                text(
                    "WITH s AS (INSERT INTO sede (nombre, calle, altura, apertura, cierre, dias)"
                    " VALUES (:n, 'Av. Vergara', 1850, '00:00', '23:59', ARRAY[1,2,3,4,5,6,7])"
                    " RETURNING id),"
                    " e AS (INSERT INTO espacio (sede_id, deporte, tipo, numero, nombre, techada,"
                    " iluminada, precio_por_hora) SELECT id, 'Futbol', 'F5', 1, :e, false, true,"
                    " 38000 FROM s RETURNING id)"
                    " INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora,"
                    " total, creado_en, modificado_en)"
                    " SELECT u.id, e.id, h, h + interval '1 hour', 38000, 38000,"
                    " now() - interval '2 hours', now() - interval '2 hours' FROM usuario u, e,"
                    " (SELECT date_trunc('hour', now(), 'America/Argentina/Buenos_Aires')"
                    " + interval '1 hour' AS h) AS t WHERE u.correo = :c AND u.activo"
                    " RETURNING reserva.id"
                ),
                {"n": f"Sede Haedo {s}", "e": f"Haedo{s}_Vergara_1850_Futbol_F5_1", "c": correo},
            ).scalar_one()
        )


def test_los_recordatorios_salen_con_un_comando_fuera_del_servicio_web(
    api: TestClient, motor: Engine, unico: Callable[[], str]
) -> None:
    """los recordatorios salen aunque el servicio web esté dormido @REV-02-S3
    @assumption:REV-02-ASM-02
    """
    s = unico()
    api.post("/registro", json=_datos_de_alta(s))
    reserva = _reserva_en_la_proxima_hora(motor, f"socio.{s}@correo.com", s)

    corrida = subprocess.run(
        [sys.executable, "-m", "app.interfaz.barrido", "--una-vez"],
        cwd=RAIZ_API, env={**os.environ, "PYTHONUTF8": "1"},
        capture_output=True, text=True, timeout=120, check=False,
    )  # fmt: skip

    assert corrida.returncode == 0, corrida.stdout + corrida.stderr
    with motor.connect() as conn:
        avisos = conn.execute(
            text("SELECT count(*) FROM notificacion WHERE tipo = 'recordatorio' AND reserva_id = :r"),
            {"r": reserva},
        ).scalar_one()
    assert avisos == 1


class _CanalQueFalla:
    def enviar(self, tokens: list[str], aviso: object) -> object:
        raise ConnectionError("FCM no responde")


def test_un_aviso_que_no_salio_queda_a_la_vista(
    motor: Engine, caplog: pytest.LogCaptureFixture
) -> None:
    """un recordatorio que no salió queda a la vista de quien opera @REV-02-S4"""
    from app.aplicacion.notificaciones import despachar_pendientes
    from app.infraestructura.notificaciones import NotificacionesSql

    with motor.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, envio)"
                " SELECT id, 'cancelacion_usuario', 'Cancelaste tu reserva', 'Fútbol 5',"
                " 'pendiente' FROM usuario WHERE activo LIMIT 1"
            )
        )
        conn.execute(
            text(
                "INSERT INTO dispositivo (usuario_id, token, plataforma, permiso)"
                " SELECT usuario_id, 'fcm-' || id, 'android', true FROM notificacion"
                " WHERE envio = 'pendiente' ON CONFLICT DO NOTHING"
            )
        )

    with caplog.at_level(logging.INFO), motor.connect() as conn:
        despachar_pendientes(NotificacionesSql(conn), _CanalQueFalla())

    errores = [r for r in caplog.records if r.levelno >= logging.ERROR]
    assert any("aviso_sin_enviar" in r.getMessage() for r in errores)
    assert not any("fcm-" in r.getMessage() for r in caplog.records)


def test_la_version_vive_en_pyproject_y_la_api_la_expone(api: TestClient) -> None:
    """la versión vive en pyproject.toml y la API la expone @REV-02-S14 @assumption:REV-02-ASM-09"""
    salud = api.get("/health").json()

    assert salud["version"] == VERSION
    assert config.version == VERSION


def test_la_version_vive_en_un_solo_lugar_y_la_api_la_expone(api: TestClient) -> None:
    """la versión vive en un solo lugar y la API la expone @REV-02-S14"""
    contrato = api.get("/openapi.json").json()

    assert contrato["info"]["version"] == VERSION
    assert VERSION not in (RAIZ_API / "app" / "main.py").read_text(encoding="utf-8")


def test_la_configuracion_se_lee_igual_desde_cualquier_carpeta() -> None:
    """la configuración se lee igual desde cualquier carpeta de arranque @REV-02-S15"""
    archivo = Path(str(Config.model_config.get("env_file")))

    assert archivo.is_absolute()
    assert archivo == RAIZ_API / ".env"
