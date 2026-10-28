"""The single template of the app's emails: the app's dark palette as HTML that mail clients
respect (inline styles and tables, no images or scripts)."""

from collections.abc import Sequence
from html import escape

BACKGROUND = "#0A0A0B"
CARD = "#141416"
ACCENT = "#D4FF3D"
TEXT = "#FFFFFF"
TEXT_MUTED = "#A1A1AA"
BORDER = "#27272A"
TYPEFACE = "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif"
BRAND = "CLUB NAHUEL MOSSE"
CARD_WIDTH = 560


def _paragraph(text: str) -> str:
    return (
        f'<p style="margin:0 0 16px 0;font-size:16px;line-height:24px;'
        f'color:{TEXT_MUTED};">{escape(text)}</p>'
    )


def _details(details: Sequence[tuple[str, str]]) -> str:
    if not details:
        return ""
    rows = "".join(
        f'<tr><td style="padding:10px 0;border-top:1px solid {BORDER};font-size:13px;'
        f'color:{TEXT_MUTED};width:35%;">{escape(label)}</td>'
        f'<td style="padding:10px 0;border-top:1px solid {BORDER};font-size:15px;'
        f'font-weight:600;color:{TEXT};">{escape(value)}</td></tr>'
        for label, value in details
    )
    return (
        '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" '
        f'style="margin:8px 0 20px 0;">{rows}</table>'
    )


def _button(text: str, url: str) -> str:
    return (
        '<table role="presentation" cellpadding="0" cellspacing="0" border="0" '
        'style="margin:8px 0 20px 0;"><tr>'
        f'<td align="center" bgcolor="{ACCENT}" style="border-radius:10px;">'
        f'<a href="{escape(url)}" style="display:inline-block;padding:14px 28px;'
        f"font-family:{TYPEFACE};font-size:16px;font-weight:700;color:{BACKGROUND};"
        f'text-decoration:none;border-radius:10px;">{escape(text)}</a></td></tr></table>'
        f'<p style="margin:0 0 8px 0;font-size:12px;line-height:18px;color:{TEXT_MUTED};'
        f'word-break:break-all;">Si el botón no funciona, copiá este enlace: {escape(url)}</p>'
    )


def html_email(  # noqa: PLR0913, PLR0917 -- the content of an email is these parts
    title: str,
    paragraphs: Sequence[str],
    button: tuple[str, str] | None = None,
    footer: str = "",
    details: Sequence[tuple[str, str]] = (),
) -> str:
    """The complete HTML document. Every dynamic value is escaped here."""
    body = "".join(_paragraph(p) for p in paragraphs)
    action = "" if button is None else _button(*button)
    note = (
        f'<p style="margin:24px 0 0 0;font-size:12px;line-height:18px;'
        f'color:{TEXT_MUTED};">{escape(footer)}</p>'
        if footer
        else ""
    )
    return (
        '<!DOCTYPE html><html lang="es"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width,initial-scale=1">'
        f'<meta name="color-scheme" content="dark"><title>{escape(title)}</title></head>'
        f'<body style="margin:0;padding:0;background:{BACKGROUND};">'
        '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" '
        f'bgcolor="{BACKGROUND}" style="background:{BACKGROUND};"><tr><td align="center" '
        'style="padding:24px 12px;">'
        f'<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" '
        f'bgcolor="{CARD}" style="max-width:{CARD_WIDTH}px;background:{CARD};'
        f'border-radius:16px;font-family:{TYPEFACE};"><tr><td style="padding:32px 28px;">'
        f'<p style="margin:0 0 24px 0;font-size:13px;font-weight:700;letter-spacing:3px;'
        f'color:{ACCENT};">{BRAND}</p>'
        f'<h1 style="margin:0 0 16px 0;font-size:24px;line-height:32px;color:{TEXT};">'
        f"{escape(title)}</h1>"
        f"{body}{_details(details)}{action}{note}"
        "</td></tr></table></td></tr></table></body></html>"
    )
