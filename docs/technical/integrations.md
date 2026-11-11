# Integrations · ClubNahuelMosse

The external services the system uses, what each one is used for and in which repo files the integration is made.
Only variables are named, never their values. To operate them, the [runbook](runbook.md); for context, the
[architecture](architecture.md) and the [system design](system-design.md).

| Service | Used for | Where |
|---|---|---|
| Firebase Authentication | Registration, sign-in and password recovery | `apps/api/app/shared/identity.py`, `apps/mobile/lib/features/session/data/firebase.dart` |
| Firebase Cloud Messaging | Push notices to the phone | `apps/api/app/modules/notifications/push.py`, `apps/mobile/lib/features/notifications/presentation/fcm_notification_system.dart` |
| Brevo | Recovery, confirmation and reminder emails and notices | `apps/api/app/shared/email.py` |
| PostgreSQL on Render | All the data | `apps/api/app/shared/config.py`, `render.yaml` |
| Render | API hosting and deployment from `main` | `render.yaml` |
| API monitor | Keeping it awake | none in the repo (UptimeRobot, outside the code) |

## Firebase Authentication

**What it is used for.** Registration, sign-in, password change and recovery. The app signs in against
Firebase; the API verifies the token of each request and checks passwords with the web key of the project.

**Files.**
- API: `apps/api/app/shared/identity.py` (Firebase client and token verification),
  `apps/api/app/shared/firebase_credential.py` (service account), `apps/api/app/modules/session/current_user.py`
  (the person behind each request), `apps/api/app/modules/users/registration.py` (account creation).
- App: `apps/mobile/lib/features/session/data/firebase.dart`, `apps/mobile/lib/features/session/data/session_repository.dart`,
  `apps/mobile/lib/common/config.dart` (reads the build variables).
- Configuration: `firebase.json` (Auth emulator), `render.yaml`, `apps/mobile/definiciones.example.json`.

**Variables.**
- API: `FIREBASE_PROJECT_ID`, `FIREBASE_API_KEY`, `FIREBASE_CREDENTIALS_JSON`, `FIREBASE_AUTH_EMULATOR_HOST`.
- App (`--dart-define`): `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_SENDER_ID`, `FIREBASE_PROJECT_ID`,
  `AUTH_EMULATOR`.

Locally: the Auth emulator (`npm run emulators`) replaces Firebase and the app is started with `AUTH_EMULATOR`.

## Firebase Cloud Messaging

**What it is used for.** Push notices (the reminder one hour before and booking notices). The app registers the device
token in the API and the API sends the notice through FCM.

**Files.**
- API: `apps/api/app/modules/notifications/push.py` (sending through `firebase-admin`),
  `apps/api/app/modules/notifications/use_cases.py` (when it is delivered),
  `apps/api/app/modules/notifications/sweep.py` (the reminder clock),
  `apps/api/app/shared/firebase_credential.py`.
- App: `apps/mobile/lib/features/notifications/presentation/fcm_notification_system.dart` (permission, token and messages),
  `apps/mobile/lib/features/notifications/data/simulated_notification_system.dart` (the system without Firebase), `apps/mobile/lib/main.dart`,
  `apps/mobile/android/app/src/main/AndroidManifest.xml` (icon and color of the notifications).
- Configuration: `render.yaml`.

**Variables.**
- API: `FIREBASE_CREDENTIALS_JSON`; the sweep interval is `reminders_every` in `apps/api/app/shared/config.py`.
- App (`--dart-define`): `PUSH`, `FIREBASE_SENDER_ID`.

If it does not answer: without `FIREBASE_CREDENTIALS_JSON` the notice stays `no_channel`; if FCM fails, `failed` (the runbook, in
"no-reminders"). Locally there are no credentials and the push channel is the null one.

## Brevo

**What it is used for.** Outgoing email: password recovery link, booking confirmation, reminders and
notices. In production it goes out through the Brevo HTTP API, because free Render blocks outgoing SMTP. There are two
alternatives chosen with `EMAIL_MODE`: `smtp` (an own server) and `outbox` (stores the email in the table
`outgoing_email`, only for development and tests).

**Files.**
- API: `apps/api/app/shared/email.py` (the three modes and the sending), `apps/api/app/shared/email_template.py` (the HTML),
  `apps/api/app/modules/password_recovery/use_cases.py`, `apps/api/app/modules/bookings/email.py`,
  `apps/api/app/modules/notifications/rules.py` (the texts of each email).
- Configuration: `apps/api/app/shared/config.py`, `render.yaml`.

**Variables.** `EMAIL_MODE`, `BREVO_API_KEY`, `EMAIL_SENDER`, `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`,
`SMTP_PASSWORD`, `PUBLIC_URL` (the links in the emails point there).

If it does not answer: the log carries "the email could not be sent"; check the service variables (the runbook, in
"no-email").

## PostgreSQL on Render

**What it is used for.** The database of the whole system: members, venues, bookings, notices and emails. The API uses it with
SQLAlchemy and the Alembic migrations run in the build.

**Files.** `render.yaml` (the database `clubnahuelmosse-db`), `apps/api/app/shared/config.py` (the connection URL and the
driver), `apps/api/alembic.ini`.

**Variables.** `DATABASE_URL`. Render hands it to the API from the database; it is not written by hand.

If it does not answer: the runbook, in "database-down" (on the free plan the database expires after 30 days).

## Render

**What it is used for.** The hosting of the API (`clubnahuelmosse-api`, FastAPI) and the deployment: each commit to the
linked branch (`main`) deploys by itself, with the build, the migrations, the start and the health check.

**Files.** `render.yaml` (the Blueprint: build, start, `healthCheckPath` and environment variables),
`apps/api/README.md` (the first-time steps), `apps/api/app/main.py` (the application that starts).

**Variables.** `PYTHON_VERSION`, `PUBLIC_URL` and those of the other services, which `render.yaml` declares with
`sync: false` so they do not live in the repo.

If it does not answer: the free plan puts the service to sleep after 15 minutes and the first request takes about a minute
(the runbook, in "Deploy").

## Monitor that keeps the API awake

**What it is used for.** An UptimeRobot monitor calls `/health` every 5 minutes so Render does not put the API to sleep. That
lets the reminder sweep, which runs inside the process, send the notices on time.

**Files.** None in the repo: the monitor is configured in UptimeRobot and points to `/health`, which the API answers in
`apps/api/app/health.py`. The runbook describes it in `docs/technical/runbook.md`.

**Variables.** None.

If it does not answer: without the monitor the sweep does not run while Render puts the service to sleep (the runbook, in
"no-reminders").
