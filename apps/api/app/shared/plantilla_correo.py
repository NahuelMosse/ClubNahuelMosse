"""La plantilla única de los correos de la app: la paleta oscura de la app en HTML que
respetan los clientes de correo (estilos en línea y tablas, sin imágenes ni scripts)."""

from collections.abc import Sequence
from html import escape

FONDO = "#0A0A0B"
TARJETA = "#141416"
ACENTO = "#D4FF3D"
TEXTO = "#FFFFFF"
TEXTO_SECUNDARIO = "#A1A1AA"
BORDE = "#27272A"
TIPOGRAFIA = "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif"
MARCA = "CLUB NAHUEL MOSSE"
ANCHO_TARJETA = 560


def _parrafo(texto: str) -> str:
    return (
        f'<p style="margin:0 0 16px 0;font-size:16px;line-height:24px;'
        f'color:{TEXTO_SECUNDARIO};">{escape(texto)}</p>'
    )


def _detalles(detalles: Sequence[tuple[str, str]]) -> str:
    if not detalles:
        return ""
    filas = "".join(
        f'<tr><td style="padding:10px 0;border-top:1px solid {BORDE};font-size:13px;'
        f'color:{TEXTO_SECUNDARIO};width:35%;">{escape(nombre)}</td>'
        f'<td style="padding:10px 0;border-top:1px solid {BORDE};font-size:15px;'
        f'font-weight:600;color:{TEXTO};">{escape(valor)}</td></tr>'
        for nombre, valor in detalles
    )
    return (
        '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" '
        f'style="margin:8px 0 20px 0;">{filas}</table>'
    )


def _boton(texto: str, url: str) -> str:
    return (
        '<table role="presentation" cellpadding="0" cellspacing="0" border="0" '
        'style="margin:8px 0 20px 0;"><tr>'
        f'<td align="center" bgcolor="{ACENTO}" style="border-radius:10px;">'
        f'<a href="{escape(url)}" style="display:inline-block;padding:14px 28px;'
        f"font-family:{TIPOGRAFIA};font-size:16px;font-weight:700;color:{FONDO};"
        f'text-decoration:none;border-radius:10px;">{escape(texto)}</a></td></tr></table>'
        f'<p style="margin:0 0 8px 0;font-size:12px;line-height:18px;color:{TEXTO_SECUNDARIO};'
        f'word-break:break-all;">Si el botón no funciona, copiá este enlace: {escape(url)}</p>'
    )


def html_de_correo(  # noqa: PLR0913 -- el contenido de un correo son estas partes
    titulo: str,
    parrafos: Sequence[str],
    boton: tuple[str, str] | None = None,
    pie: str = "",
    detalles: Sequence[tuple[str, str]] = (),
) -> str:
    """El documento HTML completo. Todo dato dinámico se escapa acá."""
    cuerpo = "".join(_parrafo(p) for p in parrafos)
    accion = "" if boton is None else _boton(*boton)
    nota = (
        f'<p style="margin:24px 0 0 0;font-size:12px;line-height:18px;'
        f'color:{TEXTO_SECUNDARIO};">{escape(pie)}</p>'
        if pie
        else ""
    )
    return (
        '<!DOCTYPE html><html lang="es"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width,initial-scale=1">'
        f'<meta name="color-scheme" content="dark"><title>{escape(titulo)}</title></head>'
        f'<body style="margin:0;padding:0;background:{FONDO};">'
        '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" '
        f'bgcolor="{FONDO}" style="background:{FONDO};"><tr><td align="center" '
        'style="padding:24px 12px;">'
        f'<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" '
        f'bgcolor="{TARJETA}" style="max-width:{ANCHO_TARJETA}px;background:{TARJETA};'
        f'border-radius:16px;font-family:{TIPOGRAFIA};"><tr><td style="padding:32px 28px;">'
        f'<p style="margin:0 0 24px 0;font-size:13px;font-weight:700;letter-spacing:3px;'
        f'color:{ACENTO};">{MARCA}</p>'
        f'<h1 style="margin:0 0 16px 0;font-size:24px;line-height:32px;color:{TEXTO};">'
        f"{escape(titulo)}</h1>"
        f"{cuerpo}{_detalles(detalles)}{accion}{nota}"
        "</td></tr></table></td></tr></table></body></html>"
    )
