"""Datos (continuación): historiales, índices, cola de avisos y migración 0008.

Los helpers y los fixtures son los de test_datos.py.
"""

import threading
from collections.abc import Callable
from typing import Any

from alembic import command
from alembic.config import Config as AlembicConfig
from fastapi.testclient import TestClient
from sqlalchemy import Engine, event, text
from test_datos import (  # noqa: F401 — los fixtures se importan para que pytest los vea
    _barrer,
    _cancelar,
    _capturar,
    _despachar,
    _empate,
    _envios,
    _pasadas,
    _recordatorio,
    _varar,
    base_de_migraciones,
    canal,
    socio,
    token_admin,
)
from test_recordatorio import Socio


def _ids_del_socio(socio: Socio) -> set[str]:
    with socio.motor.connect() as conn:
        return {
            str(f.id)
            for f in conn.execute(
                text("SELECT id FROM reserva WHERE usuario_id = :u"), {"u": socio.usuario_id}
            )
        }


def _historial(socio: Socio, **params: str) -> dict[str, Any]:
    r = socio.api.get("/reservas", headers=socio.sesion, params={"cuando": "historial", **params})
    assert r.status_code == 200
    cuerpo: dict[str, Any] = r.json()
    return cuerpo


def _capturar_sql(accion: Callable[[], None]) -> list[tuple[str, Any]]:
    """Las sentencias que la base recibe mientras corre [accion]."""
    vistas: list[tuple[str, Any]] = []

    def escuchar(conn: Any, cursor: Any, statement: str, parameters: Any, *_: Any) -> None:
        vistas.append((statement, parameters))

    event.listen(Engine, "before_cursor_execute", escuchar)
    try:
        accion()
    finally:
        event.remove(Engine, "before_cursor_execute", escuchar)
    return vistas


def test_el_total_y_los_contadores_siguen_exactos_en_una_sola_consulta(
    api: TestClient, socio: Socio, token_admin: str
) -> None:
    """el total y los contadores del historial global siguen exactos, como pide CU-14, en una sola
    consulta @REV-03-S3 @assumption:REV-03-ASM-10
    """
    _pasadas(socio, 25)
    admin = {"Authorization": f"Bearer {token_admin}"}
    cuerpos: list[dict[str, Any]] = []

    sentencias = _capturar_sql(
        lambda: cuerpos.append(
            api.get("/reservas/todas", headers=admin, params={"q": socio.sede}).json()
        )
    )

    assert cuerpos[0]["total"] == 25
    assert cuerpos[0]["contadores"]["todas"] == 25
    assert cuerpos[0]["contadores"]["completadas"] == 25
    assert len([s for s, _ in sentencias if "count(*)" in s.lower()]) == 1


def test_en_el_historial_propio_con_el_mismo_inicio_va_primero_el_id_mas_alto(
    socio: Socio,
) -> None:
    """en el historial propio, con el mismo inicio va primero el id más alto y llegan todas
    @REV-03-S2
    """
    _pasadas(socio, 20)
    _empate(socio)

    todas = _historial(socio)["reservas"]

    claves = [(r["inicio"], r["id"]) for r in todas]
    assert claves == sorted(claves, reverse=True)
    assert {r["id"] for r in todas} == _ids_del_socio(socio)
    assert len(todas) == 21


def test_las_proximas_reservas_siguen_llegando_enteras(socio: Socio) -> None:
    """las próximas reservas siguen llegando enteras @REV-03-S2 @assumption:REV-03-ASM-16"""
    with socio.motor.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total)"
                " SELECT :u, :e, h + make_interval(days => n), h + make_interval(days => n)"
                " + interval '1 hour', 38000, 38000 FROM generate_series(1, 25) AS n,"
                " (SELECT date_trunc('hour', now()) AS h) AS t"
            ),
            {"u": socio.usuario_id, "e": socio.espacio_id},
        )

    r = socio.api.get("/reservas", headers=socio.sesion, params={"cuando": "proximas"}).json()

    assert len(r["reservas"]) == 25


def test_la_migracion_0008_corta_por_lock_timeout_y_se_puede_volver_a_correr(
    base_de_migraciones: tuple[Engine, AlembicConfig],
) -> None:
    """la migración 0008 corta por lock_timeout si una transacción larga tiene la tabla
    @REV-03-S7 @assumption:REV-03-ASM-15
    """
    base, alembic = base_de_migraciones
    command.upgrade(alembic, "0007")
    bloqueo = base.connect()
    bloqueo.execute(text("LOCK TABLE notificacion IN ACCESS EXCLUSIVE MODE"))
    resultado: list[BaseException] = []
    hilo = threading.Thread(
        target=lambda: _capturar(resultado, lambda: command.upgrade(alembic, "0008"))
    )

    hilo.start()
    hilo.join(timeout=60)
    bloqueo.rollback()
    bloqueo.close()

    assert not hilo.is_alive()
    assert "lock timeout" in str(resultado[0])
    with base.connect() as conn:
        version = conn.execute(text("SELECT version_num FROM alembic_version")).scalar_one()
    assert version == "0007"
    command.upgrade(alembic, "0008")
