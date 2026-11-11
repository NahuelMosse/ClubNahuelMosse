# Code map · ClubNahuelMosse

Where everything is in the repo. The architecture (the pieces, how they talk and why) is in
[`architecture.md`](architecture.md); here go the folders, the files and what each one holds. Symbols are cited by
name, not by line: look them up with the editor's search.

## Where is…?

| I am looking for | It is in |
|---|---|
| The rules of a booking (1 to 4 hours, 7 days in view, venue schedule) | `apps/api/app/modules/availability/rules.py` (`validate_booking`, `duration_error`, `MIN_HOURS`, `MAX_HOURS`, `DAYS_IN_VIEW`) |
| That two bookings do not overlap | the `EXCLUDE USING gist` constraint of `apps/api/migrations/versions/0001_modelo_inicial.py`, and `BookingsSql.insert` in `apps/api/app/modules/bookings/repository.py`, which translates the `23P01` error to `SlotTaken` |
| The "book" use case | `apps/api/app/modules/bookings/use_cases.py` (`book`) |
| An HTTP route | `apps/api/app/modules/<feature>/routes.py`; the full table is in [API routes](#api-routes) |
| Who is admin and where it is checked | the role comes from the `app_user` table; every admin use case raises `Forbidden`; in the app, the `redirect` of `apps/mobile/lib/redirect.dart` only hides screens |
| How the Firebase token is validated | `apps/api/app/modules/session/current_user.py` (`current_user`) → `session/use_cases.py` (`authenticated_profile`) → `shared/identity.py` (`FirebaseProvider.uid_from_token`) |
| The club's time and time zone | API: `apps/api/app/shared/club_timezone.py` (`CLUB_TIMEZONE`); app: `apps/mobile/lib/common/club_timezone.dart` |
| The reminders one hour before | `apps/api/app/modules/notifications/sweep.py` (the clock) → `use_cases.py` (`send_reminders`, `deliver`) → `push.py` (FCM) |
| The cancellation notices | queued in the same transaction that cancels (`BookingsSql.cancel` and `BookingsSql.void`) and sent by `dispatch_pending` |
| The password recovery email | `apps/api/app/modules/password_recovery/use_cases.py` (code, validity, hourly cap); the sending (SMTP, Brevo or mailbox) is in `shared/email.py` |
| The API environment variables | `apps/api/app/shared/config.py`; the table is in [API configuration](#api-configuration) |
| The database engine and the per-request connection | `apps/api/app/shared/db.py` |
| The database schema | `apps/api/migrations/versions/0001` to `0012`; the explained model is in [`system-design.md`](system-design.md#data) |
| A screen of the app | `apps/mobile/lib/features/<feature>/presentation/<name>_screen.dart`; the full table is in [App routes](#app-routes) |
| The colors, fonts and theme | `apps/mobile/lib/theme/tokens.dart` (`Palette`) and `theme/theme.dart` |
| The animations and transitions | `apps/mobile/lib/common/motion.dart`, `common/motion/` and `common/transitions.dart` |
| The brand components (bib, die-cut, marker…) | `apps/mobile/lib/common/`; see [App components](#app-components) |
| How the app calls the API | `apps/mobile/lib/api/api_client.dart` (`ApiClient`) and `api/rutas.dart` (the allowed routes) |
| The error dialogs | `apps/mobile/lib/common/error_dialog.dart` (`handleNetworkError`) |
| The app's `--dart-define` values | `apps/mobile/lib/common/config.dart` |
| Push on the phone | `apps/mobile/lib/features/notifications/presentation/notification_center.dart` (`NotificationCenter`) and `fcm_notification_system.dart` |
| The requirement of each feature | `specs/<CU-NN-name>/card.snapshot.md` (the newer cards, `card.md`); the original use cases are outside the repo, in `../CU/` |
| Which test proves a scenario | search for its tag (`@CU-09-H02-02`, `@REV-01-S12`) in `apps/api/tests` and `apps/mobile` |
| How to run everything | `sh scripts/test.sh` (checks and tests) and `sh scripts/e2e.sh` (screens on the emulator) |

## The repo

```
app-tp/
├── apps/
│   ├── api/                 REST API: FastAPI + hand-written SQL on PostgreSQL
│   │   ├── app/             code: main.py, shared/ and modules/ (one folder per feature)
│   │   ├── migrations/      Alembic, 0001 to 0012
│   │   ├── tests/           unit, integration, scenarios
│   │   ├── openapi.json     the published contract, versioned (a test compares it with the API)
│   │   ├── pyproject.toml   dependencies (uv), ruff and mypy
│   │   └── README.md        configure, run, test and deploy the API
│   └── mobile/              Flutter app, Android only
│       ├── lib/             code, one folder per feature
│       ├── test/            widget, accessibility and capture tests
│       ├── integration_test/ scenarios on the emulator against the real API
│       ├── assets/          fonts, venue photos, icon
│       ├── android/         Android project (signing, deep link, icon)
│       └── README.md        --dart-define, run and build the APK
├── docs/
│   ├── technical/           architecture, this map, system design, runbook, costs
│   ├── adr/                 decisions: stack (0001) and hosting on Render (0002)
│   ├── business/            accessibility statement
│   └── screenshots/         the README captures
├── docs-site/               the documentation site (Docusaurus)
├── specs/                   one folder per card: requirement, assumptions, tests and closing
├── scripts/                 test.sh, e2e.sh
├── render.yaml              Render blueprint: the API and its database
├── firebase.json            Firebase Auth emulator (port 9099)
├── package.json             only for `npm run emulators` (firebase-tools)
└── .claude/                 the method kit (SDD): rules, agents, hooks and tools
```

## The API (`apps/api`)

### Structure

The code is grouped by feature: one folder per feature under `app/modules/`, flat, with the files it
needs among `routes.py` (HTTP), `use_cases.py` (orchestration), `rules.py` (pure rules) and `repository.py`
(SQL with `text()` on a SQLAlchemy `Connection`, no ORM). What is shared is in `app/shared/` and above it stay
`main.py`, `health.py` and `e2e_support.py`.

- A feature imports another only through its `__init__.py`, and there are no cycles.
- `shared/` imports no features; `rules.py` imports no database or web; use cases import neither
  `repository` nor `routes`.
- Routes receive the repository with `Depends` from the provider in their own `repository.py`
  (`bookings_repository`, …); a test replaces it with `app.dependency_overrides`. The commands (`sweep.py`,
  `seed_admin.py`) build their pieces themselves.
- Each repository writes only its own tables.

The tests `apps/api/tests/unit/test_architecture_features.py`, `test_layers_features.py`,
`test_api_clean_features.py` and `test_map_by_feature.py` enforce these rules.

### By feature

Files of each feature (under `apps/api/app/modules/<feature>/`) and the app folder under
`apps/mobile/lib/features/`:

| Feature | Files | App |
|---|---|---|
| `bookings` | `routes.py`, `use_cases.py`, `store.py`, `rules.py`, `repository.py`, `email.py` | `bookings/` |
| `availability` | `routes.py`, `use_cases.py`, `slots.py`, `rules.py`, `repository.py` | `bookings/` |
| `venues` | `routes.py`, `use_cases.py`, `rules.py`, `repository.py` | `venues/`, `admin/` |
| `spaces` | `routes.py`, `use_cases.py`, `rules.py`, `repository.py` | `spaces/`, `admin/` |
| `users` | `registration_routes.py`, `account_routes.py`, `registration.py`, `profile.py`, `password.py`, `deactivation.py`, `admins.py`, `seed_admin.py`, `rules.py`, `repository.py` | `users/` |
| `session` | `use_cases.py`, `profile.py`, `current_user.py`, `repository.py` | `session/` |
| `password_recovery` | `routes.py`, `use_cases.py`, `rules.py`, `repository.py` | `session/` |
| `notifications` | `routes.py`, `use_cases.py`, `store.py`, `rules.py`, `repository.py`, `sweep.py`, `push.py`, `email.py` | `notifications/` |

Shared in `app/shared/`: `config.py`, `db.py` (`engine`, `connection()`, `in_transaction`), `errors.py` (all the
business errors), `http_errors.py`, `responses.py`, `input_validation.py`, `body_limit.py`, `club_timezone.py` (`CLUB_TIMEZONE`),
`identity.py` (`FirebaseProvider`), `firebase_credential.py`, `email.py`, `message.py` and `email_template.py`.

### File by file

**Root of `app/`**

| File | What it holds |
|---|---|
| `main.py` | `create_app()`: builds the app, the error handlers and the routers; `_lifespan` (the background sweep) |
| `health.py` | `/health` (the process is alive) |
| `e2e_support.py` | `/_testing/*`: shortcuts for the e2e tests; mounted only with `E2E_TESTING=true` and the emulator |

**`shared/`**

| File | What it holds |
|---|---|
| `config.py` | `Settings` (pydantic-settings), reads the environment and the `.env` file of `apps/api` |
| `db.py` | `engine`, `connection()` (one connection per request), `DbConnection`, `in_transaction`, `violated_constraint` |
| `errors.py` | the business exceptions: `InvalidData`, `Duplicate`, `NotAuthenticated`, `RateLimited`, `AccountExists`, `Forbidden`, `Unavailable`, `NumberTaken`, `SlotTaken`, `NotFound`, `ConcurrentChange`, `BookingsOutsideHours`, `OpeningHoursChanged`, `HasFutureBookings` |
| `http_errors.py` | handlers for `InvalidData` (422 with `errors`), `Forbidden` (403) and `NotFound` (404), the same three across the whole API |
| `responses.py` | `conflict`: the 409 with `errors` that each route chooses |
| `input_validation.py` | bounded types for the bodies (`Texto40`, `Clave`, `Identifier`…), `parse_time` and the 422 and 400 handler |
| `body_limit.py` | `BodyLimit`: cap on the size and time of the body |
| `club_timezone.py` | `CLUB_TIMEZONE`, the only definition of `America/Argentina/Buenos_Aires` |
| `identity.py` | `FirebaseProvider`: verify tokens, check passwords, create and delete accounts |
| `firebase_credential.py` | `service_credential`: the service account from the JSON or the file |
| `email.py` | `send`: SMTP with verified STARTTLS, Brevo, or the development mailbox |
| `message.py` | `Message`: recipient, subject and body |
| `email_template.py` | `html_email`: the HTML template of the emails |

**`modules/`** (each `routes*.py` file holds the HTTP routes; `repository.py` the SQL and its `*_repository` provider)

| Feature | What it holds | Tables it writes |
|---|---|---|
| `session` | `Profile`, `authenticated_profile` (from the token to the `Profile`), `current_user` (the authentication dependency), `ProfilesSql` | — (reads `app_user`) |
| `users` | `register`, `update_profile`, `change_password`, `deactivate` (the account), `seed_admin` (and its command), registration and profile rules, `UsersSql` | `app_user` |
| `venues` | `active_venues`, `create_venue`, `update_venue`, `deactivate_venue`, `validate_venue`, `VenuesSql` | `venue` |
| `spaces` | the fixed catalog (`Sport`, `Kind`), `suggested_name`, creation, edit and removal of spaces, `SpacesSql` | `space` |
| `availability` | `OpeningHours`, `slot_grid`, `validate_booking`, `available_slots`, `available_spaces` (`slots.py`), `AvailabilitySql` (reads) | — |
| `bookings` | `book`, `my_bookings`, `cancel_booking`, `modify_booking`, `global_history`, `admin_detail`, `void_booking`, `BookingsSql` (history paginated by cursor) | `booking` |
| `notifications` | `LEAD_TIME` (1 h), `send_reminders`, `dispatch_pending`, devices and notification center, `NotificationsSql`, `push_channel` (`push.py`: `FcmChannel`, `NullChannel`), `sweep.py` (in process with `sweep_every` or one pass with `--una-vez`) | `notification`, `notification_booking`, `device` |
| `password_recovery` | `request_link`, `link_is_valid`, `use_link`, `hash_of`, `LinksSql` | `recovery_link`, `outgoing_email` (mailbox mode only) |

### API routes

"Session" means any account with a valid token. The admin routes ask for a session and the use case answers 403
if the role is not `admin`.

| Method and route | File | Use case | Who |
|---|---|---|---|
| GET `/health` | `health.py` | — | anyone |
| GET `/openapi.json` | FastAPI | — | anyone (also `/docs` and `/redoc`) |
| POST `/register` | `users/registration_routes.py` | `register` | anyone |
| POST `/password-recovery` | `password_recovery/routes.py` | `request_link` | anyone |
| POST `/password-recovery/check` | `password_recovery/routes.py` | `link_is_valid` | anyone |
| PUT `/password-recovery` | `password_recovery/routes.py` | `use_link` | anyone |
| GET `/link/recover` | `password_recovery/routes.py` | page that opens the app from the email | anyone |
| GET `/me` | `users/account_routes.py` | — | session |
| PUT `/me` | `users/account_routes.py` | `update_profile` | session |
| PUT `/me/password` | `users/account_routes.py` | `change_password` | session |
| DELETE `/me` | `users/account_routes.py` | `deactivate` | session |
| GET `/venues` | `venues/routes.py` | `active_venues` | session |
| POST `/venues` | `venues/routes.py` | `create_venue` | admin |
| PUT `/venues/{venue_id}` | `venues/routes.py` | `update_venue` | admin |
| DELETE `/venues/{venue_id}` | `venues/routes.py` | `deactivate_venue` | admin |
| GET `/spaces/catalog` | `spaces/routes.py` | `catalog` | session |
| GET `/spaces` | `spaces/routes.py` | `active_spaces` | session |
| GET `/spaces/name` | `spaces/routes.py` | `suggested_name` | admin |
| POST `/spaces` | `spaces/routes.py` | `create_space` | admin |
| PUT `/spaces/{space_id}` | `spaces/routes.py` | `update_space` | admin |
| DELETE `/spaces/{space_id}` | `spaces/routes.py` | `deactivate_space` | admin |
| GET `/spaces/{space_id}/slots` | `availability/routes.py` | `available_slots` | session |
| GET `/spaces/available` | `availability/routes.py` | `available_spaces` | session |
| GET `/bookings` | `bookings/routes.py` | `my_bookings` | session |
| POST `/bookings` | `bookings/routes.py` | `book` | user (admin: 403) |
| POST `/bookings/{booking_id}/cancel` | `bookings/routes.py` | `cancel_booking`, then dispatches the notice | user, only their own bookings (someone else's gives 404) |
| POST `/bookings/{booking_id}/modify` | `bookings/routes.py` | `modify_booking` | user |
| GET `/bookings/all` | `bookings/routes.py` | `global_history` | admin |
| GET `/bookings/all/{booking_id}` | `bookings/routes.py` | `admin_detail` | admin |
| POST `/bookings/{booking_id}/void` | `bookings/routes.py` | `void_booking`, then dispatches the notice | admin |
| PUT `/devices` | `notifications/routes.py` | `register_device` | user |
| POST `/devices/unregister` | `notifications/routes.py` | `deactivate_device` | session |
| GET `/notifications` | `notifications/routes.py` | `my_notifications` | session |
| POST `/notifications/read-all` | `notifications/routes.py` | `mark_all_read` | session |
| POST `/notifications/{notification_id}/read` | `notifications/routes.py` | `mark_read` | session |

### API configuration

`shared/config.py` reads these variables from the environment or from the `.env` file of `apps/api` (which is not versioned; `.env.example` lists them without values).

| Variable | Default | What for |
|---|---|---|
| `DATABASE_URL` | `postgresql+psycopg://club:club@localhost:5432/club` | the database; used by the API and the migrations |
| `FIREBASE_PROJECT_ID` | `demo-clubnahuelmosse` | the project that issues the tokens |
| `FIREBASE_API_KEY` | empty | check passwords over REST (the emulator does not need it) |
| `FIREBASE_CREDENTIALS_JSON` | empty | the service account; without it push stays on the null channel |
| `PUBLIC_URL` | `http://localhost:8000` | the host of the email links |
| `EMAIL_MODE` | `smtp` | `outbox` stores the emails in the `outgoing_email` table (development only) |
| `SMTP_HOST`, `SMTP_PORT` (587), `SMTP_USER`, `SMTP_PASSWORD`, `EMAIL_SENDER` | empty | the outgoing email (each also read under its Spanish name, see the API README) |
| `REMINDERS_EVERY` | 30 | seconds between sweeps; 0 turns the in-process sweep off |
| `E2E_TESTING` | false | mount `/_testing` (only together with the emulator) |
| `VERSION` | the one in `pyproject.toml` | what `/health` and the log report |

Outside `Settings`: `FIREBASE_AUTH_EMULATOR_HOST` (Auth emulator), `GOOGLE_APPLICATION_CREDENTIALS` (service account
by file), `ADMIN_PASSWORD` (only `seed_admin`) and `TEST_DATABASE_URL` (tests only).

### Migrations

| No. | What it does |
|---|---|
| 0001 | `app_user`, `venue`, `space`, `booking`, the `booking_with_status` view, the overlap exclusion and the logical-removal and immutability triggers |
| 0002 | `app_user.password_changed_at` |
| 0003 | `recovery_link` and `outgoing_email` |
| 0004 | venue name unique among the active ones |
| 0005 | `device`, `notification` and the index of active bookings by start |
| 0006 | send states and one cancellation notice per booking |
| 0007 | `notification_booking` (grouped notices), `count` and `replaced_by` |
| 0008 | history indexes created with `CONCURRENTLY`, and attempts and taken-at columns to resume stranded notices |
| 0009 | drops the attempts and taken-at columns (notices are not retried), adds `sending_since` and the ones that were `sending` become `failed` |
| 0010 | `uuid` identifiers with `uuid_v7()` and audit columns |
| 0011 | the five-minute reminder (`five_minute_reminder`) |
| 0012 | the schema in English: tables, columns, constraints, indexes, triggers, functions, the view and the stored values |

They are run with `uv run alembic upgrade head` from `apps/api`. A migration that is already in `main` is not edited: another
one is added.

### API tests

| Folder | What it covers | Needs |
|---|---|---|
| `apps/api/tests/unit/` | domain rules, use cases with doubles, the layer rules and the configuration | nothing |
| `apps/api/tests/integration/` | each area over HTTP (`test_<area>_api.py`), database constraints and protected routes | `*_test` database and Auth emulator |
| `apps/api/tests/scenarios/` | the scenarios of each card, with its tag in the name (`@CU-09-H02-02`, `@REV-01-S12`), the published contract, the migrations and `render.yaml` | `*_test` database and Auth emulator |

`apps/api/tests/conftest.py` requires the database to end in `_test`, recreates it from scratch with Alembic once per run and wraps
each test in a transaction that is discarded. To run only one card: `uv run pytest tests/scenarios --card <ID>`.

## The app (`apps/mobile`)

### How it is built

- **One folder per feature** under `lib/features/` (`session`, `users`, `home`, `venues`, `spaces`, `bookings`, `notifications`,
  `admin`), each with `data/`, `domain/` and `presentation/`, plus `api` (the HTTP client), `theme` (colors and typography), `common`
  (shared components and utilities) and `l10n` (the Spanish and English texts).
- **No third-party state manager.** Each feature has a repository (`VenuesRepository`, `SpacesRepository`, `BookingsApi`,
  `AvailabilityApi`, `NotificationsRepository`, `SessionRepository`, `PasswordRecovery`) over a single `ApiClient`. `_AppState` creates them in `app.dart` and passes them by
  constructor to each screen, which is a `StatefulWidget` with `setState`. The ones that change on their own (`Session`,
  `NotificationCenter`, `Appearance`) are `ChangeNotifier`s.
- **Navigation with `go_router`**, all the routes in `router.dart`, with a global per-role `redirect` in `redirect.dart`.
- `test/architecture_test.dart` watches the structure.

### File by file

**Root of `lib/`**

| File | What it holds |
|---|---|
| `main.dart` | `main()` and `bootstrap()`: error capture, Firebase, client, session, push, appearance; resumes the session with `resumeWithRetry` and launches `App` |
| `app.dart` | `App`: creates the repositories, listens for taps on push notifications and builds `MaterialApp.router` with the router from `router.dart` |
| `router.dart` | `AppRouter`: all the GoRouter routes, one method per section (session, home, venues, bookings, admin) |
| `redirect.dart` | `redirectByRole`: where each route goes depending on whether there is a session and the role |

**`api/`**

| File | What it holds |
|---|---|
| `api_client.dart` | `ApiClient` (get, post, put, delete), the response and the errors `SinConexion`, `ErrorDelServidor`, `ServidorSinRespuesta`; the per-request cut |
| `rutas.dart` | the list of API routes the app may request; in debug, a request to an undeclared route fails |

**`features/session/`**

| File | What it holds |
|---|---|
| `domain/profile.dart`, `domain/role.dart` | `Profile`, `Role` |
| `domain/session_exceptions.dart`, `domain/recovery_exceptions.dart` | `InvalidCredentials`, `SessionExpired`, `DataRejected`, `PasswordRejected`, `InvalidLink`, `EmailRejected` |
| `domain/token_source.dart` | `TokenSource`, what the API client asks for the token |
| `data/session_repository.dart` | `SessionRepository` (sign in, resume, refresh, edit profile, change password, deactivate, sign out, `token()`) |
| `data/credentials.dart` | `FirebaseCredentials` |
| `data/firebase.dart` | `initFirebase`, with the emulator if `AUTH_EMULATOR` is set |
| `data/password_recovery.dart` | `PasswordRecovery`, the repository of the three steps |
| `presentation/session.dart` | `Session`, the `ChangeNotifier` the router listens to |
| `presentation/login_screen.dart` | the login |
| `presentation/forgot_password_screen.dart` | ask for the recovery email |
| `presentation/new_password_screen.dart` | the new password from the email link |
| `presentation/access_denied_screen.dart` | what a user sees who reaches an admin route |
| `presentation/account_card.dart` | the account button and card, sign-out |
| `presentation/load_failure.dart`, `request_failure.dart` | the notices for a failed load and a failed send |

**`features/users/`**: `presentation/registration_screen.dart`, `presentation/registration_done_screen.dart`, `data/registration_service.dart` (`RegistrationService`),
`domain/registration_rules.dart` (name, DNI, birth date, email and password rules), `presentation/my_profile_screen.dart` (data, edit, dark mode, account removal) and `presentation/change_password_screen.dart`.

**`features/home/`**: `presentation/home_screen.dart`, the Home: marker, next booking, sports and shortcuts.

**`features/venues/`**

| File | What it holds |
|---|---|
| `domain/venue.dart` | `Venue`, `OpenDays` (`open_days.dart`) |
| `data/venues_repository.dart` | `VenuesRepository` |
| `domain/venue_exceptions.dart` | `VenueRejected`, `VenueUnavailable`, `VenueHasBookings`, `BookingsOutsideHours` |
| `presentation/venues_screen.dart` | the list, with `venue_card.dart` |
| `presentation/venue_screen.dart` | a venue with its courts, filters and `space_card.dart` |
| `presentation/photos.dart` | cover and sport photo helpers |

**`features/spaces/`**: `domain/space.dart` (`Space`, `Sport`, `SpaceKind`, `Catalog`), `data/spaces_repository.dart` (repository),
`domain/space_exceptions.dart` and `presentation/sport_icons.dart`.

**`features/bookings/`**

| File | What it holds |
|---|---|
| `domain/booking.dart`, `domain/booking_status.dart` | `Booking`, `BookingStatus` |
| `data/bookings_api.dart` | `BookingsApi` (repository) and its errors |
| `data/availability_api.dart` | `AvailabilityApi` (repository), `domain/availability_grid.dart` (`AvailabilityGrid`), `domain/slot.dart` (`Slot`) |
| `domain/booking_choice.dart` | `BookingChoice`: what was chosen before confirming; travels in the route's `extra` |
| `presentation/availability_screen.dart` | the grid of a court (also to modify a booking) |
| `presentation/confirm_booking_screen.dart` | the summary before booking |
| `presentation/confirm_change_screen.dart` | the summary before modifying |
| `presentation/booking_confirmed_screen.dart` | the celebration with the receipt |
| `presentation/my_bookings_screen.dart` | upcoming and history, with `booking_card.dart` |
| `presentation/space_search_screen.dart` | search by sport, day and time |
| `domain/search_rules.dart` | the search time-range rules |
| `presentation/cancellation.dart`, `presentation/change_slot.dart` | cancel with notices, open the modification |

**`features/notifications/`**

| File | What it holds |
|---|---|
| `presentation/notification_center.dart` | `NotificationCenter`: registers the device, polls while the app is open and tracks the unread ones |
| `data/notifications_repository.dart` | `NotificationsRepository` |
| `domain/app_notification.dart` | `AppNotification`, `noticeRoute` (where tapping a notice leads) |
| `domain/notification_system.dart`, `data/simulated_notification_system.dart` | the system interface (`NoticeTapped`) and `SimulatedNotificationSystem` |
| `presentation/fcm_notification_system.dart` | permission, token, notices tapped with the app closed or in the background |
| `presentation/bell_button.dart`, `notice_panel.dart`, `notice_card.dart`, `notifications_screen.dart` | the bell, the overlay panel, the card and the notifications screen |

**`features/admin/`**

| File | What it holds |
|---|---|
| `presentation/admin_panel_screen.dart` | everyone's bookings, by tabs |
| `presentation/booking_detail_screen.dart` | the detail with traceability |
| `presentation/booking_filters_screen.dart` | the filters panel |
| `data/booking_history_api.dart` | `BookingHistory` (paginated repository), filters and counters (`domain/history_filters.dart`, `domain/counters.dart`) |
| `presentation/void_booking.dart`, `void_booking_dialog.dart` | void with a reason |
| `presentation/admin_venues_screen.dart`, `venue_form_screen.dart`, `venue_created_screen.dart`, `venue_deactivation.dart` | venues |
| `presentation/admin_spaces_screen.dart`, `new_space_screen.dart`, `edit_space_screen.dart`, `space_created_screen.dart`, `space_deactivation.dart` | spaces |
| `presentation/deactivation.dart` | what the two removals share |
| `presentation/admin_listing.dart`, `booking_status_chip.dart` | pieces of the listings |

**`theme/`**: `tokens.dart` (`Palette`, a `ThemeExtension` with `bg*`, `text*`, `border*`, `accent*`, `state*` roles; light and dark palettes) and `theme.dart` (the dark and light themes).

**`common/`**

| Group | Files |
|---|---|
| Startup and errors | `config.dart` (`--dart-define`), `unhandled_errors.dart`, `error_dialog.dart`, `snackbar.dart`, `appearance.dart` |
| Navigation and motion | `bottom_bar.dart`, `top_bar.dart`, `transitions.dart`, `motion.dart`, `motion/` |
| Forms | `button.dart`, `text_field.dart`, `selector.dart`, `calendar.dart`, `missing_fields.dart`, `password_form.dart`, `date_format.dart`, `price_format.dart` |
| Brand | `logo_mark.dart`, `marker.dart`, `sport_tile.dart`, `member_profile.dart`, `day_timeline.dart`, `bib.dart`, `die_cut.dart` |
| Other widgets | `avatar.dart`, `empty_state.dart`, `label.dart`, `badge.dart`, `card_frame.dart`, `result.dart` (the result screen), `booking_card.dart` |
| Logic without a screen | `club_timezone.dart`, `clock.dart`, `pending_booking.dart` (the booking left pending if the session expired) |

### App routes

All in `lib/router.dart`. "Forward" enters from the right; "root" changes without animation (the tabs); "result" fades.

| Route | Screen | Transition | Who |
|---|---|---|---|
| `/` | `LoginScreen` | root | anyone |
| `/registro` | `RegistrationScreen` | forward | anyone |
| `/registro/exitoso` | `RegistrationDoneScreen` | result | anyone |
| `/recuperar-contrasena` | `ForgotPasswordScreen` | forward | anyone |
| `/recuperar?codigo=` | `NewPasswordScreen` (link `clubnahuelmosse://app/recuperar`) | forward | anyone |
| `/inicio` | `HomeScreen` | root | user |
| `/inicio/buscar` | `SpaceSearchScreen` | forward | user |
| `/notificaciones` | `NotificationsScreen` | forward | user |
| `/perfil` | `MyProfileScreen` | root | user |
| `/perfil/contrasena` | `ChangePasswordScreen` | forward | user |
| `/sedes` | `VenuesScreen` | root | user |
| `/sedes/:sede` | `VenueScreen` | forward | user |
| `/sedes/:sede/canchas/:cancha` | `AvailabilityScreen` | forward | user |
| `/sedes/:sede/canchas/:cancha/reservar` | `ConfirmBookingScreen` (asks for the `BookingChoice` in `extra`) | forward | user |
| `/reservar` | `ConfirmBookingScreen` for the booking left pending after signing in again | forward | user |
| `/reservas` | `MyBookingsScreen` | root | user |
| `/reservas/:reserva/modificar` | `AvailabilityScreen` in modify mode | forward | user |
| `/reservas/:reserva/modificar/confirmar` | `ConfirmChangeScreen` | forward | user |
| `/reservas/confirmada` | `BookingConfirmedScreen` | result | user |
| `/admin` | `AdminPanelScreen` | root | admin |
| `/admin/reserva/:id` | `BookingDetailScreen` | forward | admin |
| `/admin/acceso-denegado` | `AccessDeniedScreen` | forward | anyone with a session |
| `/admin/sedes` | `AdminVenuesScreen` | root | admin |
| `/admin/sedes/nueva` and `/admin/sedes/:sede/editar` | `VenueFormScreen` | forward | admin |
| `/admin/sedes/creada` | `VenueCreatedScreen` | result | admin |
| `/admin/espacios` | `AdminSpacesScreen` | root | admin |
| `/admin/espacios/nuevo` | `NewSpaceScreen` | forward | admin |
| `/admin/espacios/:espacio/editar` | `EditSpaceScreen` | forward | admin |
| `/admin/espacios/creado` | `SpaceCreatedScreen` | result | admin |

- **The `redirect`**: without a session, everything that is not public goes back to `/`. A user on `/admin/…` goes to
  `/admin/acceso-denegado`; an admin on a user route goes to their home.
- **Routes with `extra`** (confirm, modify, detail, the "created" screens) go back to their list if opened without
  it, for example from a link or when reopening the app.
- **The tabs** are not a `ShellRoute`: each root screen places its `BottomBar` (user: Home, Venues, Bookings,
  Profile) or `AdminBar` (Bookings, Venues, Spaces) and navigates with `context.go`.

### App configuration

`lib/common/config.dart` reads the `--dart-define` values:

| Define | What for |
|---|---|
| `API_URL` | the address of the API; required (the Android emulator sees the machine at `http://10.0.2.2:8000`) |
| `AUTH_EMULATOR` | `host:port` of the Firebase Auth emulator; with it the Firebase keys are not needed and push is simulated |
| `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_SENDER_ID`, `FIREBASE_PROJECT_ID` | the real Firebase project; required without `AUTH_EMULATOR` |
| `PUSH` | `simulated` forces the fake push |
| `NOTIFICATION_POLL_SECONDS` | how often it polls for notices with the app open (20 s; 2 s with the emulator) |

### App components

| Component | File | Where it is used |
|---|---|---|
| Logo mark | `common/logo_mark.dart` | login, member card |
| Marker | `common/marker.dart` | home, member card |
| Sport tile | `common/sport_tile.dart` | home |
| Member card | `common/member_profile.dart` | profile |
| Day timeline | `common/day_timeline.dart` | availability |
| Giant bib | `common/bib.dart` | venues, member card |
| Die-cut | `common/die_cut.dart` | my bookings, booking confirmed |
| Result screen | `common/result.dart` | venue and space created, new password, recovery |
| Celebration | `common/motion/celebration.dart` | booking confirmed |
| Fade-in, staggered entrance, shake, success pulse, heartbeat, pressable | `common/motion/` | screen entrances, form errors, confirmations, buttons |
| Dialog frame | `common/error_dialog.dart` | all the dialogs |

The durations and curves are in `common/motion/timings.dart`. With the system's "remove animations"
(`MediaQuery.disableAnimationsOf`), everything lasts zero.

### App tests

| Folder | What it covers | How it runs |
|---|---|---|
| `test/` | screens and flows with the fake API: book, cancel, modify, admin, session, network errors, accessibility | `flutter test` |
| `test/redesign/` | palette, brand components, transitions and motion | `flutter test` |
| `test/admin/` | the admin panel and detail | `flutter test` |
| `test/screenshots/` | captures of each screen at 360 and 430 px, light and dark, to compare with the Figma; they assert nothing | `flutter test --update-goldens test/screenshots/<file>_screenshots.dart` |
| `integration_test/` | the use case scenarios on the Android emulator, against the real API and the Auth emulator | `sh scripts/e2e.sh [integration_test/<area>]` |

Helpers in `test/support/`:

- `mount.dart`: `apiRutas`, a fake API that answers by route and records the requests, and `montar`.
- `fixed_clock.dart`: a `testWidgets` with the clock frozen on Thursday 12/11/2026 at 15:00 club time.
- `user.dart` and `admin.dart`: mount the app with a user or admin session, with sample data.

In `integration_test/support/`, `actions.dart` has `abrirApp`, `entrarComoUsuario` and `entrarComoAdmin`, and `network.dart`
has an intermediate API to simulate drops.

## Scripts (`scripts/`)

| Script | What it does |
|---|---|
| `test.sh` | ruff, mypy and pytest of the API; `flutter analyze`, `dart format` and `flutter test` of the app |
| `e2e.sh` | starts the Auth emulator and the API on its own `*_test` database, migrates, seeds an admin and runs `integration_test` on the Android emulator |

API commands: `python -m app.modules.users.seed_admin` (create or promote the first administrator) and
`python -m app.modules.notifications.sweep --una-vez` (one pass of reminders and notices).

## `specs/` and the way of working

Each feature is a **card** with its folder in `specs/`:

| Prefix | What they are |
|---|---|
| `CU-NN` | the use cases of the assignment (sign in, book, void…) |
| `RNF-01`, `MOD-01`, `TP-NN` | non-functional requirements, data model and specific requests of the practical assignment |
| `REV-NN`, `INT-01` | the corrections of the review in `specs/REVISION-kit3.md` and their integration |
| `RED-NN` | the redesign: palette, components, screens and motion |

The folders have two formats, depending on the version of the method the card was made with:

| Cards | Files |
|---|---|
| `CU-NN`, `RNF-01`, `MOD-01`, `TP-NN` | `card.snapshot.md` (the frozen requirement), `ambiguedades.md` (doubts and assumptions), `plan.md` and `tasks.md` (the tasks with their tests); `MOD-01` adds `data-model.md` |
| `REV-NN`, `INT-01`, `RED-NN` | `card.md` (requirement, scenarios `S1…`, assumptions `ASM-NN`, tasks with their tests and the log), `ambiguities.md`, `risk.json`, `judge.md` (the plan review at high risk) and `closing.md` (the closing: what happened and what could not run) |

`specs/TRAZABILIDAD.md` crosses the use cases with their tests and `specs/asvs.md` is the security matrix. The method is in
`.claude/METHOD.md` and the stack with its commands in `.claude/STACK.md`.
