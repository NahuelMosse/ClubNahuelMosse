from alembic import context
from sqlalchemy import create_engine

from app.config import config as config_app

url = context.config.get_main_option("sqlalchemy.url") or config_app.database_url


def correr() -> None:
    motor = create_engine(url)
    try:
        with motor.connect() as conn:
            context.configure(connection=conn)
            with context.begin_transaction():
                context.run_migrations()
    finally:
        motor.dispose()


correr()
