import tomllib
from pathlib import Path
from typing import Literal

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

API_ROOT = Path(__file__).resolve().parents[2]


_PROJECT = tomllib.loads((API_ROOT / "pyproject.toml").read_text(encoding="utf-8"))


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=API_ROOT / ".env", extra="ignore")

    version: str = str(_PROJECT["project"]["version"])
    database_url: str = "postgresql+psycopg://club:club@localhost:5432/club"
    firebase_project_id: str = "demo-clubnahuelmosse"
    # The project web key, to check passwords; the emulator does not need it.
    firebase_api_key: str = ""
    # The Firebase service account JSON, for platforms that do not mount files from a
    # blueprint. With GOOGLE_APPLICATION_CREDENTIALS set the file is used.
    firebase_credentials_json: str = ""
    # The public address of this API: the links in emails point here.
    public_url: str = "http://localhost:8000"
    # "brevo" in production (its HTTP API, because free Render blocks outgoing SMTP); "smtp" for
    # an own server; "outbox" leaves emails in the outgoing_email table, with the codes in
    # clear, and is only for development and scenarios.
    email_mode: Literal["outbox", "smtp", "brevo"] = "smtp"
    brevo_api_key: str = ""
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    email_sender: str = ""
    # Enables /_testing (the outbox and link expiry), and only against the emulator.
    e2e_testing: bool = False
    # Every how many seconds the sweep sends the reminders that are due; 0 turns it off.
    reminders_every: int = 30

    @field_validator("database_url")
    @classmethod
    def _with_psycopg_driver(cls, url: str) -> str:
        """Render hands out `postgresql://...`; SQLAlchemy needs the driver named."""
        for scheme in ("postgres://", "postgresql://"):
            if url.startswith(scheme):
                return "postgresql+psycopg://" + url.removeprefix(scheme)
        return url


config = Settings()
