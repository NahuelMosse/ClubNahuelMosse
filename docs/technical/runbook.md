# Runbook · ClubNahuelMosse

For whoever operates the API on Render and did not write it. Short sentences, commands you paste, symptoms before causes. What
was not run on Render says `not verified`: the deployment on Render has not been made yet (scenario RNF-01-H06-01 is
skipped without `API_URL_NUBE`). Finding numbers refer to the review of the `kit-3` branch (`specs/REVISION-kit3.md`).
The architecture is in [`architecture.md`](architecture.md), the system design in
[`system-design.md`](system-design.md) and the costs in [`infra-cost.md`](infra-cost.md).

Owner: pending a person · Last review: pending a person (reviewed by someone who did not write it)

## Deploy

The source of the configuration is `render.yaml`, at the root of the repo. Render reads it as a Blueprint and creates the web service
`clubnahuelmosse-api` and the database `clubnahuelmosse-db`. The first-time steps (account, Firebase project, Blueprint,
seeding the administrator) are in "Deploy on Render" of `apps/api/README.md`.

Each commit to the linked branch deploys by itself. On each deployment Render runs, in `apps/api`:

1. Build: `uv sync --frozen --no-dev && uv run --no-sync alembic upgrade head`. **The migrations run here, against the
   real database**, while the previous version is still serving: if they fail, the deployment does not go out and the service stays on the
   previous version. Each migration runs in its own transaction and those that create indexes on tables with data do so with
   `CONCURRENTLY` and `lock_timeout`, so they do not block the serving version.
2. Start: `uv run --no-sync uvicorn app.main:app --host 0.0.0.0 --port $PORT`.
3. Health check: `GET /health`, which answers 200 while the process is alive.

How to tell it finished: the service status in the Render dashboard changes to "Live" (`not verified`: no deployment was
made), `GET /health` returns the deployed version. Minimal check of the API:
`GET /venues` without a session answers 401. On the free plan the first request after sleeping takes about a minute.

The API on the Render free plan sleeps after 15 minutes without traffic. An UptimeRobot monitor calls `/health` every
5 minutes to keep it awake, and that is what lets the in-process sweep send the reminders;
the monitor has to point at `/health`.

## Roll back

**Code.** There is no command of its own: the previous commit is deployed again. Two paths, in this order of preference:

1. `git revert <bad commit>` and push to the linked branch: Render deploys the revert with the same build as above.
2. In the service dashboard, deploy a previous commit by hand (`not verified`: the dashboard was not used).

**Data.** The `free` database has no automatic copies, expires after 30 days and is deleted 14 days later: there is no rollback of
data.

**Migrations.** The build runs `alembic upgrade head`, but there is no rollback command in the deployment. If the previous commit
does not carry the latest migration, Alembic complains about a revision it does not know and the build fails (known
Alembic behavior, not rehearsed against Render: `not verified`). Rolling a migration back is done by hand, against the
database **External Database URL**, from `apps/api`: `DATABASE_URL=<External Database URL> uv run alembic downgrade -1`.
Three downgrades delete tables with data and must not be run on a database in real use: 0003 (`outgoing_email`,
`recovery_link`), 0005 (`notification`, `device`) and 0007 (`notification_booking` and the columns `count` and
`replaced_by`). 0008 and 0009 downgrade without losing bookings.

How to confirm the previous version is serving: the deployment status in the dashboard, `GET /health` with the previous version and
the behavior that had broken.

## Diagnose

First look, in this order:

1. `GET https://<service>.onrender.com/health`: if it answers, the web process is alive; it carries the version. If it takes about
   a minute, it was asleep (free plan).
2. `GET /venues` without a session: 401 is normal.
3. The service log in the Render dashboard (`not verified`).
4. The database: `psql "<External Database URL>" -c "select 1"` (`not verified`: `psql` was not tried against Render).

## Alerts, by symptom

There are no alerts defined and no `runbook_url`. What follows is by symptom, for whoever sees it in the app or in the log.

### database-down: the app says it could not connect

- **What the user sees:** the network error notice with a retry.
- **Confirm:** `/health` answers but the screens fail; the log carries `OperationalError` errors.
- **Mitigate:** check that the database has not expired (30 days on the free plan) and its status in the Render dashboard.
- **Verify:** `GET /venues` with a session answers 200.
- **Escalate:** if the database expired, its data is lost after the 14-day grace period: create a new database and migrate it.

### old-schema: errors on screens that use new tables or columns

- **What the user sees:** errors on the screens that use new tables or columns.
- **Confirm:** the database is not on the latest migration (`alembic current` against the database).
- **Mitigate:** run `DATABASE_URL=<External Database URL> uv run alembic upgrade head` from `apps/api`, or redeploy.
- **Verify:** the screens answer.
- **Escalate:** if the migration fails, to whoever wrote the migration, with the error.

### no-reminders: the one-hour-before notices do not arrive

- **What the user sees:** no push notice before the slot; in the notice center of the app the notice does appear when
  the API is awake.
- **Confirm:** the sweep runs inside the web process every `REMINDERS_EVERY` seconds and does not run while Render puts
  the service to sleep. In the `notification` table, the `delivery` of the notice says what happened: `no_permission` (the person gave no permission),
  `no_channel` (`FIREBASE_CREDENTIALS_JSON` is missing), `failed` (FCM failed; the log carries `aviso_sin_enviar` with the notice
  number).
