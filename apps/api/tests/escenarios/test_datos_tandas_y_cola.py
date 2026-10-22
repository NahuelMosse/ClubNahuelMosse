"""Datos (continuación): tandas, índices, cola de avisos y migración 0008.

Los helpers y los fixtures son los de test_datos.py.
"""

import threading
from collections.abc import Callable
from datetime import UTC, datetime
from typing import Any

import pytest
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
from test_recordatorio import CanalDePrueba, Socio

from app.dominio.reservas import Marcador
from app.interfaz.marcador import codificar


def _ids_del_socio(socio: Socio) -> set[int]:
    with socio.motor.connect() as conn:
        return {
            int(f.id)
            for f in conn.execute(
                text("SELECT id FROM reserva WHERE usuario_id = :u"), {"u": socio.usuario_id}
            )
        }


def _historial(socio: Socio, **params: str) -> dict[str, Any]:
    r = socio.api.get("/reservas", headers=socio.sesion, params={"cuando": "historial", **params})
    assert r.status_code == 200
    cuerpo: dict[str, Any] = r.json()
    return cuerpo


def test_el_historial_propio_trae_tandas_de_20_y_sin_marcador_las_mas_recientes(
    socio: Socio,
) -> None:
    """el historial propio trae tandas de 20 y sin marcador las 20 más recientes
    @REV-03-S2 @assumption:REV-03-ASM-03
    """
    _pasadas(socio, 25)

    primera = _historial(socio)

    inicios = [r["inicio"] for r in primera["reservas"]]
    assert len(inicios) == 20
    assert inicios == sorted(inicios, reverse=True)
    assert primera["siguiente"] is not None
    assert len(_historial(socio, despues=primera["siguiente"])["reservas"]) == 5


def test_con_el_mismo_inicio_el_historial_global_pone_primero_el_id_mas_alto(
    api: TestClient, socio: Socio, token_admin: str
) -> None:
    """con el mismo inicio va primero el id más alto @REV-03-S3 @assumption:REV-03-ASM-07"""
    _pasadas(socio, 20)
    _empate(socio)
    admin = {"Authorization": f"Bearer {token_admin}"}

    r = api.get("/reservas/todas", headers=admin, params={"q": socio.sede}).json()["reservas"]

    claves = [(x["inicio"], x["id"]) for x in r]
    assert len(claves) == 21
    assert claves == sorted(claves, reverse=True)
    assert len({inicio for inicio, _ in claves}) == 20


def test_una_reserva_nueva_no_aparece_en_las_tandas_ya_vistas(socio: Socio) -> None:
    """una reserva nueva no aparece en las tandas ya vistas y sí al volver a abrir el historial
    @REV-03-S2 @assumption:REV-03-ASM-08
    """
    _pasadas(socio, 25)
    primera = _historial(socio)
    with socio.motor.begin() as conn:
        nueva = conn.execute(
            text(
                "INSERT INTO reserva (usuario_id, espacio_id, inicio, fin, precio_por_hora, total)"
                " SELECT :u, :e, h - interval '1 hour', h, 38000, 38000 FROM"
                " (SELECT date_trunc('hour', now(), 'America/Argentina/Buenos_Aires') AS h) AS t"
                " RETURNING id"
            ),
            {"u": socio.usuario_id, "e": socio.espacio_id},
        ).scalar_one()

    segunda = _historial(socio, despues=primera["siguiente"])

    assert nueva not in [r["id"] for r in segunda["reservas"]]
    assert _historial(socio)["reservas"][0]["id"] == nueva


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


def test_la_pagina_avanzada_del_historial_global_no_recorre_las_filas_anteriores(
    api: TestClient, socio: Socio, token_admin: str
) -> None:
    """la página avanzada del historial global no recorre las filas anteriores y el total se cuenta
    con índice @REV-03-S3 @assumption:REV-03-ASM-12
    """
    _pasadas(socio, 25)
    admin = {"Authorization": f"Bearer {token_admin}"}
    primera = api.get("/reservas/todas", headers=admin, params={"q": socio.sede}).json()

    sentencias = _capturar_sql(
        lambda: api.get(
            "/reservas/todas",
            headers=admin,
            params={"q": socio.sede, "despues": primera["siguiente"]},
        ).json()
    )

    [(pagina, parametros)] = [
        (s, p) for s, p in sentencias if "ORDER BY r.inicio DESC" in s and "LIMIT" in s
    ]
    assert parametros["offset"] == 0
    with socio.motor.connect() as conn:
        conn.exec_driver_sql("SET enable_seqscan = off")
        plan = "\n".join(str(f[0]) for f in conn.exec_driver_sql("EXPLAIN " + pagina, parametros))
    assert "reserva_por_inicio" in plan


