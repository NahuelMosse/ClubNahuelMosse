# ADR-0001: FastAPI with PostgreSQL for the API, Flutter for the app and Firebase for identity

## Status

`accepted` · 2026-09-27 · NahuelMosse (repo author). Date of the commits that built each piece: the API in d13f90d and the app in
c55abec, both of 2026-09-27.

## Problem and requirement

The assignment asks for a mobile app in Flutter, a REST API documented with Swagger/OpenAPI (free language,
"preferably Python"), a relational database ("preferably PostgreSQL") and Firebase for authentication and push
notices. The constraints are a team of one person, no budget and delivery within one term. The requirements that
demand it are RNF-01 (non-functional requirements) and the use cases of session, bookings and notices.

## Alternatives

### Alternative A — FastAPI, SQLAlchemy, Alembic and PostgreSQL; Flutter; Firebase Authentication and Cloud Messaging

| Axis | Answer |
|---|---|
| Meets the requirement | yes: the API publishes `/openapi.json` and `/docs` (`apps/api/README.md`), the app is Flutter (`apps/mobile/pubspec.yaml`), the database is PostgreSQL and Firebase identifies and notifies. The no-overlap constraint on bookings is solved in the database with `btree_gist` (`apps/api/migrations/versions/0001_modelo_inicial.py:170-171`) |
| Deployment ease | one `render.yaml` describes the API and the database; the build installs with `uv` and migrates with Alembic (`render.yaml:11`). Firebase is a managed service |
| Monthly infra cost | today USD 0 with the free plans of Render and Firebase Authentication; the paid alternatives are in `docs/technical/infra-cost.md` |
| Cost to operate | dependency patches by hand (no update bot, finding 25); no backups on the free database (finding 4); Firebase is not operated |
| Corrective maintenance cost | the author knows the stack, it is reproduced locally with Postgres and the Firebase Auth emulator (`firebase.json`), and all three have a large community. There are 384 API tests and 416 app tests that run locally (review, "What ran") |
| Lock-in and exit | the data is standard Postgres; the API is REST with OpenAPI. Leaving Firebase Authentication requires migrating the accounts and passwords (`app_user.firebase_uid` is the join key) and replacing the token verification (`apps/api/app/shared/identity.py`) |

### Alternative B — Django REST Framework with own authentication (users and passwords in the database) and push notices with another service

| Axis | Answer |
|---|---|
| Meets the requirement | in part: it meets Python, OpenAPI and PostgreSQL, but the assignment names Firebase for authentication and push notifications, and an own identity forces storing passwords, recovering accounts and issuing tokens |
| Deployment ease | a single service and one database, like A, without depending on Firebase for identity |
| Monthly infra cost | the same Render web service and database as A; the cost of another push service was not calculated (`not verified`) |
| Cost to operate | storing, rotating and protecting the password hashes, sending emails and the attempt limit would be operated by the author |
| Corrective maintenance cost | Django is the best-known Python framework and brings an ORM and migrations; the author did not evaluate it with a trial (`not verified`) |
| Lock-in and exit | lower than A for identity; the cost of the rest was not measured |

## Decision and why

Alternative A was chosen. What decided it was the assignment, which names Flutter, Python, PostgreSQL and Firebase, and the cost of operating
an own identity, which the author avoided. The coupling to Firebase for accounts, tokens and
notices is accepted as a cost, along with the SDK accepting unsigned tokens if the environment defines `FIREBASE_AUTH_EMULATOR_HOST` (finding 25). It is reviewed if
Firebase stops being free for the volume of the club or if the assignment changes provider. The infrastructure numbers
are in `docs/technical/infra-cost.md`; the current state of the system, in `docs/technical/system-design.md`.
