"""Datos: reemplazo del test del plan de la página avanzada de test_datos_tandas_y_cola.py.

Con los datos que dejan los demás tests, el planificador puede filtrar por otro índice y ordenar
después; con el orden por índice obligado, el plan muestra si `reserva_por_inicio` sirve la página.
"""

from fastapi.testclient import TestClient
from test_datos import (  # noqa: F401 — los fixtures se importan para que pytest los vea
    _pasadas,
    socio,
    token_admin,
)
from test_datos_tandas_y_cola import _capturar_sql
from test_recordatorio import Socio


def test_la_pagina_avanzada_del_historial_global_no_recorre_las_filas_anteriores(
    api: TestClient, socio: Socio, token_admin: str
) -> None:
    """la página avanzada del historial global no recorre las filas anteriores y el total se cuenta
    con índice @REV-03-S3 @assumption:REV-03-ASM-12 @INT-01-ASM-01
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
        conn.exec_driver_sql("SET enable_sort = off")
        plan = "\n".join(str(f[0]) for f in conn.exec_driver_sql("EXPLAIN " + pagina, parametros))
    assert "reserva_por_inicio" in plan
