"""Datos: el límite de una tanda del historial global.

Los helpers y los fixtures son los de test_datos.py.
"""

from fastapi.testclient import TestClient
from test_datos import (  # noqa: F401 — los fixtures se importan para que pytest los vea
    _barrer,
    _cancelar,
    _despachar,
    _empate,
    _envios,
    _pasadas,
    _recordatorio,
    canal,
    socio,
    token_admin,
)
from test_recordatorio import Socio


def test_una_tanda_justa_del_historial_global_no_ofrece_otra(
    api: TestClient, socio: Socio, token_admin: str
) -> None:
    """con exactamente 20 reservas el historial global no devuelve marcador de siguiente tanda
    @REV-03-S3
    """
    _pasadas(socio, 20)
    admin = {"Authorization": f"Bearer {token_admin}"}

    r = api.get("/reservas/todas", headers=admin, params={"q": socio.sede}).json()

    assert len(r["reservas"]) == 20
    assert r["siguiente"] is None
