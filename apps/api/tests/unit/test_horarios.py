from datetime import date, datetime, time, timedelta
from zoneinfo import ZoneInfo

import pytest

from app.aplicacion.errores import DatosInvalidos, NoDisponible
from app.aplicacion.horarios import horarios_disponibles
from app.dominio.horarios import Agenda, Grilla, grilla, validar_consulta

ZONA = ZoneInfo("America/Argentina/Buenos_Aires")
TODOS = (1, 2, 3, 4, 5, 6, 7)
JUEVES = date(2026, 11, 12)


def _a(dia: date, hora: int) -> datetime:
    return datetime.combine(dia, time(hora), tzinfo=ZONA)


def _inicios(g: Grilla) -> list[str]:
    return [f"{f.inicio:%H}" for f in g.franjas]


def test_de_la_apertura_al_cierre_en_horas_completas() -> None:
    g = grilla(Agenda(time(8), time(23), TODOS), JUEVES, 1, _a(JUEVES - timedelta(1), 9), [])
    assert _inicios(g)[0] == "08" and _inicios(g)[-1] == "22"
    assert len(g.franjas) == 15 and g.no_disponibles == 0


def test_con_mas_horas_la_ultima_termina_al_cierre() -> None:
    g = grilla(Agenda(time(8), time(23), TODOS), JUEVES, 3, _a(JUEVES - timedelta(1), 9), [])
    assert _inicios(g)[-1] == "20"
    assert g.franjas[-1].fin == _a(JUEVES, 23)


def test_un_cierre_a_medianoche_deja_la_franja_de_las_23() -> None:
    g = grilla(Agenda(time(20), time(0), TODOS), JUEVES, 1, _a(JUEVES - timedelta(1), 9), [])
    assert _inicios(g) == ["20", "21", "22", "23"]


def test_hoy_no_ofrece_la_hora_que_ya_empezo() -> None:
    ahora = datetime.combine(JUEVES, time(14, 0), tzinfo=ZONA)
    g = grilla(Agenda(time(8), time(23), TODOS), JUEVES, 1, ahora, [])
    assert _inicios(g)[0] == "15"


def test_una_reserva_deja_no_disponibles_las_franjas_que_pisa() -> None:
    ocupada = [(_a(JUEVES, 11), _a(JUEVES, 12))]
    g = grilla(Agenda(time(8), time(23), TODOS), JUEVES, 2, _a(JUEVES - timedelta(1), 9), ocupada)
    libres = {f"{f.inicio:%H}": f.disponible for f in g.franjas}
    assert (libres["09"], libres["10"], libres["11"], libres["12"]) == (True, False, False, True)
    assert g.no_disponibles == 2


def test_la_sede_no_abre_ese_dia() -> None:
    g = grilla(Agenda(time(8), time(23), (1, 2, 3)), JUEVES, 1, _a(JUEVES - timedelta(1), 9), [])
    assert not g.abre and g.franjas == ()


@pytest.mark.parametrize(
    ("dias", "horas", "campos"),
    [(0, 1, set()), (6, 4, set()), (7, 1, {"fecha"}), (-1, 1, {"fecha"}), (0, 5, {"horas"})],
)
def test_se_consulta_de_hoy_a_seis_dias_y_de_1_a_4_horas(
    dias: int, horas: int, campos: set[str]
) -> None:
    assert set(validar_consulta(JUEVES + timedelta(dias), JUEVES, horas)) == campos


class _Horarios:
    def __init__(self, agenda: Agenda | None) -> None:
        self._agenda = agenda
        self.pedido: tuple[datetime, datetime] | None = None

    def agenda(self, espacio_id: int) -> Agenda | None:
        return self._agenda

    def ocupadas(
        self, espacio_id: int, desde: datetime, hasta: datetime
    ) -> list[tuple[datetime, datetime]]:
        self.pedido = (desde, hasta)
        return []


def test_sin_fecha_consulta_hoy() -> None:
    horarios = _Horarios(Agenda(time(8), time(23), TODOS))
    g = horarios_disponibles(horarios, 1, None, 1, _a(JUEVES, 9))
    assert g.fecha == JUEVES
    assert horarios.pedido == (_a(JUEVES, 0), _a(JUEVES, 0) + timedelta(days=2))


def test_un_espacio_que_no_esta_activo_no_se_consulta() -> None:
    with pytest.raises(NoDisponible):
        horarios_disponibles(_Horarios(None), 1, JUEVES, 1, _a(JUEVES, 9))


def test_una_fecha_fuera_de_la_semana_se_rechaza() -> None:
    with pytest.raises(DatosInvalidos):
        horarios_disponibles(
            _Horarios(Agenda(time(8), time(23), TODOS)), 1, JUEVES + timedelta(8), 1,
            _a(JUEVES, 9),
        )  # fmt: skip
