from datetime import date, datetime, time, timedelta
from zoneinfo import ZoneInfo

import pytest

from app.modules.horarios.casos_de_uso import horarios_disponibles
from app.modules.horarios.reglas import (
    Agenda,
    Grilla,
    error_de_duracion,
    grilla,
    validar_consulta,
    validar_rango,
    validar_reserva,
)
from app.shared.errores import DatosInvalidos, NoDisponible

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
        self,
        espacio_id: int,
        desde: datetime,
        hasta: datetime,
        salvo: tuple[int, int] | None = None,
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


@pytest.mark.parametrize(
    ("desde", "hasta", "errores"),
    [
        (10, 12, {}),
        (22, 0, {"hasta": "La sede cierra a las 23:00"}),
        (18, 18, {"hasta": "La duración mínima es de una hora"}),
        (20, 18, {"hasta": "La duración mínima es de una hora"}),
        (10, 15, {"hasta": "La duración máxima es de 4 horas"}),
        (7, 9, {"desde": "La sede abre a las 08:00"}),
    ],
)
def test_un_rango_se_valida_contra_el_horario_de_la_sede(
    desde: int, hasta: int, errores: dict[str, str]
) -> None:
    agenda = Agenda(time(8), time(23), TODOS)
    assert validar_rango(
        agenda, JUEVES, time(desde), time(hasta), _a(JUEVES - timedelta(1), 9)
    ) == (errores)


def test_un_rango_que_ya_empezo_o_de_otro_dia_no_se_consulta() -> None:
    agenda = Agenda(time(8), time(23), (1, 2, 3, 4))
    ahora = datetime.combine(JUEVES, time(18, 20), tzinfo=ZONA)
    assert validar_rango(agenda, JUEVES, time(18), time(19), ahora) == {
        "desde": "El horario tiene que ser futuro"
    }
    assert validar_rango(agenda, JUEVES - timedelta(1), time(18), time(19), ahora) == {
        "fecha": "La fecha tiene que ser futura"
    }
    assert validar_rango(agenda, JUEVES + timedelta(1), time(18), time(19), ahora) == {
        "fecha": "La sede no abre ese día"
    }
    assert validar_rango(agenda, JUEVES + timedelta(7), time(18), time(19), ahora) == {
        "fecha": "Elegí un día de los próximos 7"
    }
    assert validar_rango(agenda, JUEVES, time(19, 30), time(21), ahora) == {
        "desde": "Elegí una hora en punto"
    }


@pytest.mark.parametrize(
    ("desde", "horas", "campo", "mensaje"),
    [
        (10, 0, "hasta", "La duración mínima es de una hora"),
        (10, 5, "hasta", "La duración máxima es de 4 horas"),
        (22, 3, "hasta", "La sede cierra a las 23:00"),
        (21, 2, None, None),
    ],
)
def test_una_reserva_se_valida_por_su_inicio_y_su_duracion(
    desde: int, horas: int, campo: str | None, mensaje: str | None
) -> None:
    errores = validar_reserva(
        Agenda(time(8), time(23), TODOS), JUEVES, time(desde), horas, _a(JUEVES - timedelta(1), 9)
    )
    assert errores == ({} if campo is None else {campo: mensaje})


@pytest.mark.parametrize(
    ("horas", "mensaje"),
    [
        (-1, "La duración mínima es de una hora"),
        (0, "La duración mínima es de una hora"),
        (1, None),
        (4, None),
        (5, "La duración máxima es de 4 horas"),
        (10**12, "La duración máxima es de 4 horas"),
    ],
)
def test_una_duracion_es_reservable_de_una_a_cuatro_horas(horas: int, mensaje: str | None) -> None:
    assert error_de_duracion(horas) == mensaje
