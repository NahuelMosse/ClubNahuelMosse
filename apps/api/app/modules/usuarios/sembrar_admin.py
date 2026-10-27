"""Crea la primera cuenta de administrador, o promueve una existente.

    ADMIN_CONTRASENA=... uv run python -m app.modules.usuarios.sembrar_admin \\
        --correo admin@club.com --nombre Ana --apellido Díaz --dni 30111222 --nacimiento 1985-06-01

La contraseña llega por variable de entorno para que no quede en el historial de la terminal.
Si ya hay una cuenta con ese correo, sólo se asciende con `--promover` y conserva su contraseña.
"""

import argparse
import os
import sys
from datetime import datetime

from app.modules.usuarios.administradores import sembrar_admin
from app.modules.usuarios.reglas import DatosRegistro
from app.modules.usuarios.repositorio import UsuariosSql
from app.shared.club_timezone import CLUB_TIMEZONE as ZONA
from app.shared.db import engine
from app.shared.errors import AccountExists, Duplicate, InvalidData
from app.shared.identity import FirebaseProvider


def _leer(argumentos: list[str] | None) -> argparse.Namespace:
    lector = argparse.ArgumentParser(description=__doc__.splitlines()[0] if __doc__ else None)
    for campo in ("correo", "nombre", "apellido", "dni", "nacimiento"):
        lector.add_argument(f"--{campo}", required=True)
    lector.add_argument(
        "--promover", action="store_true", help="ascender la cuenta que ya tenga ese correo"
    )
    return lector.parse_args(argumentos)


def main(argumentos: list[str] | None = None) -> int:
    datos = _leer(argumentos)
    contrasena = os.environ.get("ADMIN_CONTRASENA", "")
    if not contrasena:
        print("Falta la variable de entorno ADMIN_CONTRASENA", file=sys.stderr)
        return 2

    with engine().connect() as conn:
        try:
            sembrar_admin(
                DatosRegistro(
                    nombre=datos.nombre,
                    apellido=datos.apellido,
                    dni=datos.dni,
                    fecha_nacimiento=datos.nacimiento,
                    correo=datos.correo,
                    contrasena=contrasena,
                ),
                hoy=datetime.now(ZONA).date(),
                identidad=FirebaseProvider(),
                usuarios=UsuariosSql(conn),
                promover=datos.promover,
            )
        except AccountExists:
            print(
                f"ya hay una cuenta con {datos.correo}; usá --promover para hacerla administradora",
                file=sys.stderr,
            )
            return 1
        except InvalidData as e:
            for campo, mensaje in e.errors.items():
                print(f"{campo}: {mensaje}", file=sys.stderr)
            return 1
        except Duplicate as e:
            print(f"ya hay otra cuenta activa con ese {' y '.join(e.fields)}", file=sys.stderr)
            return 1
    print(f"administrador listo: {datos.correo}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