def test_en_el_historial_propio_con_el_mismo_inicio_va_primero_el_id_mas_alto(
    socio: Socio,
) -> None:
    """en el historial propio, con el mismo inicio va primero el id más alto y ninguna tanda
    saltea ni repite @REV-03-S2 @assumption:REV-03-ASM-13
    """
    _pasadas(socio, 20)
    _empate(socio)
    primera = _historial(socio)
    segunda = _historial(socio, despues=primera["siguiente"])

    todas = primera["reservas"] + segunda["reservas"]

    claves = [(r["inicio"], r["id"]) for r in todas]
    assert claves == sorted(claves, reverse=True)
    assert {r["id"] for r in todas} == _ids_del_socio(socio)
    assert len(todas) == 21


def test_un_marcador_armado_a_mano_o_del_historial_global_solo_trae_reservas_propias(
    api: TestClient, socio: Socio, token_admin: str
) -> None:
    """un marcador armado a mano o tomado del historial global sólo trae reservas propias
    @REV-03-S2 @assumption:REV-03-ASM-01
    """
    _pasadas(socio, 25)
    admin = {"Authorization": f"Bearer {token_admin}"}
    del_global = api.get("/reservas/todas", headers=admin).json()["siguiente"]
    a_mano = codificar(Marcador(datetime(2999, 1, 1, tzinfo=UTC), 2**62))
    despues_del_final = codificar(Marcador(datetime(2000, 1, 1, tzinfo=UTC), 1))

    for marcador in (del_global, a_mano):
        if marcador is not None:
            tanda = _historial(socio, despues=marcador)
            assert {r["id"] for r in tanda["reservas"]} <= _ids_del_socio(socio)
    vacia = _historial(socio, despues=despues_del_final)
    assert vacia["reservas"] == []
    assert vacia["siguiente"] is None


def test_las_proximas_reservas_siguen_llegando_enteras_sin_tandas(socio: Socio) -> None:
    """las próximas reservas siguen llegando enteras, sin tandas @REV-03-S2
    @assumption:REV-03-ASM-16
    """
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
    assert r["siguiente"] is None


def test_el_openapi_documenta_despues_siguiente_y_el_422(api: TestClient) -> None:
    """el OpenAPI documenta despues, siguiente y el 422 del marcador
    @REV-03-S2 @assumption:REV-03-ASM-01
    """
    doc = api.get("/openapi.json").json()
    operacion = doc["paths"]["/reservas"]["get"]

    assert "despues" in [p["name"] for p in operacion["parameters"]]
    assert "422" in operacion["responses"]
    assert "siguiente" in doc["components"]["schemas"]["ListaDeReservas"]["properties"]
    assert "despues" in [p["name"] for p in doc["paths"]["/reservas/todas"]["get"]["parameters"]]


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


def test_de_cada_intento_quedan_tomada_en_e_intentos_y_el_error_va_al_log(
    socio: Socio, canal: CanalDePrueba
) -> None:
    """de cada intento quedan tomada_en e intentos y el error va al log, no a la base
    @REV-03-S5 @assumption:REV-03-ASM-09
    """
    _cancelar(socio, "20:00")
    with socio.motor.begin() as conn:
        conn.execute(
            text("UPDATE notificacion SET envio = 'pendiente' WHERE usuario_id = :u"),
            {"u": socio.usuario_id},
        )

    _despachar(socio, canal)

    with socio.motor.connect() as conn:
        [(tomada_en, intentos)] = conn.execute(
            text("SELECT tomada_en, intentos FROM notificacion WHERE usuario_id = :u"),
            {"u": socio.usuario_id},
        ).all()
        columnas = {
            str(f.column_name)
            for f in conn.execute(
                text(
                    "SELECT column_name FROM information_schema.columns"
                    " WHERE table_name = 'notificacion'"
                )
            )
        }
    assert tomada_en is not None
    assert intentos == 1
    assert not {c for c in columnas if "error" in c}


