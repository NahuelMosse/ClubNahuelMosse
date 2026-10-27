class InvalidData(Exception):
    def __init__(self, errors: dict[str, str]) -> None:
        super().__init__("datos inválidos")
        self.errors = errors


class Duplicate(Exception):
    """An active account already exists with one of these fields."""

    def __init__(self, fields: list[str]) -> None:
        super().__init__(f"duplicado: {', '.join(fields)}")
        self.fields = fields


class NotAuthenticated(Exception):
    """The request carries no valid token of an account with an active profile."""


class RateLimited(Exception):
    """The identity provider is throttling after too many attempts in a row."""


class AccountExists(Exception):
    """An active account already has that email and promoting it was not requested."""


class Forbidden(Exception):
    """Whoever asks for the operation cannot perform it."""


class Unavailable(Exception):
    """What was requested no longer exists or was deactivated."""


class NumberTaken(Exception):
    """Another creation already took the space number that was being shown."""

    def __init__(self, next_number: int, name: str) -> None:
        super().__init__(f"número ocupado; el siguiente es {next_number} ({name})")
        self.next_number = next_number
        self.name = name


class SlotTaken(Exception):
    """Another active booking of the same space overlaps the requested time."""


class NotFound(Exception):
    """Nothing with that number belongs to whoever asks for it."""


class ConcurrentChange(Exception):
    """What was meant to change is no longer as it was seen (another person or time changed
    it)."""


class BookingsOutsideHours(Exception):
    """The new opening hours leave future bookings outside: it must be confirmed."""

    def __init__(self, count: int) -> None:
        super().__init__(f"{count} reservas futuras quedan fuera del horario nuevo")
        self.count = count


class OpeningHoursChanged(Exception):
    """The branch opening hours changed between validating a booking and saving it."""


class HasFutureBookings(Exception):
    """The branch or the space has active bookings that have not ended yet."""
