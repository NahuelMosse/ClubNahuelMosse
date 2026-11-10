"""Casos de uso de reservas con un repositorio en memoria: sin base ni emulador."""

from dataclasses import replace
from datetime import date, datetime, time, timedelta, timezone
from uuid import UUID

import pytest

from app.modules.availability.rules import OpeningHours
from app.modules.bookings.rules import (
    Booking,
    BookingHistory,
    BookingHistoryEntry,
    Counters,
    HistoryFilters,
)
from app.modules.bookings.use_cases import (
    MAX_REASON_LENGTH,
    admin_detail,
    book,
    cancel_booking,
    global_history,
    modify_booking,
    my_bookings,
    void_booking,
)
from app.modules.session.profile import Profile as Perfil
from app.shared.errors import (
    ConcurrentChange,
    Forbidden,
    InvalidData,
    NotFound,
    OpeningHoursChanged,
    SlotTaken,
    Unavailable,
)

ZONA = timezone(timedelta(hours=-3))
AHORA = datetime(2026, 3, 2, 10, 0, tzinfo=ZONA)  # lunes
MANANA = date(2026, 3, 3)
AGENDA = OpeningHours(opens_at=time(8, 0), closes_at=time(23, 0), open_days=(1, 2, 3, 4, 5, 6, 7))


def _id(numero: int) -> UUID:
    return UUID(int=numero)


def _perfil(id: int = 1, rol: str = "user") -> Perfil:
    return Perfil(
        id=_id(id), uid=f"u{id}", first_name="Ana", last_name="Paz", email="a@b.c", role=rol,
        dni="1", birth_date=date(2000, 1, 1),
    )  # fmt: skip


def _reserva(**cambios: object) -> Booking:
    base = Booking(
        id=_id(5), space_id=_id(2), venue_id=_id(1), space="Cancha 1", sport="futbol",
        kind="5",
        venue="Centro", address="x", starts_at=datetime(2026, 3, 3, 18, 0, tzinfo=ZONA),
        ends_at=datetime(2026, 3, 3, 20, 0, tzinfo=ZONA), price_per_hour=100, total=200,
        status="active", reason=None,
    )  # fmt: skip
    return replace(base, **cambios)


def _historial(**cambios: object) -> BookingHistoryEntry:
    r = _reserva()
    base = BookingHistoryEntry(
        id=r.id, space_id=r.space_id, venue_id=r.venue_id, space=r.space,
        sport=r.sport, kind=r.kind, venue=r.venue, address=r.address, starts_at=r.starts_at,
        ends_at=r.ends_at, price_per_hour=100, total=200, status="active", reason=None,
        user_id=_id(1), user="Ana Paz", created_at=AHORA, canceled_at=None,
        canceled_by_name=None, space_deactivated=False,
    )  # fmt: skip
    return replace(base, **cambios)


class Memoria:
    def __init__(self) -> None:
        self.agenda_actual: OpeningHours | None = AGENDA
        self.repetida_hecha: Booking | None = None
        self.propia_de: Booking | None = None
        self.tipo: tuple[UUID, str, str] | None = (_id(1), "futbol", "5")
        self.agendas_cambiadas = 0
        self.llamadas: list[tuple] = []
        self.detalle: BookingHistoryEntry | None = None

    def of_user(self, usuario_id, cuando):
        self.llamadas.append(("de_usuario", usuario_id, cuando))
        return [_reserva()]

    def opening_hours(self, espacio_id):
        return self.agenda_actual

    def repeated(self, usuario_id, espacio_id, inicio, fin):
        self.llamadas.append(("repetida", usuario_id, espacio_id, inicio, fin))
        return self.repetida_hecha

    def own(self, usuario_id, reserva_id):
        self.llamadas.append(("propia", usuario_id, reserva_id))
        return self.propia_de

    def space_kind(self, espacio_id):
        return self.tipo

    def move(self, usuario_id, reserva_id, antes, espacio_id, inicio, fin, agenda):
        self.llamadas.append(("mover", usuario_id, reserva_id, antes, espacio_id, inicio, fin))
        if self.agendas_cambiadas:
            self.agendas_cambiadas -= 1
            raise OpeningHoursChanged()
        return _reserva(space_id=espacio_id, starts_at=inicio, ends_at=fin)

    def cancel(self, usuario_id, reserva_id):
        self.llamadas.append(("cancelar", usuario_id, reserva_id))
        return _reserva(status="canceled")

    def insert(self, usuario_id, espacio_id, inicio, fin, agenda):
        self.llamadas.append(("insertar", usuario_id, espacio_id, inicio, fin, agenda))
        if self.agendas_cambiadas:
            self.agendas_cambiadas -= 1
            raise OpeningHoursChanged()
        return _reserva(space_id=espacio_id, starts_at=inicio, ends_at=fin)

    def void(self, admin_id, reserva_id, motivo, espacio_id, inicio):
        self.llamadas.append(("anular", admin_id, reserva_id, motivo, espacio_id, inicio))
        return _historial(status="voided", reason=motivo)

    def history(self, filtros):
        self.llamadas.append(("history", filtros))
        return BookingHistory(
            bookings=[], total=0, page=1, per_page=20,
            counters=Counters(all=0, active=0, completed=0, voided=0),
        )  # fmt: skip

    def any_one(self, reserva_id):
        self.llamadas.append(("una_de_cualquiera", reserva_id))
        return self.detalle


