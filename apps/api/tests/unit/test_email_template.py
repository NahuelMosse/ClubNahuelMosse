"""The email template without a details table leaves no traces in the HTML."""

from app.shared.email_template import html_email


def test_an_email_without_details_shows_neither_none_nor_an_empty_table() -> None:
    """an email without details shows neither None nor an empty details table @MAIL-02-S1"""
    html = html_email("Create a new password", ["Hi Ana:"])

    assert "None" not in html
    assert "width:35%" not in html
