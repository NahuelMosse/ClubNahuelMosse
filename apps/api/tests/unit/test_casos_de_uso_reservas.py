"""Casos de uso de reservas con un repositorio en memoria: sin base ni emulador."""

from dataclasses import replace
from datetime import date, datetime, time, timedelta, timezone

import pytest

from app.aplicacion.errores import (
    AgendaCambiada,
    Cambiado,
    DatosInvalidos,
    HorarioOcupado,
    NoDisponible,
    NoEncontrada,
    Prohibido,
)
from app.aplicacion.reservas import (
    MOTIVO_MAXIMO,
    anular_reserva,
    cancelar_reserva,
    detalle_admin,
    historial_global,
    mis_reservas,
    modificar_reserva,
    reservar,
)
from app.dominio.horarios import Agenda
from app.dominio.reservas import (
    Contadores,
    FiltrosHistorial,
    HistorialDeReservas,
    Reserva,
    ReservaHistorial,
)
from app.dominio.usuarios import Perfil

ZONA = timezone(timedelta(hours=-3))
AHORA = datetime(2026, 3, 2, 10, 0, tzinfo=ZONA)  # lunes
MANANA = date(2026, 3, 3)
AGENDA = Agenda(apertura=time(8, 0), cierre=time(23, 0), dias=(1, 2, 3, 4, 5, 6, 7))


def _perfil(id: int = 1, rol: str = "usuario") -> Perfil:
    return Perfil(
        id=id, uid=f"u{id}", nombre="Ana", apellido="Paz", correo="a@b.c", rol=rol,
        dni="1", fecha_nacimiento=date(2000, 1, 1),
    )  # fmt: skip


def _reserva(**cambios: object) -> Reserva:
    base = Reserva(
        id=5, espacio_id=2, sede_id=1, espacio="Cancha 1", deporte="futbol", tipo="5",
        sede="Centro", direccion="x", inicio=datetime(2026, 3, 3, 18, 0, tzinfo=ZONA),
        fin=datetime(2026, 3, 3, 20, 0, tzinfo=ZONA), precio_por_hora=100, total=200,
        estado="activa", motivo=None,
    )  # fmt: skip
    return replace(base, **cambios)


def _historial(**cambios: object) -> ReservaHistorial:
    r = _reserva()
    base = ReservaHistorial(
        id=r.id, espacio_id=r.espacio_id, sede_id=r.sede_id, espacio=r.espacio,
        deporte=r.deporte, tipo=r.tipo, sede=r.sede, direccion=r.direccion, inicio=r.inicio,
        fin=r.fin, precio_por_hora=100, total=200, estado="activa", motivo=None,
        usuario_id=1, usuario="Ana Paz", creado_en=AHORA, cancelada_en=None,
        cancelada_por_nombre=None, espacio_de_baja=False,
    )  # fmt: skip
    return replace(base, **cambios)


class Memoria:
    def __init__(self) -> None:
        self.agenda_actual: Agenda | None = AGENDA
        self.repetida_hecha: Reserva | None = None
        self.propia_de: Reserva | None = None
        self.tipo: tuple[int, str, str] | None = (1, "futbol", "5")
        self.agendas_cambiadas = 0
        self.llamadas: list[tuple] = []
        self.detalle: ReservaHistorial | None = None

    def de_usuario(self, usuario_id, cuando):
        self.llamadas.append(("de_usuario", usuario_id, cuando))
        return [_reserva()]

    def agenda(self, espacio_id):
        return self.agenda_actual

    def repetida(self, usuario_id, espacio_id, inicio, fin):
        self.llamadas.append(("repetida", usuario_id, espacio_id, inicio, fin))
        return self.repetida_hecha

    def propia(self, usuario_id, reserva_id):
        self.llamadas.append(("propia", usuario_id, reserva_id))
        return self.propia_de

    def tipo_de_espacio(self, espacio_id):
        return self.tipo

    def mover(self, usuario_id, reserva_id, antes, espacio_id, inicio, fin, agenda):
        self.llamadas.append(("mover", usuario_id, reserva_id, antes, espacio_id, inicio, fin))
        if self.agendas_cambiadas:
            self.agendas_cambiadas -= 1
            raise AgendaCambiada()
        return _reserva(espacio_id=espacio_id, inicio=inicio, fin=fin)

    def cancelar(self, usuario_id, reserva_id):
        self.llamadas.append(("cancelar", usuario_id, reserva_id))
        return _reserva(estado="cancelada")

    def insertar(self, usuario_id, espacio_id, inicio, fin, agenda):
        self.llamadas.append(("insertar", usuario_id, espacio_id, inicio, fin, agenda))
        if self.agendas_cambiadas:
            self.agendas_cambiadas -= 1
            raise AgendaCambiada()
        return _reserva(espacio_id=espacio_id, inicio=inicio, fin=fin)

    def anular(self, admin_id, reserva_id, motivo, espacio_id, inicio):
        self.llamadas.append(("anular", admin_id, reserva_id, motivo, espacio_id, inicio))
        return _historial(estado="anulada", motivo=motivo)

    def historial(self, filtros):
        self.llamadas.append(("historial", filtros))
        return HistorialDeReservas(
            reservas=[], total=0, pagina=1, por_pagina=20,
            contadores=Contadores(todas=0, activas=0, completadas=0, anuladas=0),
        )  # fmt: skip

    def una_de_cualquiera(self, reserva_id):
        self.llamadas.append(("una_de_cualquiera", reserva_id))
        return self.detalle