def _errores(excepcion: pytest.ExceptionInfo[InvalidData]) -> dict[str, str]:
    return excepcion.value.errors


# mis_reservas


def test_mis_reservas_pide_solo_las_de_quien_consulta() -> None:
    repo = Memoria()

    resultado = my_bookings(repo, _perfil(id=7), "upcoming")

    assert resultado == [_reserva()]
    assert repo.llamadas == [("de_usuario", _id(7), "upcoming")]
    my_bookings(repo, _perfil(id=7), "history")
    assert repo.llamadas[-1] == ("de_usuario", _id(7), "history")


# reservar


def test_reservar_guarda_con_el_horario_pedido_y_la_agenda_de_la_sede() -> None:
    repo = Memoria()

    reserva = book(repo, _perfil(), _id(2), MANANA, time(18, 0), 2, AHORA)

    inicio = datetime(2026, 3, 3, 18, 0, tzinfo=ZONA)
    assert repo.llamadas[-1] == (
        "insertar",
        _id(1),
        _id(2),
        inicio,
        inicio + timedelta(hours=2),
        AGENDA,
    )
    assert (reserva.starts_at, reserva.ends_at) == (inicio, inicio + timedelta(hours=2))


def test_reservar_hasta_la_medianoche_es_valido() -> None:
    repo = Memoria()

    reserva = book(repo, _perfil(), _id(2), MANANA, time(22, 0), 1, AHORA)

    assert reserva.ends_at == datetime(2026, 3, 3, 23, 0, tzinfo=ZONA)


def test_reservar_un_administrador_es_prohibido() -> None:
    with pytest.raises(Forbidden):
        book(Memoria(), _perfil(rol="admin"), _id(2), MANANA, time(18, 0), 1, AHORA)


def test_reservar_sin_hora_pide_una_hora_en_punto() -> None:
    with pytest.raises(InvalidData) as e:
        book(Memoria(), _perfil(), _id(2), MANANA, None, 1, AHORA)

    assert set(_errores(e)) == {"start_hour"}


@pytest.mark.parametrize("horas", [0, 5, -1])
def test_reservar_con_una_duracion_fuera_de_una_a_cuatro_horas_falla(horas: int) -> None:
    repo = Memoria()

    with pytest.raises(InvalidData) as e:
        book(repo, _perfil(), _id(2), MANANA, time(18, 0), horas, AHORA)

    assert set(_errores(e)) == {"hours", "until"}
    assert repo.llamadas == []


@pytest.mark.parametrize("horas", [1, 4])
def test_reservar_acepta_los_bordes_de_la_duracion(horas: int) -> None:
    reserva = book(Memoria(), _perfil(), _id(2), MANANA, time(10, 0), horas, AHORA)

    assert reserva.ends_at - reserva.starts_at == timedelta(hours=horas)


def test_reservar_un_dia_fuera_de_la_ventana_falla_aun_en_date_max() -> None:
    with pytest.raises(InvalidData) as e:
        book(Memoria(), _perfil(), _id(2), date.max, time(18, 0), 4, AHORA)
    assert set(_errores(e)) == {"date"}

    with pytest.raises(InvalidData):
        book(Memoria(), _perfil(), _id(2), AHORA.date() + timedelta(days=7), time(18, 0), 1, AHORA)


