import pytest

from app.modules.notifications.push import build_message
from app.modules.notifications.rules import Notice

# firebase_admin avisa que `tokens` está deprecado en favor de `fids`; el canal real lo usa igual.
pytestmark = pytest.mark.filterwarnings("ignore:MulticastMessage.tokens:DeprecationWarning")


def test_el_aviso_de_anulacion_lleva_una_clave_estable_para_reemplazar_al_anterior() -> None:
    """el agrupado toma el lugar del aviso anterior en la bandeja @supuesto:CU-24.2-SUP-09"""
    uno = build_message(["t"], Notice("a", "b", {"tipo": "cancelacion_forzosa", "reserva_id": "1"}))
    varios = build_message(["t"], Notice("a", "b", {"tipo": "cancelacion_forzosa"}))

    for m in (uno, varios):
        assert m.android is not None
        assert m.android.collapse_key == "cancelacion_forzosa"
        assert m.android.notification is not None
        assert m.android.notification.tag == "cancelacion_forzosa"
        assert m.apns is not None
        assert m.apns.headers == {"apns-collapse-id": "cancelacion_forzosa"}


def test_los_demas_avisos_no_se_reemplazan_entre_si() -> None:
    m = build_message(["t"], Notice("a", "b", {"tipo": "recordatorio", "reserva_id": "1"}))

    assert m.android is None
    assert m.apns is None
