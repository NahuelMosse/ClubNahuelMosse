"""Bordes de las reglas de avisos: tipo desconocido, un solo anulado y el límite del motivo."""

from datetime import UTC, datetime
from uuid import uuid4

from app.modules.notifications.rules import (
    REASON_LIMIT,
    VoidedBooking,
    forced_cancellation_message,
    forced_cancellations_message,
    short_kind,
)
from app.modules.spaces import CATALOG

START = datetime(2026, 5, 4, 15, 0, tzinfo=UTC)


def _voided(reason: str) -> VoidedBooking:
    sport = CATALOG[0]
    return VoidedBooking(
        booking_id=uuid4(),
        starts_at=START,
        sport=sport.key,
        kind=sport.kinds[0].key,
        venue="Sede Centro",
        reason=reason,
    )


def test_un_tipo_desconocido_del_deporte_nombra_el_deporte_y_no_falla() -> None:  # @ENG-14-S1
    sport = CATALOG[0]
    assert short_kind(sport.key, "no-existe") == sport.key
    assert short_kind("no-existe", "no-existe") == "no-existe"


def test_un_solo_anulado_lleva_su_reserva_y_varios_sólo_la_cuenta() -> None:  # @ENG-14-S1
    one = forced_cancellation_message([_voided("Lluvia")])
    assert one.title == "El club anuló tu reserva"
    assert one.data["booking_id"]

    two = forced_cancellation_message([_voided("Lluvia"), _voided("Lluvia")])
    assert two == forced_cancellations_message(2)
    assert two.title == "El club anuló 2 de tus reservas"
    assert two.data == {"kind": "forced_cancellation"}


def test_el_motivo_en_el_límite_exacto_no_se_recorta() -> None:  # @ENG-14-S1
    exact = "m" * REASON_LIMIT
    assert f"Motivo: {exact}." in forced_cancellation_message([_voided(exact)]).body

    over = forced_cancellation_message([_voided("m" * (REASON_LIMIT + 1))]).body
    assert "…" in over
