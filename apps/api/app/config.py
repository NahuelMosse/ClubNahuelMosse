from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict


class Config(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+psycopg://club:club@localhost:5432/club"
    firebase_project_id: str = "demo-clubnahuelmosse"
    # La clave web del proyecto, para comprobar contraseñas; el emulador no la necesita.
    firebase_api_key: str = ""
    # La dirección pública de esta API: los enlaces de los correos apuntan acá.
    url_publica: str = "http://localhost:8000"
    # "smtp" en producción; "buzon" deja los correos en la tabla correo_saliente, con los
    # códigos en claro, y sirve sólo para desarrollo y escenarios.
    correo_modo: Literal["buzon", "smtp"] = "smtp"
    smtp_host: str = ""
    smtp_puerto: int = 587
    smtp_usuario: str = ""
    smtp_contrasena: str = ""
    correo_remitente: str = ""
    # Habilita /_pruebas (el buzón y el vencimiento de enlaces), y sólo contra el emulador.
    pruebas: bool = False


config = Config()
