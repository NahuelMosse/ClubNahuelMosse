"""Las franjas que se pueden reservar en un espacio: horas completas, dentro del horario de
su sede y en el futuro (RF 3)."""

from collections.abc import Sequence
from dataclasses import dataclass
from datetime import date, datetime, time, timedelta

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
