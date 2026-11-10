"""Creates the first admin account, or promotes an existing one.

    ADMIN_PASSWORD=... uv run python -m app.modules.users.seed_admin \\
        --email admin@club.com --first-name Ana --last-name Díaz --dni 30111222 \\
        --birth-date 1985-06-01

The password arrives through an environment variable so it does not stay in the terminal history.
If that email already has an account, it is only promoted with `--promote`; the password stays.
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
    for option in ("email", "first-name", "last-name", "dni", "birth-date"):
        parser.add_argument(f"--{option}", required=True)
    parser.add_argument(
        "--promote", action="store_true", help="promote the account that already has that email"
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse(argv)
    password = os.environ.get("ADMIN_PASSWORD", "")
    if not password:
        print("The ADMIN_PASSWORD environment variable is missing", file=sys.stderr)
        return 2

    with engine().connect() as conn:
        try:
            seed_admin(
                RegistrationData(
                    first_name=args.first_name,
                    last_name=args.last_name,
                    dni=args.dni,
                    birth_date=args.birth_date,
                    email=args.email,
                    password=password,
                ),
                today=datetime.now(CLUB_TIMEZONE).date(),
                identity=FirebaseProvider(),
                users=UsersSql(conn),
                promote=args.promote,
            )
        except AccountExists:
            print(
                f"an account with {args.email} already exists; "
                "use --promote to make it an administrator",
                file=sys.stderr,
            )
            return 1
        except InvalidData as e:
            for field, message in e.errors.items():
                print(f"{field}: {message}", file=sys.stderr)
            return 1
        except Duplicate as e:
            fields = " and ".join(e.fields)
            print(f"another active account already has that {fields}", file=sys.stderr)
            return 1
    print(f"administrator ready: {args.email}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
