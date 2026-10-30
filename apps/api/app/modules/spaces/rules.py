# kit-shape: the space kinds and the functions that validate and name them are a single concept
import re
import unicodedata
from dataclasses import dataclass
from uuid import UUID

_VENUE_PREFIX = re.compile(r"^sede\b\s*", re.IGNORECASE)
_STREET_PREFIX = re.compile(r"^(avenida|avda\.?|av\.?|calle)(\s+|(?<=\.))", re.IGNORECASE)
_TRANSLITERATION = str.maketrans(
    {"ß": "ss", "ø": "o", "Ø": "O", "ł": "l", "Ł": "L", "æ": "ae", "Æ": "AE"}
)


def _ascii(text: str) -> str:
    text = unicodedata.normalize("NFKC", text).translate(_TRANSLITERATION)
    return unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()


def _words(text: str) -> list[str]:
    return re.findall(r"[A-Za-z0-9]+", _ascii(text))


def _part(text: str) -> str:
    return "".join(w[0].upper() + w[1:] for w in _words(text))


def _positive_int(value: int, label: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
        raise ValueError(f"{label} tiene que ser un entero positivo")
    return value


def venue_part(venue: str) -> str:
    """What the venue adds to the name of its spaces: "Sede Ramos Mejía" gives "RamosMejia"."""
    return _part(_VENUE_PREFIX.sub("", _ascii(venue).strip()))


def street_part(street: str) -> str:
    """What the street adds to the name of its spaces: "Av. Rivadavia" gives "Rivadavia"."""
    return _part(_STREET_PREFIX.sub("", _ascii(street).strip()))


def composite_name(  # noqa: PLR0913, PLR0917 -- public signature fixed by its callers
    venue: str, street: str, street_number: int, sport: str, kind: str, number: int
) -> str:
    """Space name required by the assignment: venue, address, kind and number.

    `composite_name("Sede Morón", "Av. Rivadavia", 19850, "Fútbol", "F5", 1)` gives
    `Moron_Rivadavia_19850_Futbol_F5_1`, the format the prototype uses.
    """
    parts = [
        venue_part(venue),
        street_part(street),
        str(_positive_int(street_number, "la altura")),
        _part(sport),
        "".join(_words(kind)).upper(),
        str(_positive_int(number, "el número")),
    ]
    if not all(parts):
        raise ValueError("sede, calle, deporte y tipo no pueden quedar vacíos")
    return "_".join(parts)


@dataclass(frozen=True)
class SuggestedName:
    name: str
    number: int


@dataclass(frozen=True)
class SpaceVenue:
    """The part of the venue that goes into the composite name of its spaces."""

    name: str
    street: str
    street_number: int


@dataclass(frozen=True)
class Kind:
    key: str
    name: str


@dataclass(frozen=True)
class Sport:
    key: str
    name: str
    kinds: tuple[Kind, ...]


CATALOG: tuple[Sport, ...] = (
    Sport(
        "Futbol",
        "Fútbol",
        (
            Kind("F5", "Fútbol 5"),
            Kind("F7", "Fútbol 7"),
            Kind("F8", "Fútbol 8"),
            Kind("F11", "Fútbol 11"),
        ),
    ),
    Sport("Tenis", "Tenis", (Kind("PDL", "Polvo de ladrillo"), Kind("CEM", "Cemento"))),
    Sport("Padel", "Pádel", (Kind("PAD", "Pádel"),)),
    Sport("Voley", "Vóley", (Kind("IND", "Indoor"), Kind("PLA", "Vóley playa"))),
    Sport("Basquet", "Básquet", (Kind("B5", "Básquet 5"), Kind("3X3", "Básquet 3x3"))),
    Sport("Hockey", "Hockey", (Kind("H7", "Hockey 7"),)),
    Sport("Golf", "Golf", (Kind("DR", "Driving range"), Kind("9H", "9 hoyos"))),
)

MAX_PRICE = 9_999_999

REQUIRED = "Este campo es obligatorio"


def catalog_kind(sport: str, kind: str) -> Kind | None:
    for s in CATALOG:
        if s.key == sport:
            return next((k for k in s.kinds if k.key == kind), None)
    return None


@dataclass(frozen=True)
class SpaceData:
    """What comes from the form, unvalidated."""

    venue_id: UUID | None
    sport: str
    kind: str
    covered: bool | None
    lit: bool | None
    price_per_hour: int | None


@dataclass(frozen=True)
class NewSpace:
    venue_id: UUID
    sport: str
    kind: str
    covered: bool
    lit: bool
    price_per_hour: int


@dataclass(frozen=True)
class Space:
    id: UUID
    name: str
    venue_id: UUID
    venue: str
    sport: str
    kind: str
    number: int
    covered: bool
    lit: bool
    price_per_hour: int


@dataclass(frozen=True)
class SpaceChange:
    """What is corrected on a space (CU-22); `None` is what stays as it is. The composite
    name does not change."""

    covered: bool | None
    lit: bool | None
    price_per_hour: int | None


def _price_error(price: int | None) -> str | None:
    if price is None:
        return REQUIRED
    if not 0 < price <= MAX_PRICE:
        return "Ingresá un precio entre $ 1 y $ 9.999.999"
    return None


def validate_change(
    covered: bool | None,  # noqa: FBT001
    lit: bool | None,  # noqa: FBT001
    price_per_hour: int | None,
    *,
    given: frozenset[str],
) -> tuple[SpaceChange | None, dict[str, str]]:
    """The change ready to save, or the error of each field. Only what is in [given] changes:
    what did not come does not overwrite what someone else saved in the meantime.

    The error keys and the names in [given] are the JSON field names of the API."""
    errors: dict[str, str] = {}
    if not given & {"covered", "lit", "price_per_hour"}:
        errors["change"] = "No hay nada que cambiar"
    if "covered" in given and covered is None:
        errors["covered"] = REQUIRED
    if "lit" in given and lit is None:
        errors["lit"] = REQUIRED
    if "price_per_hour" in given and (error := _price_error(price_per_hour)):
        errors["price_per_hour"] = error
    if errors:
        return None, errors
    return SpaceChange(covered, lit, price_per_hour), {}


def validate_space(data: SpaceData) -> tuple[NewSpace | None, dict[str, str]]:
    """The space ready to save, or the error of each field (keys are JSON field names)."""
    errors: dict[str, str] = {}
    if data.venue_id is None:
        errors["venue_id"] = REQUIRED
    sports = {s.key for s in CATALOG}
    if not data.sport:
        errors["sport"] = REQUIRED
    elif data.sport not in sports:
        errors["sport"] = "Elegí un deporte de la lista"
    if not data.kind:
        errors["kind"] = REQUIRED
    elif data.sport in sports and catalog_kind(data.sport, data.kind) is None:
        errors["kind"] = "Elegí un tipo de la lista"
    if data.covered is None:
        errors["covered"] = REQUIRED
    if data.lit is None:
        errors["lit"] = REQUIRED
    price = data.price_per_hour
    if (error := _price_error(price)) is not None:
        errors["price_per_hour"] = error
    if errors or data.venue_id is None or data.covered is None or data.lit is None or price is None:
        return None, errors
    return (
        NewSpace(
            venue_id=data.venue_id,
            sport=data.sport,
            kind=data.kind,
            covered=data.covered,
            lit=data.lit,
            price_per_hour=price,
        ),
        {},
    )