- **Mitigate:** trigger the sweep from outside with `uv run python -m app.modules.notifications.sweep --una-vez` (for example, with an external
  cron), or keep the service awake in the hour before the slots.
- **Verify:** the notice changes to `sent`.
- **Escalate:** the underlying fix is a cron that calls the sweep; the Render free plan has no cron jobs.

### no-email: the recovery email does not arrive

- **What the user sees:** asks to recover the password and the link never arrives; the response is the same as for an email
  with no account.
- **Confirm:** the log carries "the email could not be sent" with the subject and the error type (without the address); the timeout is
  10 s and the server certificate is verified. Check `SMTP_HOST`, `SMTP_USER`, `SMTP_PASSWORD` and
  `EMAIL_SENDER` in the service *Environment*.
- **Mitigate:** fix the variable and deploy again; if the password of the mail account changed, see "Secret
  rotation and revocation".
- **Verify:** ask for recovery with a test account and receive the email.
- **Escalate:** to whoever administers the outgoing mail account.

### too-many-requests: sign-in answers 429

- **What the user sees:** is asked to wait before trying again.
- **Confirm:** sign-in answered `TOO_MANY_ATTEMPTS`: Firebase cuts it, the API does not limit requests.
- **Mitigate:** wait.
- **Verify:** sign-in works again.
- **Escalate:** if it persists, check the status of Firebase Authentication.

## Support view

Whoever operates searches the Render log for the error line. Pending a person: support levels, who has access to the
log and audit of those accesses.

## Escalation matrix

| Severity | Support level | Who | Channel | In how long | Data package passed |
|---|---|---|---|---|---|
| all | pending a person | pending a person | pending a person | pending a person | UTC time, route, what was expected, what happened, steps to repeat it |

## Incidents

An incident is declared if the user sees it and it is not solved by one of the sections above, if another person is needed,
or if it is still unsolved after an hour. On declaring it, three roles are named (who leads, who communicates and who
takes notes; they can be the same person) and a living document is opened with a timeline in UTC: what was seen, what was
done and at what time. First the damage is stopped (go back to the previous commit, turn the sweep off with `REMINDERS_EVERY=0`) and
then the cause is sought. On closing it, a blameless postmortem is written: impact, timeline, cause and actions with an
owner. Where it is noted and who leads is a decision pending a person.

## Communication

Four states, with a short text for each: Investigating, Identified, Monitoring, Resolved. First message 5
minutes after declaring the incident, updates at least every 20 minutes in the first two hours, always with the time of the
next one. The closing says whether there was data loss. Through which channel members and administrators are told is not decided:
pending a person.

## Secret rotation and revocation

Inventory with names and places, without values: `## Secrets inventory` of `docs/technical/system-design.md`. On Render they live
as *Environment* variables of the service; changing one requires deploying again. Owners, frequency and rotation
dates: pending a person.

| Secret | How it is rotated | How to check the old value no longer works |
|---|---|---|
| `FIREBASE_CREDENTIALS_JSON` | Firebase console → *Project settings* → *Service accounts* → *Generate new private key*; paste the whole JSON into the variable; deploy; delete the old key from the service account in Google Cloud | the API starts and verifies tokens with the new key; the old key no longer appears in the service account (`not verified` in the console) |
| `SMTP_PASSWORD` | Change it at the mail provider and then in the variable; deploy | ask for recovery on a test account and receive the email; the provider rejects the old password |
| `FIREBASE_API_KEY` | Create a new key in Google Cloud (project credentials), change the API variable and build the APK again with the new `--dart-define=FIREBASE_API_KEY`: the key travels inside the app | the new app signs in; deleting the old key leaves the old installations without service |
| `DATABASE_URL` | The database hands it out through `fromDatabase` in `render.yaml`. How to change its password: `not verified`, the Render procedure was not consulted | the migrations run with the new one and the old one fails in `psql` |
| `ADMIN_PASSWORD` | Only seeds the account. To change it, the administrator uses "Recover password" (CU-04-SUP-02) | sign in with the new password; the old one gives an error |

On a leak, in this order: revoke everything exposed in the same operation, issue the replacement, deploy, check the old
value fails (401 or 403), clean the place of the leak, review the use of the secret in the exposed window and leave it
recorded. Deleting the commit or restarting the API revokes nothing. To cut the sessions of an account, its password is
changed: the API revokes its refresh tokens when it changes (`FirebaseProvider.change_password` in
`apps/api/app/shared/identity.py`) and verifies each token with `check_revoked=True`. There is no command to revoke the
sessions of all accounts at once.

There is no secret scanner as a pre-commit hook nor a secret manager per environment: today the repo only avoids versioning the
`.env` (`apps/api/.env.example` has no values).

## Security incident response

Phases: detect, contain, eradicate, recover and postmortem. **Detect:** today there are no alerts; it is detected by a report, by
the Render log. **Contain:** rotate what was exposed with the previous section and, if needed, turn the service off
from the Render dashboard. **Eradicate and recover:** fix the cause, deploy and check. Who decides whether personal data was
involved (national ID, birth date, email, device token: `## Personal data` of the system design) and
whether the people or the authority must be told under Law 25.326 is decided before it happens: pending a person;
the text of the law was not consulted (`not verified`). Every leak is documented even if it is not notified, and the postmortem
stays blameless, with impact, timeline, causes and actions with an owner.
