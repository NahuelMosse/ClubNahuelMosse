from alembic import context
from sqlalchemy import create_engine

from app.shared.config import config as app_config

url = context.config.get_main_option("sqlalchemy.url") or app_config.database_url


def run() -> None:
    engine = create_engine(url)
    try:
        with engine.connect() as conn:
            # One transaction per migration: a `CREATE INDEX CONCURRENTLY` cannot run inside
            # one, and a single transaction for the whole upgrade would hold the locks of the
            # first migrations while the last index is built.
            context.configure(connection=conn, transaction_per_migration=True)
            with context.begin_transaction():
                context.run_migrations()
    finally:
        engine.dispose()


run()
