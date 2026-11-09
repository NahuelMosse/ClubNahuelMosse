from app.modules.bookings.rules import Booking
from app.modules.notifications import short_kind
from app.modules.session import Profile
from app.shared.club_timezone import CLUB_TIMEZONE
from app.shared.email_template import html_email
from app.shared.message import Message

DAYS = ("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")
MONTHS = (
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
)
SUBJECT = "Your booking is confirmed"


def _money(amount: int) -> str:
    """«$ 12.000», with a dot as thousands separator as it reads in es-AR."""
    return f"$ {amount:,}".replace(",", ".")


def booking_email(profile: Profile, booking: Booking) -> Message:
    """The confirmation of a new booking, with the club's day and time."""
    starts = booking.starts_at.astimezone(CLUB_TIMEZONE)
    ends = booking.ends_at.astimezone(CLUB_TIMEZONE)
    details = [
        ("Court", short_kind(booking.sport, booking.kind)),
        ("Venue", booking.venue),
        ("Day", f"{DAYS[starts.weekday()]} {MONTHS[starts.month - 1]} {starts.day}"),
        ("Time", f"{starts:%H:%M} to {ends:%H:%M}"),
        ("Total", _money(booking.total)),
    ]
    greeting = f"Hi {profile.first_name}: your court is booked."
    return Message(
        recipient=profile.email,
        subject=SUBJECT,
        body="\n".join([greeting, "", *(f"{label}: {value}" for label, value in details)]),
        html=html_email(
            SUBJECT, [greeting], details=details, footer="We are waiting for you at the venue."
        ),
    )
