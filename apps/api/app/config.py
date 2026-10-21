from typing import Literal

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Config(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+psycopg://club:club@localhost:5432/club"
    firebase_project_id: str = "demo-clubnahuelmosse"
    # La clave web del proyecto, para comprobar contraseñas; el emulador no la necesita.
    firebase_api_key: str = ""
    # El JSON de la cuenta de servicio de Firebase, para las plataformas que no montan archivos
    # desde un blueprint. Con GOOGLE_APPLICATION_CREDENTIALS definida se usa el archivo.
    firebase_credenciales_json: str = ""
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
    # Cada cuántos segundos el barrido manda los recordatorios que ya les toca; 0 lo apaga.
    recordatorios_cada: int = 30
    # Detrás del proxy de Render el origen de un pedido es el último valor de X-Forwarded-For.
    detras_de_proxy: bool = False

    @field_validator("database_url")
    @classmethod
    def _con_driver_psycopg(cls, url: str) -> str:
        """Render entrega `postgresql://...`; SQLAlchemy necesita nombrar el driver."""
        for esquema in ("postgres://", "postgresql://"):
            if url.startswith(esquema):
                return "postgresql+psycopg://" + url.removeprefix(esquema)
        return url


config = Config()