def test_reservar_el_ultimo_dia_de_la_ventana_se_acepta() -> None:
    dia = AHORA.date() + timedelta(days=6)

    assert book(Memoria(), _perfil(), _id(2), dia, time(18, 0), 1, AHORA).id == _id(5)


def test_reservar_devuelve_el_pedido_repetido_sin_validar_el_horario() -> None:
    repo = Memoria()
    repo.repetida_hecha = _reserva(id=_id(99))
    repo.agenda_actual = None
    ya_empezado = AHORA - timedelta(days=1)

    reserva = book(repo, _perfil(), _id(2), ya_empezado.date(), time(9, 0), 1, AHORA)

    assert reserva.id == _id(99)
    assert [c[0] for c in repo.llamadas] == ["repetida"]


def test_reservar_un_espacio_sin_agenda_no_esta_disponible() -> None:
    repo = Memoria()
    repo.agenda_actual = None

    with pytest.raises(Unavailable):
        book(repo, _perfil(), _id(2), MANANA, time(18, 0), 1, AHORA)


def test_reservar_fuera_del_horario_de_la_sede_falla_sin_guardar() -> None:
    repo = Memoria()

    with pytest.raises(InvalidData):
        book(repo, _perfil(), _id(2), MANANA, time(7, 0), 1, AHORA)
    with pytest.raises(InvalidData):
        book(repo, _perfil(), _id(2), MANANA, time(22, 0), 2, AHORA)
    assert [c for c in repo.llamadas if c[0] == "insertar"] == []


def test_reservar_revalida_si_la_agenda_cambio_en_el_medio() -> None:
    repo = Memoria()
    repo.agendas_cambiadas = 2

    reserva = book(repo, _perfil(), _id(2), MANANA, time(18, 0), 1, AHORA)

    assert reserva.id == _id(5)
    assert len([c for c in repo.llamadas if c[0] == "insertar"]) == 3


def test_reservar_con_la_agenda_cambiando_siempre_termina_en_horario_ocupado() -> None:
    repo = Memoria()
    repo.agendas_cambiadas = 99

    with pytest.raises(SlotTaken):
        book(repo, _perfil(), _id(2), MANANA, time(18, 0), 1, AHORA)

    assert len([c for c in repo.llamadas if c[0] == "insertar"]) == 3


# cancel_booking


def test_cancelar_reserva_cancela_la_de_quien_pide() -> None:
    repo = Memoria()

    reserva = cancel_booking(repo, _perfil(id=3), _id(5))

    assert reserva.status == "canceled"
    assert repo.llamadas == [("cancelar", _id(3), _id(5))]


def test_cancelar_reserva_deja_pasar_los_errores_del_repositorio() -> None:
    class Ajena(Memoria):
        def cancel(self, usuario_id, reserva_id):
            raise NotFound("no")

    with pytest.raises(NotFound):
        cancel_booking(Ajena(), _perfil(), _id(5))


# modify_booking


def _con_reserva() -> Memoria:
    repo = Memoria()
    repo.propia_de = _reserva()
    return repo


def test_modificar_reserva_mueve_con_la_misma_duracion_y_el_estado_anterior() -> None:
    repo = _con_reserva()

    nueva = modify_booking(repo, _perfil(), _id(5), _id(3), MANANA, time(10, 0), AHORA)

    inicio = datetime(2026, 3, 3, 10, 0, tzinfo=ZONA)
    antes = (_id(2), datetime(2026, 3, 3, 18, 0, tzinfo=ZONA))
    assert repo.llamadas[-1] == (
        "mover",
        _id(1),
        _id(5),
        antes,
        _id(3),
        inicio,
        inicio + timedelta(hours=2),
    )
    assert (nueva.space_id, nueva.starts_at) == (_id(3), inicio)


def test_modificar_reserva_un_administrador_es_prohibido() -> None:
    with pytest.raises(Forbidden):
        modify_booking(
            _con_reserva(), _perfil(rol="admin"), _id(5), _id(2), MANANA, time(9, 0), AHORA
        )


