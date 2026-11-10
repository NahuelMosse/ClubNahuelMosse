from datetime import UTC, datetime
from uuid import UUID

from app.modules.notifications.rules import VoidedBooking, forced_cancellation_message


def _anulada(reserva_id: int = 7, motivo: str = "mantenimiento de la cancha") -> VoidedBooking:
    return VoidedBooking(
        booking_id=UUID(int=reserva_id),
        # Wed 11 a las 20:00 en el club (UTC−3)
        starts_at=datetime(2026, 11, 11, 23, 0, tzinfo=UTC),
        sport="Futbol",
        kind="F5",
        venue="Sede Ramos Mejía",
        reason=motivo,
    )


def test_una_reserva_dice_deporte_sede_dia_hora_y_motivo() -> None:
    notice = forced_cancellation_message([_anulada()])

    assert notice.title == "The club voided your booking"
    assert notice.body == (
        "Football 5 · Sede Ramos Mejía · Wed 11, 20:00. Reason: mantenimiento de la cancha."
    )
    assert notice.data == {"kind": "forced_cancellation", "booking_id": str(UUID(int=7))}


def test_varias_reservas_dicen_cuantas_son_y_no_apuntan_a_una() -> None:
    notice = forced_cancellation_message([_anulada(1), _anulada(2), _anulada(3)])

    assert notice.title == "The club voided 3 of your bookings"
    assert notice.body == "You have 3 bookings voided by the club. See the detail in your history."
    assert notice.data == {"kind": "forced_cancellation"}


def test_el_motivo_de_mas_de_doscientos_caracteres_se_recorta() -> None:
    motivo = "x" * 200

    body = forced_cancellation_message([_anulada(motivo=motivo)]).body
    assert body.endswith(f"Reason: {motivo}.")

    body = forced_cancellation_message([_anulada(motivo=motivo + "y")]).body
    assert body.endswith(f"Reason: {'x' * 199}….")