def _errores(excepcion: pytest.ExceptionInfo[DatosInvalidos]) -> dict[str, str]:
    return excepcion.value.errores


# mis_reservas


def test_mis_reservas_pide_solo_las_de_quien_consulta() -> None:
    repo = Memoria()

    resultado = mis_reservas(repo, _perfil(id=7), "proximas")

    assert resultado == [_reserva()]
    assert repo.llamadas == [("de_usuario", 7, "proximas")]
    mis_reservas(repo, _perfil(id=7), "historial")
    assert repo.llamadas[-1] == ("de_usuario", 7, "historial")


# reservar


def test_reservar_guarda_con_el_horario_pedido_y_la_agenda_de_la_sede() -> None:
    repo = Memoria()

    reserva = reservar(repo, _perfil(), 2, MANANA, time(18, 0), 2, AHORA)

    inicio = datetime(2026, 3, 3, 18, 0, tzinfo=ZONA)
    assert repo.llamadas[-1] == ("insertar", 1, 2, inicio, inicio + timedelta(hours=2), AGENDA)
    assert (reserva.inicio, reserva.fin) == (inicio, inicio + timedelta(hours=2))


def test_reservar_hasta_la_medianoche_es_valido() -> None:
    repo = Memoria()

    reserva = reservar(repo, _perfil(), 2, MANANA, time(22, 0), 1, AHORA)

    assert reserva.fin == datetime(2026, 3, 3, 23, 0, tzinfo=ZONA)


def test_reservar_un_administrador_es_prohibido() -> None:
    with pytest.raises(Prohibido):
        reservar(Memoria(), _perfil(rol="admin"), 2, MANANA, time(18, 0), 1, AHORA)


def test_reservar_sin_hora_pide_una_hora_en_punto() -> None:
    with pytest.raises(DatosInvalidos) as e:
        reservar(Memoria(), _perfil(), 2, MANANA, None, 1, AHORA)

    assert set(_errores(e)) == {"desde"}


@pytest.mark.parametrize("horas", [0, 5, -1])
def test_reservar_con_una_duracion_fuera_de_una_a_cuatro_horas_falla(horas: int) -> None:
    repo = Memoria()

    with pytest.raises(DatosInvalidos) as e:
        reservar(repo, _perfil(), 2, MANANA, time(18, 0), horas, AHORA)

    assert set(_errores(e)) == {"horas", "hasta"}
    assert repo.llamadas == []


@pytest.mark.parametrize("horas", [1, 4])
def test_reservar_acepta_los_bordes_de_la_duracion(horas: int) -> None:
    reserva = reservar(Memoria(), _perfil(), 2, MANANA, time(10, 0), horas, AHORA)

    assert reserva.fin - reserva.inicio == timedelta(hours=horas)


