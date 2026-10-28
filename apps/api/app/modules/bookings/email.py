from app.modules.bookings.rules import Booking
from app.modules.notifications import short_kind
from app.modules.session import Profile
from app.shared.club_timezone import CLUB_TIMEZONE
from app.shared.email_template import html_email
from app.shared.message import Message

DAYS = ("lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo")
MONTHS = (
    "enero",
    "febrero",
    "marzo",
    "abril",
    "mayo",
    "junio",
    "julio",
    "agosto",
    "septiembre",
    "octubre",
    "noviembre",
    "diciembre",
)
SUBJECT = "Tu reserva está confirmada"


def _money(amount: int) -> str:
    """«$ 12.000», with a dot as thousands separator as it reads in es-AR."""
    return f"$ {amount:,}".replace(",", ".")


def booking_email(profile: Profile, booking: Booking) -> Message:
    """The confirmation of a new booking, with the club's day and time."""
    starts = booking.starts_at.astimezone(CLUB_TIMEZONE)
    ends = booking.ends_at.astimezone(CLUB_TIMEZONE)
    details = [
        ("Cancha", short_kind(booking.sport, booking.kind)),
        ("Sede", booking.venue),
        ("Día", f"{DAYS[starts.weekday()]} {starts.day} de {MONTHS[starts.month - 1]}"),
        ("Horario", f"{starts:%H:%M} a {ends:%H:%M}"),
        ("Total", _money(booking.total)),
    ]
    greeting = f"Hola {profile.first_name}: ya tenés tu cancha."
    return Message(
        recipient=profile.email,
        subject=SUBJECT,
        body="\n".join([greeting, "", *(f"{label}: {value}" for label, value in details)]),
        html=html_email(SUBJECT, [greeting], details=details, footer="Te esperamos en la sede."),
    )
