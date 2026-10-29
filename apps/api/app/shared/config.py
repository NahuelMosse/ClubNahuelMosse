import tomllib
from pathlib import Path
from typing import Any, Literal

from pydantic import AliasChoices, Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

API_ROOT = Path(__file__).resolve().parents[2]


_PROJECT = tomllib.loads((API_ROOT / "pyproject.toml").read_text(encoding="utf-8"))


def _env(default: Any, english: str, spanish: str) -> Any:
    """A setting read from its English variable or the previous Spanish one; English wins."""
    return Field(default, validation_alias=AliasChoices(english, spanish))


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=API_ROOT / ".env", extra="ignore", populate_by_name=True
    )

    version: str = str(_PROJECT["project"]["version"])
    database_url: str = "postgresql+psycopg://club:club@localhost:5432/club"
    firebase_project_id: str = "demo-clubnahuelmosse"
    # The project web key, to check passwords; the emulator does not need it.
    firebase_api_key: str = ""
    # The Firebase service account JSON, for platforms that do not mount files from a
    # blueprint. With GOOGLE_APPLICATION_CREDENTIALS set the file is used.
    firebase_credentials_json: str = _env(
        "", "FIREBASE_CREDENTIALS_JSON", "FIREBASE_CREDENCIALES_JSON"
    )
    # The public address of this API: the links in emails point here.
    public_url: str = _env("http://localhost:8000", "PUBLIC_URL", "URL_PUBLICA")
    # "brevo" in production (its HTTP API, because free Render blocks outgoing SMTP); "smtp" for
    # an own server; "outbox" leaves emails in the correo_saliente table, with the codes in
    # clear, and is only for development and scenarios.
    email_mode: Literal["outbox", "smtp", "brevo"] = _env("smtp", "EMAIL_MODE", "CORREO_MODO")
    brevo_api_key: str = ""
    smtp_host: str = ""
    smtp_port: int = _env(587, "SMTP_PORT", "SMTP_PUERTO")
    smtp_user: str = _env("", "SMTP_USER", "SMTP_USUARIO")
    smtp_password: str = _env("", "SMTP_PASSWORD", "SMTP_CONTRASENA")
    email_sender: str = _env("", "EMAIL_SENDER", "CORREO_REMITENTE")
    # Enables /_testing (the outbox and link expiry), and only against the emulator.
    e2e_testing: bool = Field(
        default=False, validation_alias=AliasChoices("E2E_TESTING", "PRUEBAS")
    )
    # Every how many seconds the sweep sends the reminders that are due; 0 turns it off.
    reminders_every: int = _env(30, "REMINDERS_EVERY", "RECORDATORIOS_CADA")

    @field_validator("email_mode", mode="before")
    @classmethod
    def _accept_previous_outbox_name(cls, mode: Any) -> Any:
        return "outbox" if mode == "buzon" else mode

    @field_validator("database_url")
    @classmethod
    def _with_psycopg_driver(cls, url: str) -> str:
        """Render hands out `postgresql://...`; SQLAlchemy needs the driver named."""
        for scheme in ("postgres://", "postgresql://"):
            if url.startswith(scheme):
                return "postgresql+psycopg://" + url.removeprefix(scheme)
        return url


config = Settings()