def test_modificar_reserva_sin_hora_falla() -> None:
    with pytest.raises(InvalidData) as e:
        modify_booking(_con_reserva(), _perfil(), _id(5), _id(2), MANANA, None, AHORA)

    assert set(_errores(e)) == {"start_hour"}


def test_modificar_reserva_fuera_de_la_ventana_falla_antes_de_buscarla() -> None:
    repo = _con_reserva()

    with pytest.raises(InvalidData) as e:
        modify_booking(repo, _perfil(), _id(5), _id(2), date.max, time(9, 0), AHORA)

    assert set(_errores(e)) == {"date"}
    assert repo.llamadas == []


def test_modificar_reserva_ajena_no_se_encuentra() -> None:
    with pytest.raises(NotFound):
        modify_booking(Memoria(), _perfil(), _id(5), _id(2), MANANA, time(9, 0), AHORA)


def test_modificar_reserva_repetida_devuelve_la_actual_sin_mover() -> None:
    repo = _con_reserva()

    reserva = modify_booking(repo, _perfil(), _id(5), _id(2), MANANA, time(18, 0), AHORA)

    assert reserva == _reserva()
    assert [c[0] for c in repo.llamadas] == ["propia"]


def test_modificar_reserva_cancelada_con_el_mismo_horario_no_se_da_por_repetida() -> None:
    repo = Memoria()
    repo.propia_de = _reserva(status="canceled")

    modify_booking(repo, _perfil(), _id(5), _id(2), MANANA, time(18, 0), AHORA)

    assert repo.llamadas[-1][0] == "mover"


def test_modificar_reserva_mismo_espacio_otro_horario_o_otro_espacio_mismo_horario_mueve() -> None:
    repo = _con_reserva()

    modify_booking(repo, _perfil(), _id(5), _id(2), MANANA, time(19, 0), AHORA)
    assert repo.llamadas[-1][0] == "mover"
    modify_booking(repo, _perfil(), _id(5), _id(3), MANANA, time(18, 0), AHORA)
    assert repo.llamadas[-1][0] == "mover"


@pytest.mark.parametrize(
    "tipo", [None, (_id(2), "futbol", "5"), (_id(1), "tenis", "5"), (_id(1), "futbol", "7")]
)
def test_modificar_reserva_a_una_cancha_de_otro_tipo_o_sede_falla(tipo) -> None:
    repo = _con_reserva()
    repo.tipo = tipo

    with pytest.raises(InvalidData) as e:
        modify_booking(repo, _perfil(), _id(5), _id(3), MANANA, time(10, 0), AHORA)

    assert set(_errores(e)) == {"space_id"}


def test_modificar_reserva_valida_el_horario_con_la_agenda() -> None:
    with pytest.raises(InvalidData):
        modify_booking(_con_reserva(), _perfil(), _id(5), _id(3), MANANA, time(7, 0), AHORA)

    repo = _con_reserva()
    repo.agenda_actual = None
    with pytest.raises(Unavailable):
        modify_booking(repo, _perfil(), _id(5), _id(3), MANANA, time(10, 0), AHORA)


def test_modificar_reserva_revalida_si_cambia_la_agenda_y_se_rinde_a_la_tercera() -> None:
    repo = _con_reserva()
    repo.agendas_cambiadas = 1
    modify_booking(repo, _perfil(), _id(5), _id(3), MANANA, time(10, 0), AHORA)
    assert len([c for c in repo.llamadas if c[0] == "mover"]) == 2

    repo = _con_reserva()
    repo.agendas_cambiadas = 99
    with pytest.raises(SlotTaken):
        modify_booking(repo, _perfil(), _id(5), _id(3), MANANA, time(10, 0), AHORA)
    assert len([c for c in repo.llamadas if c[0] == "mover"]) == 3


def test_modificar_reserva_de_tres_horas_conserva_la_duracion() -> None:
    repo = Memoria()
    repo.propia_de = _reserva(ends_at=datetime(2026, 3, 3, 21, 0, tzinfo=ZONA))

    nueva = modify_booking(repo, _perfil(), _id(5), _id(3), MANANA, time(10, 0), AHORA)

    assert nueva.ends_at - nueva.starts_at == timedelta(hours=3)


# global_history


