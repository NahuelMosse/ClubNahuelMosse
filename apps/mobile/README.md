# ClubNahuelMosse — app móvil

App Flutter de reservas de espacios deportivos. Se conecta a la API de `apps/api` y usa Firebase
Authentication para iniciar sesión y Firebase Cloud Messaging para los avisos. Sólo se construye
para Android.

## Requisitos

- Flutter con Dart `^3.9.2` (`flutter doctor` sin errores para Android).
- Android SDK y un emulador o un teléfono con la depuración USB activa.
- La API de `apps/api` en marcha (ver su README), local o desplegada.

## Configurar

```sh
cd apps/mobile
flutter pub get
```

La app no lleva direcciones ni claves en el código: todo lo que cambia entre ambientes llega por
`--dart-define` al ejecutar o construir.

| Variable | Qué es |
|---|---|
| `API_URL` | Dirección base de la API, obligatoria. Con el emulador de Android y la API en la misma máquina, `http://10.0.2.2:<puerto>` |
| `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_SENDER_ID`, `FIREBASE_PROJECT_ID` | Datos de la app Android registrada en el proyecto de Firebase (consola de Firebase, configuración del proyecto). Obligatorias salvo con `AUTH_EMULADOR` |
| `AUTH_EMULADOR` | `host:puerto` del emulador de Firebase Auth. Si está, no hace falta proyecto de Firebase y los avisos son simulados |
| `PUSH` | `simulado` para no usar Firebase Cloud Messaging con un proyecto real |
| `AVISOS_SEGUNDOS` | Cada cuántos segundos la app abierta consulta avisos nuevos (20 por defecto; 2 con el emulador de Auth) |

El `applicationId` de Android es `ar.edu.unimoron.clubnahuelmosse` y el nombre en el dispositivo,
`ClubNahuelMosse`. El ícono sale de `assets/icono/icono.png`; si se cambia la imagen, se regenera
con `dart run flutter_launcher_icons`.

## Ejecutar

Contra el emulador de Firebase Auth y una API local (ver «Ejecutar» en el README de la API para
levantarlos):

```sh
flutter run --dart-define=API_URL=http://10.0.2.2:8000 --dart-define=AUTH_EMULADOR=10.0.2.2:9099
```

Contra la API desplegada y un proyecto real de Firebase:

```sh
flutter run \
  --dart-define=API_URL=<dirección pública de la API> \
  --dart-define=FIREBASE_API_KEY=<clave> \
  --dart-define=FIREBASE_APP_ID=<id de la app> \
  --dart-define=FIREBASE_SENDER_ID=<id del remitente> \
  --dart-define=FIREBASE_PROJECT_ID=<id del proyecto>
```

## Probar

```sh
flutter analyze
dart format --output=none --set-exit-if-changed lib test
flutter test
```

`sh scripts/test.sh`, desde la raíz del repo, corre además los chequeos y las pruebas de la API.

Los escenarios de pantalla (`integration_test/`) corren en un emulador de Android o un teléfono
conectado, con la API y el emulador de Firebase Auth que levanta el propio script:

```sh
# desde la raíz del repo
sh scripts/e2e.sh
sh scripts/e2e.sh integration_test/<área> --name "@<ID>-"
```

El script lee `AVD` (el emulador a arrancar si no hay dispositivo), `DISPOSITIVO`, `AUTH_PORT`,
`API_PORT` y `E2E_DATABASE_URL`; están descritas en su cabecera.

## Construir el APK

Con las mismas `--dart-define` que `flutter run`; sin `API_URL` la app no arranca:

```sh
flutter build apk --release   --dart-define=API_URL=<dirección pública de la API>   --dart-define=FIREBASE_API_KEY=<clave>   --dart-define=FIREBASE_APP_ID=<id de la app>   --dart-define=FIREBASE_SENDER_ID=<id del remitente>   --dart-define=FIREBASE_PROJECT_ID=<id del proyecto>
```

`flutter build apk --debug` lleva las mismas `--dart-define`.

El archivo queda en `build/app/outputs/flutter-apk/`. Se instala con
`adb install -r build/app/outputs/flutter-apk/app-debug.apk` (o `app-release.apk`). La versión
`release` queda firmada con la clave de depuración mientras no se configure una propia en
`android/app/build.gradle.kts`.
