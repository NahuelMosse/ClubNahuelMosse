"""SIM-01 contra la base y el emulador reales: historial sin marcador, avisos sin reintentos."""

import os
from collections.abc import Sequence
from datetime import date, timedelta
from pathlib import Path
from typing import Any
from uuid import UUID

from alembic import command
from alembic.config import Config as AlembicConfig
from fastapi.testclient import TestClient
from sqlalchemy import Engine, create_engine, text

from app.modules.notifications.rules import Notice, DeliveryResult
from tests.integracion.test_uuid_y_auditoria import base_nueva  # noqa: F401  (fixture)

RAIZ_API = Path(__file__).resolve().parents[2]
URL_PRUEBAS = os.environ["DATABASE_URL"]


def _con(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _espacio(api: TestClient, token_admin: str, sede_id: str) -> str:
    r = api.post(
        "/espacios",
        headers=_con(token_admin),
        json={
            "sede_id": sede_id,
            "deporte": "Futbol",
            "tipo": "F5",
            "techada": False,
            "iluminada": True,
            "precio_por_hora": 38000,
        },
    )
    return str(r.json()["id"])


def _reservar(api: TestClient, token: str, espacio: str, dia: int, hora: int) -> dict[str, Any]:
    r = api.post(
        "/reservas",
        headers=_con(token),
        json={
            "espacio_id": espacio,
            "fecha": (date.today() + timedelta(days=dia)).isoformat(),
            "desde": f"{hora:02d}:00",
            "horas": 1,
        },
    )
    assert r.status_code == 201, r.text
    cuerpo: dict[str, Any] = r.json()
    return cuerpo


def test_el_historial_propio_es_el_listado_entero_y_sin_marcador(
    api: TestClient, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> None:
    """el historial propio es el listado ordenadas por fecha, entero y sin marcador @SIM-01-S1 @assumption:SIM-01-ASM-01"""
    espacio = _espacio(api, token_admin, sede[0])
    creadas = [
        _reservar(api, token_usuario, espacio, d, h)["id"] for d in (1, 2) for h in range(8, 19)
    ]

    r = api.get("/reservas", headers=_con(token_usuario), params={"cuando": "proximas"})

    assert r.status_code == 200
    assert "siguiente" not in r.json()
    assert [x["id"] for x in r.json()["reservas"]] == creadas
    assert api.get("/reservas?despues=x", headers=_con(token_usuario)).status_code == 200


def test_el_historial_del_administrador_sigue_paginando_por_numero_de_pagina(
    api: TestClient, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> None:
    """el historial del administrador sigue paginando por número de página @SIM-01-S2 @assumption:SIM-01-ASM-01"""
    espacio = _espacio(api, token_admin, sede[0])
    for h in range(8, 8 + 22):
        _reservar(api, token_usuario, espacio, 1 + (h - 8) // 11, 8 + (h - 8) % 11)
    q = {"q": sede[1]}

    primera = api.get("/reservas/todas", headers=_con(token_admin), params={**q, "pagina": 1})
    segunda = api.get("/reservas/todas", headers=_con(token_admin), params={**q, "pagina": 2})

    assert primera.status_code == segunda.status_code == 200
    assert len(primera.json()["reservas"]) == 20 and len(segunda.json()["reservas"]) == 2
    assert "siguiente" not in primera.json()


def test_una_reserva_sobrevive_a_reiniciar_la_api(
    api: TestClient, token_admin: str, token_usuario: str, sede: tuple[str, str]
) -> None:
    """una reserva sobrevive a reiniciar la API sobre la misma base @SIM-01-S2"""
    from app.main import create_app

    espacio = _espacio(api, token_admin, sede[0])
    creada = _reservar(api, token_usuario, espacio, 1, 10)["id"]

    with TestClient(create_app()) as otra:
        r = otra.get("/reservas", headers=_con(token_usuario))
    assert creada in [x["id"] for x in r.json()["reservas"]]


class _CanalQueFalla:
    llamadas = 0

    def send(self, tokens: Sequence[str], aviso: Notice) -> DeliveryResult:
        type(self).llamadas += 1
        raise ConnectionError("FCM no responde")


def test_un_aviso_que_falla_queda_fallido_y_no_se_reintenta(motor: Engine) -> None:
    """un aviso que falla queda fallido y no se vuelve a intentar @SIM-01-S1 @assumption:SIM-01-ASM-02"""
    from app.modules.notifications.use_cases import dispatch_pending
    from app.modules.notifications.repository import NotificationsSql

    with motor.begin() as conn:
        id_: UUID = conn.execute(
            text(
                "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, envio)"
                " SELECT id, 'cancelacion_forzosa', 'Cancelaron', 'Fútbol 5', 'pendiente'"
                " FROM usuario WHERE activo LIMIT 1 RETURNING id"
            )
        ).scalar_one()
        conn.execute(
            text(
                "INSERT INTO dispositivo (usuario_id, token, plataforma, permiso)"
                " SELECT usuario_id, 'fcm-sim01-' || id, 'android', true FROM notificacion"
                " WHERE id = :id ON CONFLICT DO NOTHING"
            ),
            {"id": id_},
        )
    canal = _CanalQueFalla()
    with motor.connect() as conn:
        dispatch_pending(NotificationsSql(conn), canal)
        tras_el_primero = _CanalQueFalla.llamadas
        dispatch_pending(NotificationsSql(conn), canal)
    with motor.connect() as conn:
        envio: str = conn.execute(
            text("SELECT envio FROM notificacion WHERE id = :id"), {"id": id_}
        ).scalar_one()
    assert envio == "fallida"
    assert tras_el_primero >= 1 and _CanalQueFalla.llamadas == tras_el_primero


def test_notificacion_ya_no_tiene_intentos_ni_tomada_en(motor: Engine) -> None:
    """la base ya no tiene intentos ni tomada_en en notificacion @assumption:SIM-01-ASM-02"""
    with motor.connect() as conn:
        columnas = {
            f[0]
            for f in conn.execute(
                text(
                    "SELECT column_name FROM information_schema.columns"
                    " WHERE table_name = 'notificacion'"
                )
            )
        }
    assert columnas and not {"intentos", "tomada_en"} & columnas


def test_la_migracion_0009_pasa_a_fallida_un_aviso_que_estaba_enviando(
    base_nueva: tuple[AlembicConfig, str],  # noqa: F811  (la fixture importada)
) -> None:
    """la migración 0009 pasa a fallida un aviso que estaba enviando @assumption:SIM-01-ASM-07"""
    # En una base propia: la base compartida no puede volver a 0008 una vez que la 0010
    # creó filas con ids nuevos (DAT-01-ASM-02).
    alembic, url = base_nueva
    command.upgrade(alembic, "0008")
    motor = create_engine(url)
    try:
        with motor.begin() as conn:
            conn.execute(
                text(
                    "INSERT INTO usuario (firebase_uid, correo, nombre, apellido, dni,"
                    " fecha_nacimiento) VALUES ('uid-0009', 'a@correo.com', 'Ana', 'Pérez',"
                    " '30111222', '2000-03-14')"
                )
            )
            id_: int = conn.execute(
                text(
                    "INSERT INTO notificacion (usuario_id, tipo, titulo, cuerpo, envio, tomada_en)"
                    " SELECT id, 'cancelacion_forzosa', 'Cancelaron', 'Fútbol 5', 'enviando', now()"
                    " FROM usuario LIMIT 1 RETURNING id"
                )
            ).scalar_one()
        command.upgrade(alembic, "0009")
        with motor.connect() as conn:
            envio: str = conn.execute(
                text("SELECT envio FROM notificacion WHERE id = :id"), {"id": id_}
            ).scalar_one()
    finally:
        motor.dispose()
    assert envio == "fallida"
