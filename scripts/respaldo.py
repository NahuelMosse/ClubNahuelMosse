"""Copia de seguridad de la base y vuelta atrás.

    python scripts/respaldo.py guardar   --url <url> --archivo club.dump
    python scripts/respaldo.py restaurar --url <url de una base vacía> --archivo club.dump

Usa pg_dump y pg_restore (formato custom). Si no están en el PATH, `RESPALDO_PREFIJO` trae el
comando que los antecede, por ejemplo `docker exec -i mi-postgres`; en ese caso
`RESPALDO_HOST_INTERNO` (host:puerto) es como se ve la base desde ese lugar. El archivo se
escribe y se lee siempre en esta máquina, por la entrada y la salida estándar.
"""

import argparse
import os
import shlex
import shutil
import subprocess
import sys
from urllib.parse import urlsplit, urlunsplit


def _url_libpq(url: str, host_interno: str | None) -> str:
    partes = urlsplit(url)
    esquema = partes.scheme.split("+")[0]
    red = partes.netloc
    if host_interno:
        credenciales = red.rpartition("@")[0]
        red = f"{credenciales}@{host_interno}" if credenciales else host_interno
    return urlunsplit((esquema, red, partes.path, partes.query, ""))


def _comando(herramienta: str) -> list[str]:
    prefijo = shlex.split(os.environ.get("RESPALDO_PREFIJO", ""))
    if prefijo:
        return [*prefijo, herramienta]
    if shutil.which(herramienta) is None:
        sys.exit(
            f"No se encontró {herramienta}. Instalá las herramientas cliente de PostgreSQL o "
            "definí RESPALDO_PREFIJO (por ejemplo `docker exec -i <contenedor>`)."
        )
    return [herramienta]


def guardar(url: str, archivo: str) -> int:
    comando = [*_comando("pg_dump"), "--format=custom", "--no-owner", "--dbname", url]
    with open(archivo, "wb") as salida:
        corrida = subprocess.run(comando, stdout=salida, stderr=subprocess.PIPE, check=False)
    if corrida.returncode != 0:
        os.remove(archivo)
        sys.stderr.write(corrida.stderr.decode("utf-8", "replace"))
    return corrida.returncode


def restaurar(url: str, archivo: str) -> int:
    comando = [*_comando("pg_restore"), "--no-owner", "--exit-on-error", "--dbname", url]
    with open(archivo, "rb") as entrada:
        corrida = subprocess.run(comando, stdin=entrada, stderr=subprocess.PIPE, check=False)
    if corrida.returncode != 0:
        sys.stderr.write(corrida.stderr.decode("utf-8", "replace"))
    return corrida.returncode


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("accion", choices=["guardar", "restaurar"])
    parser.add_argument("--url", required=True)
    parser.add_argument("--archivo", required=True)
    args = parser.parse_args()
    url = _url_libpq(args.url, os.environ.get("RESPALDO_HOST_INTERNO"))
    accion = guardar if args.accion == "guardar" else restaurar
    return accion(url, args.archivo)


if __name__ == "__main__":
    sys.exit(main())
