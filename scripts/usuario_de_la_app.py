"""Crea (o actualiza la clave de) `club_app`, el usuario de base con el que se conecta la API:
lee y escribe datos y no puede cambiar el esquema. Las migraciones siguen corriendo con el
usuario dueño (`DATABASE_URL`); la API usa `DATABASE_URL_APP`.

    python scripts/usuario_de_la_app.py --url <url del dueño> --clave <clave>
"""

import argparse
import sys

import psycopg
from psycopg import sql
from sqlalchemy.engine import make_url

USUARIO = "club_app"


def crear(url: str, clave: str) -> None:
    destino = make_url(url)
    conexion = psycopg.connect(
        host=destino.host,
        port=destino.port,
        user=destino.username,
        password=destino.password,
        dbname=destino.database,
        autocommit=True,
    )
    base = sql.Identifier(destino.database or "")
    rol = sql.Identifier(USUARIO)
    with conexion:
        existe = conexion.execute(
            "SELECT 1 FROM pg_roles WHERE rolname = %s", (USUARIO,)
        ).fetchone()
        verbo = "ALTER" if existe else "CREATE"
        conexion.execute(
            sql.SQL("{} ROLE {} LOGIN PASSWORD {} NOSUPERUSER NOCREATEDB NOCREATEROLE").format(
                sql.SQL(verbo), rol, sql.Literal(clave)
            )
        )
        conexion.execute(sql.SQL("GRANT CONNECT ON DATABASE {} TO {}").format(base, rol))
        conexion.execute(sql.SQL("REVOKE CREATE ON SCHEMA public FROM PUBLIC"))
        conexion.execute(sql.SQL("GRANT USAGE ON SCHEMA public TO {}").format(rol))
        conexion.execute(
            sql.SQL(
                "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO {}"
            ).format(rol)
        )
        conexion.execute(
            sql.SQL("GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO {}").format(rol)
        )
        # Lo que las migraciones creen después también queda al alcance de la API.
        conexion.execute(
            sql.SQL(
                "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE"
                " ON TABLES TO {}"
            ).format(rol)
        )
        conexion.execute(
            sql.SQL(
                "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO {}"
            ).format(rol)
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--url", required=True)
    parser.add_argument("--clave", required=True)
    args = parser.parse_args()
    crear(args.url, args.clave)
    return 0


if __name__ == "__main__":
    sys.exit(main())