def test_reservar_un_dia_fuera_de_la_ventana_falla_aun_en_date_max() -> None:
    with pytest.raises(DatosInvalidos) as e:
        reservar(Memoria(), _perfil(), 2, date.max, time(18, 0), 4, AHORA)
    assert set(_errores(e)) == {"fecha"}

    with pytest.raises(DatosInvalidos):
        reservar(Memoria(), _perfil(), 2, AHORA.date() + timedelta(days=7), time(18, 0), 1, AHORA)


def test_reservar_el_ultimo_dia_de_la_ventana_se_acepta() -> None:
    dia = AHORA.date() + timedelta(days=6)

    assert reservar(Memoria(), _perfil(), 2, dia, time(18, 0), 1, AHORA).id == 5


def test_reservar_devuelve_el_pedido_repetido_sin_validar_el_horario() -> None:
    repo = Memoria()
    repo.repetida_hecha = _reserva(id=99)
    repo.agenda_actual = None
    ya_empezado = AHORA - timedelta(days=1)

    reserva = reservar(repo, _perfil(), 2, ya_empezado.date(), time(9, 0), 1, AHORA)

    assert reserva.id == 99
    assert [c[0] for c in repo.llamadas] == ["repetida"]


def test_reservar_un_espacio_sin_agenda_no_esta_disponible() -> None:
    repo = Memoria()
    repo.agenda_actual = None

    with pytest.raises(NoDisponible):
        reservar(repo, _perfil(), 2, MANANA, time(18, 0), 1, AHORA)


def test_reservar_fuera_del_horario_de_la_sede_falla_sin_guardar() -> None:
    repo = Memoria()

    with pytest.raises(DatosInvalidos):
        reservar(repo, _perfil(), 2, MANANA, time(7, 0), 1, AHORA)
    with pytest.raises(DatosInvalidos):
        reservar(repo, _perfil(), 2, MANANA, time(22, 0), 2, AHORA)
    assert [c for c in repo.llamadas if c[0] == "insertar"] == []


def test_reservar_revalida_si_la_agenda_cambio_en_el_medio() -> None:
    repo = Memoria()
    repo.agendas_cambiadas = 2

    reserva = reservar(repo, _perfil(), 2, MANANA, time(18, 0), 1, AHORA)

    assert reserva.id == 5
    assert len([c for c in repo.llamadas if c[0] == "insertar"]) == 3


def test_reservar_con_la_agenda_cambiando_siempre_termina_en_horario_ocupado() -> None:
    repo = Memoria()
    repo.agendas_cambiadas = 99

    with pytest.raises(HorarioOcupado):
        reservar(repo, _perfil(), 2, MANANA, time(18, 0), 1, AHORA)

    assert len([c for c in repo.llamadas if c[0] == "insertar"]) == 3


# cancelar_reserva


def test_cancelar_reserva_cancela_la_de_quien_pide() -> None:
    repo = Memoria()

    reserva = cancelar_reserva(repo, _perfil(id=3), 5)

    assert reserva.estado == "cancelada"
    assert repo.llamadas == [("cancelar", 3, 5)]


def test_cancelar_reserva_deja_pasar_los_errores_del_repositorio() -> None:
    class Ajena(Memoria):
        def cancelar(self, usuario_id, reserva_id):
            raise NoEncontrada("no")

    with pytest.raises(NoEncontrada):
        cancelar_reserva(Ajena(), _perfil(), 5)


# modificar_reserva


def _con_reserva() -> Memoria:
    repo = Memoria()
    repo.propia_de = _reserva()
    return repo


def test_modificar_reserva_mueve_con_la_misma_duracion_y_el_estado_anterior() -> None:
    repo = _con_reserva()

    nueva = modificar_reserva(repo, _perfil(), 5, 3, MANANA, time(10, 0), AHORA)

    inicio = datetime(2026, 3, 3, 10, 0, tzinfo=ZONA)
    antes = (2, datetime(2026, 3, 3, 18, 0, tzinfo=ZONA))
    assert repo.llamadas[-1] == ("mover", 1, 5, antes, 3, inicio, inicio + timedelta(hours=2))
    assert (nueva.espacio_id, nueva.inicio) == (3, inicio)


def test_modificar_reserva_un_administrador_es_prohibido() -> None:
    with pytest.raises(Prohibido):
        modificar_reserva(_con_reserva(), _perfil(rol="admin"), 5, 2, MANANA, time(9, 0), AHORA)