def test_la_linea_aviso_sin_enviar_no_lleva_token_correo_ni_cuerpo(
    socio: Socio, canal: CanalDePrueba, caplog: pytest.LogCaptureFixture
) -> None:
    """la línea aviso_sin_enviar no lleva el token, el correo ni el cuerpo del aviso
    @REV-03-S5 @assumption:REV-03-ASM-09
    """
    _cancelar(socio, "20:00")
    _varar(socio, "10 minutes", intentos=3)
    with socio.motor.connect() as conn:
        cuerpo = str(
            conn.execute(
                text("SELECT cuerpo FROM notificacion WHERE usuario_id = :u"),
                {"u": socio.usuario_id},
            ).scalar_one()
        )
        correo = str(
            conn.execute(
                text("SELECT correo FROM usuario WHERE id = :u"), {"u": socio.usuario_id}
            ).scalar_one()
        )
        tokens = [
            str(f.token)
            for f in conn.execute(
                text("SELECT token FROM dispositivo WHERE usuario_id = :u"),
                {"u": socio.usuario_id},
            )
        ]

    with caplog.at_level("ERROR"):
        _despachar(socio, canal)

    lineas = [r.getMessage() for r in caplog.records if "aviso_sin_enviar" in r.getMessage()]
    assert len(lineas) == 1
    for secreto in [cuerpo, correo, *tokens]:
        assert secreto not in lineas[0]


def test_el_recordatorio_de_una_reserva_que_ya_empezo_no_se_reintenta(
    socio: Socio, canal: CanalDePrueba
) -> None:
    """el recordatorio de una reserva que ya empezó no se reintenta y queda fallido
    @REV-03-S6 @assumption:REV-03-ASM-14
    """
    _recordatorio(socio, "pendiente", "10 minutes")
    with socio.motor.begin() as conn:
        conn.execute(
            text(
                "UPDATE reserva SET inicio = now() - interval '30 minutes',"
                " fin = now() + interval '30 minutes' WHERE id = :r"
            ),
            {"r": socio.reservas[-1]["id"]},
        )
        conn.execute(
            text(
                "UPDATE notificacion SET reserva_inicio = now() - interval '30 minutes'"
                " WHERE usuario_id = :u"
            ),
            {"u": socio.usuario_id},
        )
    canal.enviados.clear()

    _barrer(socio, canal)

    assert _envios(socio) == ["fallida"]
    assert canal.enviados == []


def test_una_confirmacion_de_cancelacion_que_quedo_enviando_se_vuelve_a_enviar(
    socio: Socio, canal: CanalDePrueba
) -> None:
    """una confirmación de cancelación que quedó enviando se vuelve a enviar
    @REV-03-S5 @assumption:REV-03-ASM-04
    """
    _cancelar(socio, "20:00")
    with socio.motor.begin() as conn:
        conn.execute(
            text(
                "UPDATE notificacion SET envio = 'enviando', enviada_en = NULL, tomada_en = NULL,"
                " creada_en = now() - interval '10 minutes' WHERE usuario_id = :u"
            ),
            {"u": socio.usuario_id},
        )
    canal.enviados.clear()

    _despachar(socio, canal)

    assert _envios(socio) == ["enviada"]
    assert len(canal.enviados) == 1


def test_la_trazabilidad_del_admin_muestra_el_aviso_fallido_como_fallido(
    api: TestClient, socio: Socio, token_admin: str, canal: CanalDePrueba
) -> None:
    """la trazabilidad del admin muestra el aviso fallido como fallido, no como pendiente
    @REV-03-S5 @assumption:REV-03-ASM-17
    """
    _cancelar(socio, "20:00")
    _varar(socio, "10 minutes", intentos=3)
    _despachar(socio, canal)
    admin = {"Authorization": f"Bearer {token_admin}"}

    r = api.get("/reservas/todas", headers=admin, params={"q": socio.sede}).json()["reservas"]

    assert [x["aviso_envio"] for x in r if x["id"] == socio.reservas[-1]["id"]] == ["fallida"]
