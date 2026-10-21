from datetime import UTC, datetime, timedelta, timezone

import pytest

from app.aplicacion.errores import DatosInvalidos
from app.dominio.reservas import Marcador
from app.interfaz.marcador import codificar, leer

INICIO = datetime(2026, 11, 12, 21, 0, tzinfo=UTC)


def test_un_marcador_codificado_se_lee_igual() -> None:
    assert leer(codificar(Marcador(INICIO, 4321))) == Marcador(INICIO, 4321)


def test_el_marcador_conserva_los_microsegundos_y_la_zona() -> None:
    inicio = datetime(2026, 11, 12, 18, 0, 0, 250_000, tzinfo=timezone(timedelta(hours=-3)))

    leido = leer(codificar(Marcador(inicio, 7)))

    assert leido.inicio == inicio
    assert leido.inicio.microsecond == 250_000


def test_el_marcador_es_texto_seguro_para_una_url() -> None:
    texto = codificar(Marcador(INICIO, 999_999_999))

    assert texto.isascii()
    assert not set(texto) & set("+/= ")


def _rechazado(valor: str) -> dict[str, str]:
    with pytest.raises(DatosInvalidos) as e:
        leer(valor)
    return e.value.errores


@pytest.mark.parametrize(
    "valor",
    [
        "",
        "no-es",
        "AAAA",
        # {"x":1}
        "eyJ4IjoxfQ",
        # 2026-11-12T00:00:00|abc (el id no es un número)
        "MjAyNi0xMS0xMlQwMDowMDowMHxhYmM",
        # 2026-11-12T00:00:00|5 (el inicio no dice la zona)
        "MjAyNi0xMS0xMlQwMDowMDowMHw1",
        # 2026-11-12T00:00:00+00:00|0 (no hay reserva 0)
        "MjAyNi0xMS0xMlQwMDowMDowMCswMDowMHww",
        # 2026-11-12T00:00:00+00:00|9223372036854775808 (no entra en un bigint)
        "MjAyNi0xMS0xMlQwMDowMDowMCswMDowMHw5MjIzMzcyMDM2ODU0Nzc1ODA4",
        # 2026-11-12T00:00:00+00:00|5|6
        "MjAyNi0xMS0xMlQwMDowMDowMCswMDowMHw1fDY",
        "x" * 500,
    ],
)
def test_un_marcador_que_no_se_entiende_es_un_dato_invalido(valor: str) -> None:
    assert _rechazado(valor) == {"despues": "El marcador de página no es válido"}


def test_un_marcador_con_relleno_o_caracteres_de_mas_no_se_acepta() -> None:
    valido = codificar(Marcador(INICIO, 5))

    assert _rechazado(valido + "=") == {"despues": "El marcador de página no es válido"}
    assert _rechazado(" " + valido) == {"despues": "El marcador de página no es válido"}
