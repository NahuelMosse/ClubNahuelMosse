from pydantic_settings import BaseSettings, SettingsConfigDict


class Config(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+psycopg://club:club@localhost:5432/club"
    firebase_project_id: str = "demo-clubnahuelmosse"
    # La clave web del proyecto, para comprobar contraseñas; el emulador no la necesita.
    firebase_api_key: str = ""


config = Config()