def test_modificar_reserva_sin_hora_falla() -> None:
    with pytest.raises(DatosInvalidos) as e:
        modificar_reserva(_con_reserva(), _perfil(), 5, 2, MANANA, None, AHORA)

    assert set(_errores(e)) == {"desde"}


def test_modificar_reserva_fuera_de_la_ventana_falla_antes_de_buscarla() -> None:
    repo = _con_reserva()

    with pytest.raises(DatosInvalidos) as e:
        modificar_reserva(repo, _perfil(), 5, 2, date.max, time(9, 0), AHORA)

    assert set(_errores(e)) == {"fecha"}
    assert repo.llamadas == []


def test_modificar_reserva_ajena_no_se_encuentra() -> None:
    with pytest.raises(NoEncontrada):
        modificar_reserva(Memoria(), _perfil(), 5, 2, MANANA, time(9, 0), AHORA)


def test_modificar_reserva_repetida_devuelve_la_actual_sin_mover() -> None:
    repo = _con_reserva()

    reserva = modificar_reserva(repo, _perfil(), 5, 2, MANANA, time(18, 0), AHORA)

    assert reserva == _reserva()
    assert [c[0] for c in repo.llamadas] == ["propia"]


def test_modificar_reserva_cancelada_con_el_mismo_horario_no_se_da_por_repetida() -> None:
    repo = Memoria()
    repo.propia_de = _reserva(estado="cancelada")

    modificar_reserva(repo, _perfil(), 5, 2, MANANA, time(18, 0), AHORA)

    assert repo.llamadas[-1][0] == "mover"


def test_modificar_reserva_mismo_espacio_otro_horario_o_otro_espacio_mismo_horario_mueve() -> None:
    repo = _con_reserva()

    modificar_reserva(repo, _perfil(), 5, 2, MANANA, time(19, 0), AHORA)
    assert repo.llamadas[-1][0] == "mover"
    modificar_reserva(repo, _perfil(), 5, 3, MANANA, time(18, 0), AHORA)
    assert repo.llamadas[-1][0] == "mover"


@pytest.mark.parametrize("tipo", [None, (2, "futbol", "5"), (1, "tenis", "5"), (1, "futbol", "7")])
def test_modificar_reserva_a_una_cancha_de_otro_tipo_o_sede_falla(tipo) -> None:
    repo = _con_reserva()
    repo.tipo = tipo

    with pytest.raises(DatosInvalidos) as e:
        modificar_reserva(repo, _perfil(), 5, 3, MANANA, time(10, 0), AHORA)

    assert set(_errores(e)) == {"espacio_id"}


def test_modificar_reserva_valida_el_horario_con_la_agenda() -> None:
    with pytest.raises(DatosInvalidos):
        modificar_reserva(_con_reserva(), _perfil(), 5, 3, MANANA, time(7, 0), AHORA)

    repo = _con_reserva()
    repo.agenda_actual = None
    with pytest.raises(NoDisponible):
        modificar_reserva(repo, _perfil(), 5, 3, MANANA, time(10, 0), AHORA)


def test_modificar_reserva_revalida_si_cambia_la_agenda_y_se_rinde_a_la_tercera() -> None:
    repo = _con_reserva()
    repo.agendas_cambiadas = 1
    modificar_reserva(repo, _perfil(), 5, 3, MANANA, time(10, 0), AHORA)
    assert len([c for c in repo.llamadas if c[0] == "mover"]) == 2

    repo = _con_reserva()
    repo.agendas_cambiadas = 99
    with pytest.raises(HorarioOcupado):
        modificar_reserva(repo, _perfil(), 5, 3, MANANA, time(10, 0), AHORA)
    assert len([c for c in repo.llamadas if c[0] == "mover"]) == 3


def test_modificar_reserva_de_tres_horas_conserva_la_duracion() -> None:
    repo = Memoria()
    repo.propia_de = _reserva(fin=datetime(2026, 3, 3, 21, 0, tzinfo=ZONA))

    nueva = modificar_reserva(repo, _perfil(), 5, 3, MANANA, time(10, 0), AHORA)

    assert nueva.fin - nueva.inicio == timedelta(hours=3)


# historial_global


