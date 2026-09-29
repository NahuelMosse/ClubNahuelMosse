"""Las franjas que se pueden reservar en un espacio: horas completas, dentro del horario de
su sede y en el futuro (RF 3)."""

from collections.abc import Sequence
from dataclasses import dataclass
from datetime import date, datetime, time, timedelta, tzinfo

MIN_HORAS = 1
MAX_HORAS = 4
DIAS_A_LA_VISTA = 7


@dataclass(frozen=True)
class Agenda:
    """El horario de la sede de un espacio: abre de [apertura] a [cierre] los [dias] de la
    semana (1 es lunes). Un cierre a las 00:00 es la medianoche del mismo día."""

    apertura: time
    cierre: time
    dias: tuple[int, ...]


@dataclass(frozen=True)
class Franja:
    inicio: datetime
    fin: datetime
    disponible: bool


@dataclass(frozen=True)
class Grilla:
    fecha: date
    hoy: date
    abre: bool
    franjas: tuple[Franja, ...]

    @property
    def no_disponibles(self) -> int:
        return sum(1 for f in self.franjas if not f.disponible)


def validar_consulta(fecha: date, hoy: date, horas: int) -> dict[str, str]:
    errores: dict[str, str] = {}
    if not hoy <= fecha < hoy + timedelta(days=DIAS_A_LA_VISTA):
        errores["fecha"] = f"Elegí un día de los próximos {DIAS_A_LA_VISTA}"
    if not MIN_HORAS <= horas <= MAX_HORAS:
        errores["horas"] = f"La duración va de {MIN_HORAS} a {MAX_HORAS} horas"
    return errores


def grilla(
    agenda: Agenda,
    fecha: date,
    horas: int,
    ahora: datetime,
    ocupadas: Sequence[tuple[datetime, datetime]],
) -> Grilla:
    """Cada inicio en punto desde la apertura cuya franja de [horas] termina antes del
    cierre y todavía no empezó a [ahora], que trae la zona del club. Está disponible si no
    se superpone con ninguna de las [ocupadas]."""
    hoy = ahora.date()
    if fecha.isoweekday() not in agenda.dias:
        return Grilla(fecha=fecha, hoy=hoy, abre=False, franjas=())
    zona = ahora.tzinfo
    cierre = datetime.combine(fecha, agenda.cierre, tzinfo=zona)
    if agenda.cierre == time(0, 0):
        cierre += timedelta(days=1)
    duracion = timedelta(hours=horas)
    inicio = datetime.combine(fecha, agenda.apertura, tzinfo=zona)
    franjas: list[Franja] = []
    while inicio + duracion <= cierre:
        fin = inicio + duracion
        if inicio > ahora:
            libre = not any(desde < fin and hasta > inicio for desde, hasta in ocupadas)
            franjas.append(Franja(inicio=inicio, fin=fin, disponible=libre))
        inicio += timedelta(hours=1)
    return Grilla(fecha=fecha, hoy=hoy, abre=True, franjas=tuple(franjas))


def _hhmm(hora: time) -> str:
    return hora.strftime("%H:%M")


def rango(fecha: date, desde: time, hasta: time, zona: tzinfo | None) -> tuple[datetime, datetime]:
    """Inicio y fin de [desde, hasta) el [fecha]; hasta las 00:00 es la medianoche."""
    inicio = datetime.combine(fecha, desde, tzinfo=zona)
    fin = datetime.combine(fecha, hasta, tzinfo=zona)
    if hasta == time(0, 0):
        fin += timedelta(days=1)
    return inicio, fin


def validar_rango(
    agenda: Agenda, fecha: date, desde: time, hasta: time, ahora: datetime
) -> dict[str, str]:
    """Los errores de un rango consultado, por campo: futuro, en horas completas, de 1 a 4
    horas y dentro del horario de la sede (RF 3)."""
    errores: dict[str, str] = {}
    hoy = ahora.date()
    if fecha < hoy:
        errores["fecha"] = "La fecha tiene que ser futura"
    elif fecha >= hoy + timedelta(days=DIAS_A_LA_VISTA):
        errores["fecha"] = f"Elegí un día de los próximos {DIAS_A_LA_VISTA}"
    elif fecha.isoweekday() not in agenda.dias:
        errores["fecha"] = "La sede no abre ese día"
    for campo, hora in (("desde", desde), ("hasta", hasta)):
        if (hora.minute, hora.second, hora.microsecond) != (0, 0, 0):
            errores[campo] = "Elegí una hora en punto"
    if errores.keys() & {"desde", "hasta"} or fecha >= date.max - timedelta(days=1):
        return errores
    inicio, fin = rango(fecha, desde, hasta, ahora.tzinfo)
    apertura, cierre = rango(fecha, agenda.apertura, agenda.cierre, ahora.tzinfo)
    if fin - inicio < timedelta(hours=MIN_HORAS):
        errores["hasta"] = "La duración mínima es de una hora"
    elif fin - inicio > timedelta(hours=MAX_HORAS):
        errores["hasta"] = f"La duración máxima es de {MAX_HORAS} horas"
    elif fin > cierre:
        errores["hasta"] = f"La sede cierra a las {_hhmm(agenda.cierre)}"
    if inicio < apertura:
        errores["desde"] = f"La sede abre a las {_hhmm(agenda.apertura)}"
    elif "fecha" not in errores and inicio <= ahora:
        errores["desde"] = "El horario tiene que ser futuro"
    return errores


def validar_reserva(
    agenda: Agenda, fecha: date, desde: time, horas: int, ahora: datetime
) -> dict[str, str]:
    """Los errores de reservar [horas] horas desde [desde] el [fecha]: los de un rango (RF 3)
    más una duración entera que no pase de la medianoche."""
    if not MIN_HORAS <= horas <= MAX_HORAS:
        errores = validar_rango(agenda, fecha, desde, desde, ahora)
        errores["hasta"] = (
            "La duración mínima es de una hora"
            if horas < MIN_HORAS
            else f"La duración máxima es de {MAX_HORAS} horas"
        )
        return errores
    fin = desde.hour + horas
    if fin > 24:
        errores = validar_rango(agenda, fecha, desde, time(0, 0), ahora)
        errores["hasta"] = f"La sede cierra a las {_hhmm(agenda.cierre)}"
        return errores
    return validar_rango(agenda, fecha, desde, time(fin % 24, desde.minute), ahora)
