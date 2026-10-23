from alembic import context
from sqlalchemy import create_engine

from app.config import config as config_app

url = context.config.get_main_option("sqlalchemy.url") or config_app.database_url


def correr() -> None:
    motor = create_engine(url)
    try:
        with motor.connect() as conn:
            # Una transacción por migración: un `CREATE INDEX CONCURRENTLY` no corre dentro de
            # una, y una sola para todo el upgrade mantendría tomados los locks de las primeras
            # mientras se arma el índice de la última.
            context.configure(connection=conn, transaction_per_migration=True)
            with context.begin_transaction():
                context.run_migrations()
    finally:
        motor.dispose()


correr()
