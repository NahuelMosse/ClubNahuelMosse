# ClubNahuelMosse — mobile app

Flutter app to book sports spaces. It connects to the API in `apps/api` and uses Firebase
Authentication to sign in and Firebase Cloud Messaging for notifications. It is built for Android
only.

## Requirements

- Flutter with Dart `^3.9.2` (`flutter doctor` with no Android errors).
- Android SDK and an emulator or a phone with USB debugging on.
- The API in `apps/api` running (see its README), local or deployed.

## Configure

```sh
cd apps/mobile
flutter pub get
```

The app carries no addresses or keys in its code: everything that changes between environments
arrives through `--dart-define` when running or building.

| Variable | What it is |
|---|---|
| `API_URL` | Base address of the API, required. With the Android emulator and the API on the same machine, `http://10.0.2.2:<port>` |
| `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_SENDER_ID`, `FIREBASE_PROJECT_ID` | Data of the Android app registered in the Firebase project (Firebase console, project settings). Required unless `AUTH_EMULADOR` is set |
| `AUTH_EMULADOR` | `host:port` of the Firebase Auth emulator. When set, no Firebase project is needed and notifications are simulated |
| `PUSH` | `simulado` to skip Firebase Cloud Messaging with a real project |
| `AVISOS_SEGUNDOS` | How often, in seconds, the open app polls for new notifications (20 by default; 2 with the Auth emulator) |

The Android `applicationId` is `ar.edu.unimoron.clubnahuelmosse` and the name on the device is
`ClubNahuelMosse`. The icon comes from `assets/icono/icono.png`; if the image changes, regenerate it
with `dart run flutter_launcher_icons`.

## Run

Against the Firebase Auth emulator and a local API (see "Ejecutar" in the API README to start
them):

```sh
flutter run --dart-define=API_URL=http://10.0.2.2:8000 --dart-define=AUTH_EMULADOR=10.0.2.2:9099
```

Against the deployed API and a real Firebase project:

```sh
flutter run \
  --dart-define=API_URL=<public address of the API> \
  --dart-define=FIREBASE_API_KEY=<key> \
  --dart-define=FIREBASE_APP_ID=<app id> \
  --dart-define=FIREBASE_SENDER_ID=<sender id> \
  --dart-define=FIREBASE_PROJECT_ID=<project id>
```

## Test

```sh
flutter analyze
dart format --output=none --set-exit-if-changed lib test
flutter test
```

`sh scripts/test.sh`, from the repo root, also runs the API checks and tests.

The screen scenarios (`integration_test/`) run on an Android emulator or a connected phone, with the
API and the Firebase Auth emulator that the script itself starts:

```sh
# from the repo root
sh scripts/e2e.sh
sh scripts/e2e.sh integration_test/<area> --name "@<ID>-"
```

The script reads `AVD` (the emulator to start if there is no device), `DISPOSITIVO`, `AUTH_PORT`,
`API_PORT` and `E2E_DATABASE_URL`; they are described in its header.

## Build the APK

The APK points at the API deployed on Render and at the real Firebase Authentication. It needs:

- `API_URL`: the public address of the API, `https://<service>.onrender.com` (the same as
  `URL_PUBLICA` on Render).
- The data of the Android app registered in the Firebase project. In the Firebase console,
  *Project settings* → *General* → *Your apps* → *Add app* → Android, with the package name
  `ar.edu.unimoron.clubnahuelmosse`. From there come `FIREBASE_PROJECT_ID` (project ID),
  `FIREBASE_SENDER_ID` (project number, "sender ID"), `FIREBASE_APP_ID` ("app ID", shaped
  `1:<number>:android:<hash>`) and `FIREBASE_API_KEY` (the API key).

The app starts Firebase with those `--dart-define` values (`lib/features/session/data/firebase.dart`),
so it does not use the Google Services plugin: **no `google-services.json` is needed** and the
`build.gradle.kts` files stay as they are. Without `AUTH_EMULADOR`, the app uses the real project.

```sh
cd apps/mobile
flutter build apk --release   --dart-define=API_URL=https://<service>.onrender.com   --dart-define=FIREBASE_API_KEY=<API key>   --dart-define=FIREBASE_APP_ID=<app ID>   --dart-define=FIREBASE_SENDER_ID=<sender ID>   --dart-define=FIREBASE_PROJECT_ID=<project ID>
```

`flutter build apk --debug` takes the same `--dart-define` values. Without `API_URL` the app does
not start; without the four Firebase ones or `AUTH_EMULADOR`, neither.

To avoid repeating them, copy them to a local file that git ignores and pass them all at once:

```sh
cd apps/mobile
cp definiciones.example.json definiciones.json   # and fill in the five values
flutter build apk --release --dart-define-from-file=definiciones.json
```

The file ends up in `build/app/outputs/flutter-apk/`. Install it with
`adb install -r build/app/outputs/flutter-apk/app-release.apk` (or `app-debug.apk`). The `release`
build is signed with the debug key until you configure your own in
`android/app/build.gradle.kts`.

The free Render API sleeps after 15 minutes without traffic: the first sign-in of the day can take
about a minute. The app waits up to 60 seconds per request and, after 5, tells the user that the
server is waking up. Before a demo, open `<URL>/health` in the browser.

## Assumptions that limit what the app shows

Decisions made without an answer from the client, which change what the person using the app sees.
Each ID is recorded in `specs/<card>/ambiguities.md`; the other assumptions of each card are there.

- CU-13-SUP-07 · the booking date is picked in the calendar, which offers the next 7 days
  (seven days), and times are on the hour; the duration goes up to 4 hours (CU-13-SUP-08).
- CU-09-SUP-02 · the admin does not book: the app does not offer them the bookings section and a
  403 response leads to "Access denied".
- CU-21-SUP-04 · the catalog of sports and types is fixed: the app asks the API for it and does
  not allow editing it.
- CU-12-SUP-05 · the app shows the price and the total of the booking, but there are no payments or
  refunds.
- CU-12-SUP-02 · the time grid is read on entering and when the court, date or duration change, and
  does not refresh by itself: if the slot is taken before confirming, the API answers 409.
- CU-16-SUP-06 · the photos of venues and courts are fixed images of the app; the admin does not
  upload photos.
- CU-24.1-SUP-10 · the notification center opens from a bell on the user's Home; the admin has no
  notification center.