def test_historial_global_lo_consulta_un_administrador_con_sus_filtros() -> None:
    repo = Memoria()
    filtros = FiltrosHistorial(desde=date(2026, 1, 1), hasta=date(2026, 1, 1), q="ana")

    resultado = historial_global(repo, _perfil(rol="admin"), filtros)

    assert resultado.total == 0
    assert repo.llamadas == [("historial", filtros)]


def test_historial_global_un_usuario_es_prohibido() -> None:
    repo = Memoria()

    with pytest.raises(Prohibido):
        historial_global(repo, _perfil(), FiltrosHistorial())
    assert repo.llamadas == []


def test_historial_global_rechaza_desde_posterior_a_hasta() -> None:
    admin = _perfil(rol="admin")
    filtros = FiltrosHistorial(desde=date(2026, 1, 2), hasta=date(2026, 1, 1))

    with pytest.raises(DatosInvalidos) as e:
        historial_global(Memoria(), admin, filtros)

    assert set(_errores(e)) == {"fechas"}


def test_historial_global_acepta_rangos_abiertos() -> None:
    admin = _perfil(rol="admin")

    historial_global(Memoria(), admin, FiltrosHistorial(desde=date(2026, 1, 2)))
    historial_global(Memoria(), admin, FiltrosHistorial(hasta=date(2026, 1, 2)))


# detalle_admin


def test_detalle_admin_devuelve_la_reserva_de_cualquiera() -> None:
    repo = Memoria()
    repo.detalle = _historial(usuario_id=44)

    assert detalle_admin(repo, _perfil(rol="admin"), 5).usuario_id == 44
    assert repo.llamadas == [("una_de_cualquiera", 5)]


def test_detalle_admin_un_usuario_es_prohibido() -> None:
    repo = Memoria()
    repo.detalle = _historial()

    with pytest.raises(Prohibido):
        detalle_admin(repo, _perfil(), 5)
    assert repo.llamadas == []


def test_detalle_admin_sin_reserva_no_se_encuentra() -> None:
    with pytest.raises(NoEncontrada):
        detalle_admin(Memoria(), _perfil(rol="admin"), 5)


# anular_reserva


def test_anular_reserva_guarda_el_motivo_sin_espacios_y_quien_anula() -> None:
    repo = Memoria()
    inicio = datetime(2026, 3, 3, 18, 0, tzinfo=ZONA)

    resultado = anular_reserva(repo, _perfil(id=9, rol="admin"), 5, "  lluvia  ", 2, inicio)

    assert repo.llamadas == [("anular", 9, 5, "lluvia", 2, inicio)]
    assert resultado.motivo == "lluvia"


def test_anular_reserva_un_usuario_es_prohibido() -> None:
    repo = Memoria()

    with pytest.raises(Prohibido):
        anular_reserva(repo, _perfil(), 5, "lluvia", 2, AHORA)
    assert repo.llamadas == []


@pytest.mark.parametrize("motivo", ["", "   ", "\n\t"])
def test_anular_reserva_sin_motivo_falla(motivo: str) -> None:
    repo = Memoria()

    with pytest.raises(DatosInvalidos) as e:
        anular_reserva(repo, _perfil(rol="admin"), 5, motivo, 2, AHORA)

    assert set(_errores(e)) == {"motivo"}
    assert repo.llamadas == []


def test_anular_reserva_acepta_el_motivo_maximo_y_rechaza_uno_mas() -> None:
    admin = _perfil(rol="admin")
    repo = Memoria()

    anular_reserva(repo, admin, 5, "x" * MOTIVO_MAXIMO, 2, AHORA)
    anular_reserva(repo, admin, 5, " " + "x" * MOTIVO_MAXIMO + " ", 2, AHORA)
    with pytest.raises(DatosInvalidos) as e:
        anular_reserva(repo, admin, 5, "x" * (MOTIVO_MAXIMO + 1), 2, AHORA)

    assert set(_errores(e)) == {"motivo"}
    assert str(MOTIVO_MAXIMO) in _errores(e)["motivo"]
    assert len(repo.llamadas) == 2


def test_anular_reserva_deja_pasar_lo_que_ya_cambio() -> None:
    class Cambio(Memoria):
        def anular(self, *a):
            raise Cambiado()

    with pytest.raises(Cambiado):
        anular_reserva(Cambio(), _perfil(rol="admin"), 5, "x", 2, AHORA)
