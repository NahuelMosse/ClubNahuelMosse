from app.modules.notificaciones.reglas import Aviso, Destinatario
from app.shared.mensaje import Mensaje
from app.shared.plantilla_correo import html_de_correo

TEXTO_DEL_BOTON = "Abrir la app"


def correo_de_aviso(aviso: Aviso, destinatario: Destinatario, url_publica: str) -> Mensaje:
    """El aviso por correo con la plantilla de la app: su título y su cuerpo y, si hay enlace
    público configurado, el botón que abre la app."""
    saludo = f"Hola {destinatario.nombre}:" if destinatario.nombre else "Hola:"
    parrafos = [saludo, aviso.cuerpo]
    boton = (TEXTO_DEL_BOTON, url_publica) if url_publica else None
    return Mensaje(
        para=destinatario.correo,
        asunto=aviso.titulo,
        cuerpo="\n\n".join([aviso.titulo, *parrafos]),
        html=html_de_correo(aviso.titulo, parrafos, boton),
    )
