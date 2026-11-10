# ClubNahuelMosse — API

REST API for sports space bookings, in FastAPI with PostgreSQL. Firebase Authentication identifies
people and Firebase Cloud Messaging sends the notifications. The OpenAPI documentation is published
at `/docs` (Swagger) and `/openapi.json`.

## Requirements

- Python 3.12 or later and [uv](https://docs.astral.sh/uv/).
- PostgreSQL, with an empty database and a user that can create tables.
- For the tests: Node.js (the Firebase Auth emulator is installed with `npm ci` at the repo root).

## Configure

```sh
cd apps/api
uv sync
```

Configuration arrives through environment variables. `app/shared/config.py` also reads a local
`.env` file, which is not versioned; `.env.example` lists the variables. `FIREBASE_AUTH_EMULATOR_HOST`,
`GOOGLE_APPLICATION_CREDENTIALS`, `ADMIN_PASSWORD` and `TEST_DATABASE_URL` are read only from the
process environment: in the `.env` they have no effect.

| Variable | What it is |
|---|---|
| `DATABASE_URL` | PostgreSQL connection, `postgresql+psycopg://<user>:<password>@host:port/database`. By default, user, password and database `club` on `localhost:5432` |
| `FIREBASE_PROJECT_ID` | Identifier of the Firebase project that issues the tokens |
| `FIREBASE_API_KEY` | Web key of the project; the API uses it to check passwords. Not needed with the emulator |
| `PUBLIC_URL` (or `URL_PUBLICA`) | Public address of this API; the links in the emails point there |
| `EMAIL_MODE` (or `CORREO_MODO`) | `smtp` (default) sends emails over SMTP; `brevo` sends them through the Brevo API; `buzon` leaves them in the `correo_saliente` table and is only for development |
| `BREVO_API_KEY` | Key of the Brevo API; needed with `EMAIL_MODE=brevo` |
| `FIREBASE_CREDENTIALS_JSON` (or `FIREBASE_CREDENCIALES_JSON`) | Content of the Firebase service account JSON, an alternative to `GOOGLE_APPLICATION_CREDENTIALS` |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `EMAIL_SENDER` | Outgoing mail server with `EMAIL_MODE=smtp`; each is also read as `SMTP_PUERTO`, `SMTP_USUARIO`, `SMTP_CONTRASENA`, `CORREO_REMITENTE` |
| `E2E_TESTING` (or `PRUEBAS`) | `1` enables `/_testing`, which is mounted only if `FIREBASE_AUTH_EMULATOR_HOST` also exists; in a real environment it is not defined |
| `REMINDERS_EVERY` (or `RECORDATORIOS_CADA`) | How many seconds between the sweeps that send reminders; 30 by default, 0 turns it off |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to the Firebase service account file. In production this one or `FIREBASE_CREDENCIALES_JSON` is needed: without the emulator, the API needs it to create and delete users, verify tokens with `check_revoked` and send notifications through Firebase Cloud Messaging |
| `FIREBASE_CREDENCIALES_JSON` | The content of the service account JSON, for platforms that do not mount files (Render, with a Blueprint). If `GOOGLE_APPLICATION_CREDENTIALS` is also defined, the JSON wins |
| `FIREBASE_AUTH_EMULATOR_HOST` | `host:port` of the Firebase Auth emulator; with it the API does not use the real project |
| `ADMIN_PASSWORD` | Password of the admin account, only for the command that seeds it |
| `TEST_DATABASE_URL` | Database of the tests (its name ends in `_test`); only `conftest.py` in the tests folder reads it |
| `VERSION` | Version reported by `/health` and carried by every log line; by default it comes from `pyproject.toml` |

Create the tables in the `DATABASE_URL` database:

```sh
uv run alembic upgrade head
```

The admin account is not registered from the app; it is seeded:

```sh
ADMIN_PASSWORD=<password> uv run python -m app.modules.users.seed_admin \
  --correo <email> --nombre <first name> --apellido <last name> --dni <dni> --nacimiento YYYY-MM-DD
```

## Run

Locally, against the Firebase Auth emulator (from the repo root, in another terminal, `npm ci` the
first time and then `npm run emuladores`, which listens on port 9099):

```sh
cd apps/api
FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 FIREBASE_PROJECT_ID=demo-clubnahuelmosse \
  CORREO_MODO=buzon uv run uvicorn app.main:app --host 0.0.0.0 --port 8000
```

The documentation is at `http://localhost:8000/docs`. From the Android emulator the API is seen as
`http://10.0.2.2:8000`.

## Errors

422 for an invalid value (`{"errors": {field: message}}`); 403 and 404 without a body.

## Contract

`apps/api/openapi.json` is the versioned contract and a test compares it with the API. Regenerate it
after any change to routes or models:

```sh
cd apps/api
FIREBASE_AUTH_EMULATOR_HOST= uv run --no-sync python -c "import json, pathlib; from app.main import create_app; pathlib.Path('openapi.json').write_text(json.dumps(create_app().openapi(), indent=2, ensure_ascii=False) + '\n', encoding='utf-8')"
```

## Sports catalog

The catalog is fixed and lives in `app/modules/spaces/rules.py`; the app requests it with `GET /spaces/catalog`.
Sports and types: Fútbol (F5, F7, F8, F11), Tenis (PDL, CEM), Pádel (PAD), Vóley (IND, PLA), Básquet
(B5, 3X3), Hockey (H7) and Golf (DR, 9H). Decisions about Básquet:

- REV-05-ASM-01: Básquet has two types: "Básquet 5" (`B5`, full court) and "Básquet 3x3" (`3X3`, half court).
- REV-05-ASM-02: until there is a Básquet photo, the court takes cover 1 of the club, which belongs to no other sport.
- REV-05-ASM-03: Básquet goes after Vóley in the catalog.

## Test

With the Firebase Auth emulator up and a database whose name ends in `_test` (the suite drops
and recreates its schema):

```sh
# from the repo root
FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
DATABASE_URL=postgresql+psycopg://<user>:<password>@<host>:<port>/<database>_test \
TEST_DATABASE_URL=postgresql+psycopg://<user>:<password>@<host>:<port>/<database>_test \
  sh scripts/test.sh
```

`scripts/test.sh` runs from the repo root; it runs `ruff`, `mypy` and `pytest` of the API and
then `flutter analyze`, the format check and `flutter test` of the app. Only the API:

```sh
cd apps/api
uv run ruff check .
uv run mypy app
uv run pytest
uv run pytest tests/scenarios --card <ID>
```

Without the emulator (variable missing or emulator off) the run fails with "hace falta el emulador
de Firebase Auth" (the Firebase Auth emulator is required). `uv run pytest --sin-emulador` skips the
tests that use the API and runs the rest (the unit tests need neither a database nor the emulator);
the output counts the skipped ones as `skipped`.

## Operate

**Reminders without the web service.** The free service sleeps and the sweep sleeps with it. The
same sweep runs as a one-pass command, for a cron or a Render job to trigger:

```sh
cd apps/api
uv run python -m app.modules.notifications.sweep --una-vez
```

It exits with code 0 if the sweep ran and 1 if it failed. Who triggers it is not decided:
`render.yaml` does not add a paid job. A notification that was not sent leaves an error line
`aviso_sin_enviar` in the log, with the notification number and the error type, without the token.

**Logs.** A notification that was not sent leaves an error line `aviso_sin_enviar` in the log, with
the notification number and the error type, without the token.

## Data decisions

What was assumed where the requirement is silent (REV-03); each one changes in a single place.

- REV-03-ASM-02: a notification that has been `enviando` for more than 10 minutes (the API went
  down mid-send) becomes `fallida` in the next sweep and is not repeated ("sent only once",
  CU-24.1); SIM-01-ASM-10.
- REV-03-ASM-03: the own history (`GET /bookings`) returns all bookings at once, just like the
  global one; there is no cursor or batches.

## Deploy on Render

The `render.yaml` at the repo root describes everything: a Python web service for the API
(`apps/api`) and a managed Postgres database, both on the `free` plan. Render installs with `uv sync`
(it detects `uv.lock`), migrates with `alembic upgrade head` inside the build, starts `uvicorn` on the
`$PORT` it assigns and polls `/health` as the health check.

1. **Render account.** Create the account at <https://render.com> and authorize access to GitHub.
2. **Firebase project.** At <https://console.firebase.google.com> create a project
   and, inside it:
   - *Authentication* → *Sign-in method*: enable "Email/Password".
   - *Project settings* → *General*: note the **project ID** (`FIREBASE_PROJECT_ID`)
     and the **web API key** (`FIREBASE_API_KEY`).
   - *Project settings* → *Service accounts* → *Generate new private key*: a `.json` is
     downloaded. It is a secret: do not commit it to the repository.
3. **GitHub repository.** Push this repo (the `render.yaml` must be at the root of the
   branch Render will follow).
4. **Blueprint.** In Render: *New* → *Blueprint*, choose the repo and the branch, and confirm. Render
   creates `clubnahuelmosse-api` and `clubnahuelmosse-db` and asks for the values of the variables marked
   `sync: false`:

   | Variable | Value |
   |---|---|
   | `FIREBASE_PROJECT_ID`, `FIREBASE_API_KEY` | those of step 2 |
   | `FIREBASE_CREDENCIALES_JSON` | the **complete content** of the service account `.json` |
   | `URL_PUBLICA` | `https://<service name>.onrender.com`, the address Render shows for `clubnahuelmosse-api` |
   | `SMTP_HOST`, `SMTP_USUARIO`, `SMTP_CONTRASENA`, `CORREO_REMITENTE` | those of the outgoing mail account (`SMTP_PUERTO` is already 587) |

   Render asks for these values only when creating the Blueprint; to change them later, edit them in
   the service's *Environment*. `DATABASE_URL` comes from the database: `config.py` adds the `psycopg`
   driver to the `postgresql://` that Render provides. `PRUEBAS` and `FIREBASE_AUTH_EMULATOR_HOST`
   are not defined.
5. **Seed the admin**, once, from this machine against the Render database. In the
   database (*Connections* in the dashboard) copy the **External Database URL** and, from `apps/api`:

   ```sh
   DATABASE_URL=<External Database URL>    FIREBASE_PROJECT_ID=<project id> FIREBASE_API_KEY=<web key>    GOOGLE_APPLICATION_CREDENTIALS=<path to the downloaded .json>    ADMIN_PASSWORD=<password>    uv run python -m app.modules.users.seed_admin      --correo <email> --nombre <first name> --apellido <last name> --dni <dni> --nacimiento YYYY-MM-DD
   ```

6. **Check.** `https://<service>.onrender.com/openapi.json` returns the schema and
   `GET /venues` without a session answers 401. With the address in `API_URL_NUBE`, scenario
   RNF-01-H06-01 makes that check: `uv run pytest tests/scenarios --card RNF-01`.

Later deployments go out by themselves with every commit to the linked branch.

Limits of the `free` plan:

- The service sleeps after 15 minutes without traffic and the first request afterwards takes about
  a minute: wake it up before a demo. While it sleeps, the reminder sweep does not run.
- The free database expires 30 days after creation, with no automatic backups, and there is one per workspace.
- `preDeployCommand` does not exist on the free plan; that is why migrations run in the build.
  With a paid plan, move that part to `preDeployCommand` in `render.yaml`.

The app receives the address with `--dart-define=API_URL=<URL_PUBLICA>` when built; see the README of
`apps/mobile`.

To roll back a deployment, rotate a secret or handle an incident: `docs/technical/runbook.md`.

## Assumptions that limit what the API does

Decisions made without an answer from the client, which change what the person using the API sees or
what the person operating it does. Each ID is recorded in `specs/<card>/ambiguities.md`; the other
assumptions of each card are there.

- CU-13-SUP-08 · a booking lasts 1 to 4 hours, on the hour; the API rejects a duration
  shorter than one hour or longer than 4 hours.
- CU-13-SUP-07 · bookings are allowed only up to 7 days ahead (the next seven days) and at
  future times, in the club's time.
- CU-09-SUP-02 · the admin does not book: the API answers them 403. There is no cap on active
  bookings per user.
- CU-09-SUP-03 · if two people ask for the same time slot at once, one wins: the database exclusion
  constraint rejects the second with 409.
- CU-21-SUP-04 · the catalog of sports and space types is fixed, lives in the API code and
  is not edited from the app (today it does not include Básquet).
- CU-12-SUP-05 · the price is the space's, the same at every hour; the app shows it but there are no
  payments or refunds (CU-09-AMB-10, CU-10-AMB-08).
- CU-24.1-SUP-02 · the backend does not retry a failed push notification: it stays in the notification
  center as failed, and a token that Firebase rejects as invalid is removed.
- CU-01-SUP-02 · the API does not block failed sign-in attempts; only Firebase cuts them off
  (`TOO_MANY_ATTEMPTS`, answered as 429).
- CU-07-SUP-01 · a deactivated account frees its email and its DNI for a new account.
