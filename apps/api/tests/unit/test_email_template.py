"""La plantilla de correo sin tabla de detalles no deja rastros en el HTML."""

from app.shared.email_template import html_email


def test_un_correo_sin_detalles_no_muestra_none_ni_una_tabla_vacia() -> None:
    """un correo sin detalles no muestra None ni una tabla de detalles vacía @MAIL-02-S1"""
    html = html_email("Creá una contraseña nueva", ["Hola Ana:"])

    assert "None" not in html
    assert "width:35%" not in html
