# kit-shape: the venue types and the functions that validate it are a single concept
import re
from dataclasses import dataclass
from datetime import time
from uuid import UUID

from app.modules.espacios import parte_de_calle, parte_de_sede

NAME_MAX_LENGTH = 60
ADDRESS_MAX_LENGTH = 80
MIDNIGHT = time(0, 0)
WEEKDAYS = frozenset(range(1, 8))

_STREET_AND_NUMBER = re.compile(r"^(?P<street>.*\S)\s+(?P<number>\d{1,6})$", re.ASCII)


@dataclass(frozen=True)
class VenueData:
    """What arrives from the form, unvalidated."""

    name: str
    address: str
    opens_at: time | None
    closes_at: time | None
    open_days: tuple[int, ...]


@dataclass(frozen=True)
class NewVenue:
    name: str
    street: str
    street_number: int
    opens_at: time
    closes_at: time
    open_days: tuple[int, ...]


@dataclass(frozen=True)
class Venue:
    id: UUID
    name: str
    street: str
    street_number: int
    opens_at: time
    closes_at: time
    open_days: tuple[int, ...]
    space_count: int
    # The keys of the sports of its active spaces, without repeats.
    sports: tuple[str, ...] = ()

    @property
    def address(self) -> str:
        return f"{self.street} {self.street_number}"


def _on_the_hour(hour: time) -> bool:
    return hour.minute == 0 and hour.second == 0 and hour.microsecond == 0


def _hours_errors(opens_at: time | None, closes_at: time | None) -> dict[str, str]:
    errors: dict[str, str] = {}
    if opens_at is None:
        errors["apertura"] = "El horario de apertura es obligatorio"
    elif not _on_the_hour(opens_at):
        errors["apertura"] = "Elegí una hora en punto"
    if closes_at is None:
        errors["cierre"] = "El horario de cierre es obligatorio"
    elif not _on_the_hour(closes_at):
        errors["cierre"] = "Elegí una hora en punto"
    elif opens_at is not None and closes_at != MIDNIGHT and closes_at <= opens_at:
        # Closing at 00:00 means closing at midnight of the same day.
        errors["cierre"] = "El cierre tiene que ser después de la apertura"
    return errors


def validate_venue(data: VenueData) -> tuple[NewVenue | None, dict[str, str]]:
    """The venue ready to save, or the errors of each field."""
    errors: dict[str, str] = {}
    name = " ".join(data.name.split())
    if not name:
        errors["nombre"] = "El nombre es obligatorio"
    elif len(name) > NAME_MAX_LENGTH:
        errors["nombre"] = f"Usá hasta {NAME_MAX_LENGTH} caracteres"
    elif not parte_de_sede(name):
        # Without it the venue's spaces would have no composite name (RF 5).
        errors["nombre"] = "Escribí el nombre de la sede"

    address = " ".join(data.address.split())
    parts = _STREET_AND_NUMBER.match(address)
    if not address:
        errors["direccion"] = "La dirección es obligatoria"
    elif len(address) > ADDRESS_MAX_LENGTH:
        errors["direccion"] = f"Usá hasta {ADDRESS_MAX_LENGTH} caracteres"
    elif parts is None or int(parts["number"]) == 0 or not parte_de_calle(parts["street"]):
        errors["direccion"] = "Escribí la calle y la altura"

    errors |= _hours_errors(data.opens_at, data.closes_at)

    open_days = tuple(sorted(set(data.open_days)))
    if not open_days or not set(open_days) <= WEEKDAYS:
        errors["dias"] = "Elegí los días que abre"

    if errors or parts is None or data.opens_at is None or data.closes_at is None:
        return None, errors
    return (
        NewVenue(
            name=name,
            street=parts["street"],
            street_number=int(parts["number"]),
            opens_at=data.opens_at,
            closes_at=data.closes_at,
            open_days=open_days,
        ),
        {},
    )
