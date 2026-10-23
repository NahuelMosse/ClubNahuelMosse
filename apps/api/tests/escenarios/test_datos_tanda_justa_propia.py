"""Datos: el límite de una tanda del historial propio.

Los helpers y los fixtures son los de test_datos.py.
"""

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


def test_una_tanda_justa_del_historial_propio_no_ofrece_otra(socio: Socio) -> None:
    """con exactamente 20 reservas el historial propio no devuelve marcador de siguiente tanda
    @REV-03-S2
    """
    _pasadas(socio, 20)

    r = socio.api.get("/reservas", headers=socio.sesion, params={"cuando": "historial"}).json()

    assert len(r["reservas"]) == 20
    assert r["siguiente"] is None
