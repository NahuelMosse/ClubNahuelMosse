import pytest

from app.modules.espacios.reglas import nombre_compuesto


@pytest.mark.parametrize(
    ("sede", "calle", "altura", "deporte", "tipo", "numero", "esperado"),
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
def test_nombre_compuesto(
    sede: str, calle: str, altura: int, deporte: str, tipo: str, numero: int, esperado: str
) -> None:
    assert nombre_compuesto(sede, calle, altura, deporte, tipo, numero) == esperado


@pytest.mark.parametrize(("altura", "numero"), [(0, 1), (19850, 0), (-1, 1), (True, 1), (1, True)])
def test_altura_y_numero_positivos(altura: int, numero: int) -> None:
    with pytest.raises(ValueError):
        nombre_compuesto("Sede Morón", "Av. Rivadavia", altura, "Fútbol", "F5", numero)


@pytest.mark.parametrize("vacio", ["", "   ", "Sede ", "Sede", "¡!"])
def test_partes_vacias(vacio: str) -> None:
    with pytest.raises(ValueError):
        nombre_compuesto(vacio, "Av. Rivadavia", 19850, "Fútbol", "F5", 1)


def test_tipo_sin_letras_se_rechaza() -> None:
    with pytest.raises(ValueError):
        nombre_compuesto("Sede Morón", "Av. Rivadavia", 19850, "Fútbol", "¡!", 1)