def test_historial_global_lo_consulta_un_administrador_con_sus_filtros() -> None:
    repo = Memoria()
    filtros = HistoryFilters(since=date(2026, 1, 1), until=date(2026, 1, 1), q="ana")

    resultado = global_history(repo, _perfil(rol="admin"), filtros)

    assert resultado.total == 0
    assert repo.llamadas == [("history", filtros)]


def test_historial_global_un_usuario_es_prohibido() -> None:
    repo = Memoria()

    with pytest.raises(Forbidden):
        global_history(repo, _perfil(), HistoryFilters())
    assert repo.llamadas == []


def test_historial_global_rechaza_desde_posterior_a_hasta() -> None:
    admin = _perfil(rol="admin")
    filtros = HistoryFilters(since=date(2026, 1, 2), until=date(2026, 1, 1))

    with pytest.raises(InvalidData) as e:
        global_history(Memoria(), admin, filtros)

    assert set(_errores(e)) == {"dates"}


def test_historial_global_acepta_rangos_abiertos() -> None:
    admin = _perfil(rol="admin")

    global_history(Memoria(), admin, HistoryFilters(since=date(2026, 1, 2)))
    global_history(Memoria(), admin, HistoryFilters(until=date(2026, 1, 2)))


# admin_detail


def test_detalle_admin_devuelve_la_reserva_de_cualquiera() -> None:
    repo = Memoria()
    repo.detalle = _historial(user_id=_id(44))

    assert admin_detail(repo, _perfil(rol="admin"), _id(5)).user_id == _id(44)
    assert repo.llamadas == [("una_de_cualquiera", _id(5))]


def test_detalle_admin_un_usuario_es_prohibido() -> None:
    repo = Memoria()
    repo.detalle = _historial()

    with pytest.raises(Forbidden):
        admin_detail(repo, _perfil(), _id(5))
    assert repo.llamadas == []


def test_detalle_admin_sin_reserva_no_se_encuentra() -> None:
    with pytest.raises(NotFound):
        admin_detail(Memoria(), _perfil(rol="admin"), _id(5))


# anular_reserva


def test_anular_reserva_guarda_el_motivo_sin_espacios_y_quien_anula() -> None:
    repo = Memoria()
    inicio = datetime(2026, 3, 3, 18, 0, tzinfo=ZONA)

    resultado = void_booking(repo, _perfil(id=9, rol="admin"), _id(5), "  lluvia  ", _id(2), inicio)

    assert repo.llamadas == [("anular", _id(9), _id(5), "lluvia", _id(2), inicio)]
    assert resultado.reason == "lluvia"


def test_anular_reserva_un_usuario_es_prohibido() -> None:
    repo = Memoria()

    with pytest.raises(Forbidden):
        void_booking(repo, _perfil(), _id(5), "lluvia", _id(2), AHORA)
    assert repo.llamadas == []


@pytest.mark.parametrize("motivo", ["", "   ", "\n\t"])
def test_anular_reserva_sin_motivo_falla(motivo: str) -> None:
    repo = Memoria()

    with pytest.raises(InvalidData) as e:
        void_booking(repo, _perfil(rol="admin"), _id(5), motivo, _id(2), AHORA)

    assert set(_errores(e)) == {"reason"}
    assert repo.llamadas == []


def test_anular_reserva_acepta_el_motivo_maximo_y_rechaza_uno_mas() -> None:
    admin = _perfil(rol="admin")
    repo = Memoria()

    void_booking(repo, admin, _id(5), "x" * MAX_REASON_LENGTH, _id(2), AHORA)
    void_booking(repo, admin, _id(5), " " + "x" * MAX_REASON_LENGTH + " ", _id(2), AHORA)
    with pytest.raises(InvalidData) as e:
        void_booking(repo, admin, _id(5), "x" * (MAX_REASON_LENGTH + 1), _id(2), AHORA)

    assert set(_errores(e)) == {"reason"}
    assert str(MAX_REASON_LENGTH) in _errores(e)["reason"]
    assert len(repo.llamadas) == 2


def test_anular_reserva_deja_pasar_lo_que_ya_cambio() -> None:
    class Cambio(Memoria):
        def void(self, *a):
            raise ConcurrentChange()

    with pytest.raises(ConcurrentChange):
        void_booking(Cambio(), _perfil(rol="admin"), _id(5), "x", _id(2), AHORA)
