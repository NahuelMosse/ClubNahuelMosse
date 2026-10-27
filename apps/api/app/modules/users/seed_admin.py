"""Creates the first admin account, or promotes an existing one.

    ADMIN_PASSWORD=... uv run python -m app.modules.users.seed_admin \\
        --correo admin@club.com --nombre Ana --apellido Díaz --dni 30111222 --nacimiento 1985-06-01

The password arrives through an environment variable so it does not stay in the terminal history.
If that email already has an account, it is only promoted with `--promover`; the password stays.
"""

import argparse
import os
import sys
from datetime import datetime

from app.modules.users.admins import seed_admin
from app.modules.users.repository import UsersSql
from app.modules.users.rules import RegistrationData
from app.shared.club_timezone import CLUB_TIMEZONE
from app.shared.db import engine
from app.shared.errors import AccountExists, Duplicate, InvalidData
from app.shared.identity import FirebaseProvider


def _parse(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0] if __doc__ else None)
    for option in ("correo", "nombre", "apellido", "dni", "nacimiento"):
        parser.add_argument(f"--{option}", required=True)
    parser.add_argument(
        "--promover", action="store_true", help="ascender la cuenta que ya tenga ese correo"
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse(argv)
    password = os.environ.get("ADMIN_PASSWORD") or os.environ.get("ADMIN_CONTRASENA", "")
    if not password:
        print("Falta la variable de entorno ADMIN_PASSWORD", file=sys.stderr)
        return 2

    with engine().connect() as conn:
        try:
            seed_admin(
                RegistrationData(
                    first_name=args.nombre,
                    last_name=args.apellido,
                    dni=args.dni,
                    birth_date=args.nacimiento,
                    email=args.correo,
                    password=password,
                ),
                today=datetime.now(CLUB_TIMEZONE).date(),
                identity=FirebaseProvider(),
                users=UsersSql(conn),
                promote=args.promover,
            )
        except AccountExists:
            print(
                f"ya hay una cuenta con {args.correo}; usá --promover para hacerla administradora",
                file=sys.stderr,
            )
            return 1
        except InvalidData as e:
            for field, message in e.errors.items():
                print(f"{field}: {message}", file=sys.stderr)
            return 1
        except Duplicate as e:
            print(f"ya hay otra cuenta activa con ese {' y '.join(e.fields)}", file=sys.stderr)
            return 1
    print(f"administrador listo: {args.correo}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
