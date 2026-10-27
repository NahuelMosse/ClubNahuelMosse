from app.modules.notificaciones import tipo_corto
from app.modules.reservas.reglas import Reserva
from app.modules.sesion import Perfil
from app.shared.mensaje import Mensaje
from app.shared.plantilla_correo import html_de_correo
from app.shared.zona import ZONA_CLUB

DIAS = ("lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo")
MESES = (
    "enero",
    "febrero",
    "marzo",
    "abril",
    "mayo",
    "junio",
    "julio",
    "agosto",
    "septiembre",
    "octubre",
    "noviembre",
    "diciembre",
)
ASUNTO = "Tu reserva está confirmada"


def _dinero(monto: int) -> str:
    """«$ 12.000», con punto de miles como se lee en es-AR."""
    return f"$ {monto:,}".replace(",", ".")


def correo_de_reserva(perfil: Perfil, reserva: Reserva) -> Mensaje:
    """La confirmación de una reserva nueva, con el día y la hora del club."""
    inicio = reserva.inicio.astimezone(ZONA_CLUB)
    fin = reserva.fin.astimezone(ZONA_CLUB)
    detalles = [
        ("Cancha", tipo_corto(reserva.deporte, reserva.tipo)),
        ("Sede", reserva.sede),
        ("Día", f"{DIAS[inicio.weekday()]} {inicio.day} de {MESES[inicio.month - 1]}"),
        ("Horario", f"{inicio:%H:%M} a {fin:%H:%M}"),
        ("Total", _dinero(reserva.total)),
    ]
    saludo = f"Hola {perfil.nombre}: ya tenés tu cancha."
    return Mensaje(
        para=perfil.correo,
        asunto=ASUNTO,
        cuerpo="\n".join([saludo, "", *(f"{nombre}: {valor}" for nombre, valor in detalles)]),
        html=html_de_correo(ASUNTO, [saludo], detalles=detalles, pie="Te esperamos en la sede."),
    )
