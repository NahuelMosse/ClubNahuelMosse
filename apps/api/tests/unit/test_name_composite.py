import pytest

from app.modules.spaces.rules import composite_name


@pytest.mark.parametrize(
    ("venue", "street", "number", "sport", "kind", "sequence", "expected"),
    [
        (
            "Sede Castelar",
            "Av. Rivadavia",
            23500,
            "Tenis",
            "CEM",
            1,
            "Castelar_Rivadavia_23500_Tenis_CEM_1",
        ),
        (
            "Sede Ramos Mejía",
            "Calle Belgrano",
            1240,
            "Vóley",
            "ind",
            3,
            "RamosMejia_Belgrano_1240_Voley_IND_3",
        ),
        ("Haedo", "Avenida Vergara", 1850, "Fútbol", "F11", 12, "Haedo_Vergara_1850_Futbol_F11_12"),
        (
            "  Sede Morón  ",
            " Av Rivadavia ",
            19850,
            "fútbol",
            "f7",
            2,
            "Moron_Rivadavia_19850_Futbol_F7_2",
        ),
        (
            "Sede San Justo",
            "Juan Manuel de Rosas",
            700,
            "Golf",
            "LARGO",
            1,
            "SanJusto_JuanManuelDeRosas_700_Golf_LARGO_1",
        ),
    ],
)
def test_composite_name(
    venue: str, street: str, number: int, sport: str, kind: str, sequence: int, expected: str
) -> None:
    assert composite_name(venue, street, number, sport, kind, sequence) == expected


@pytest.mark.parametrize(
    ("number", "sequence"), [(0, 1), (19850, 0), (-1, 1), (True, 1), (1, True)]
)
def test_number_and_sequence_are_positive(number: int, sequence: int) -> None:
    with pytest.raises(ValueError):
        composite_name("Sede Morón", "Av. Rivadavia", number, "Fútbol", "F5", sequence)


@pytest.mark.parametrize("empty", ["", "   ", "Sede ", "Sede", "¡!"])
def test_empty_parts(empty: str) -> None:
    with pytest.raises(ValueError):
        composite_name(empty, "Av. Rivadavia", 19850, "Fútbol", "F5", 1)


def test_kind_without_letters_is_rejected() -> None:
    with pytest.raises(ValueError):
        composite_name("Sede Morón", "Av. Rivadavia", 19850, "Football", "¡!", 1)
