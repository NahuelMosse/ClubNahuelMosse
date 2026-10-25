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

El APK apunta a la API desplegada en Render y a Firebase Authentication real. Hace falta:

- `API_URL`: la dirección pública de la API, `https://<servicio>.onrender.com` (la misma que
  `URL_PUBLICA` en Render).
- Los datos de la app Android registrada en el proyecto de Firebase. En la consola de Firebase,
  *Configuración del proyecto* → *General* → *Tus apps* → *Agregar app* → Android, con el nombre de
  paquete `ar.edu.unimoron.clubnahuelmosse`. De ahí salen `FIREBASE_PROJECT_ID` (ID del proyecto),
  `FIREBASE_SENDER_ID` (número del proyecto, «ID del remitente»), `FIREBASE_APP_ID` («ID de la app»,
  con la forma `1:<número>:android:<hash>`) y `FIREBASE_API_KEY` (la clave de API).

La app inicia Firebase con esas `--dart-define` (`lib/sesion/firebase.dart`), así que no usa el
plugin de Google Services: **no hace falta `google-services.json`** ni tocar los `build.gradle.kts`.
Sin `AUTH_EMULADOR`, la app usa el proyecto real.

```sh
cd apps/mobile
flutter build apk --release   --dart-define=API_URL=https://<servicio>.onrender.com   --dart-define=FIREBASE_API_KEY=<clave de API>   --dart-define=FIREBASE_APP_ID=<ID de la app>   --dart-define=FIREBASE_SENDER_ID=<ID del remitente>   --dart-define=FIREBASE_PROJECT_ID=<ID del proyecto>
```

`flutter build apk --debug` lleva las mismas `--dart-define`. Sin `API_URL` la app no arranca; sin
las cuatro de Firebase ni `AUTH_EMULADOR`, tampoco.

Para no repetirlas, se copian a un archivo local que git ignora y se pasan de una vez:

```sh
cd apps/mobile
cp definiciones.example.json definiciones.json   # y se completan los cinco valores
flutter build apk --release --dart-define-from-file=definiciones.json
```

El archivo queda en `build/app/outputs/flutter-apk/`. Se instala con
`adb install -r build/app/outputs/flutter-apk/app-release.apk` (o `app-debug.apk`). La versión
`release` queda firmada con la clave de depuración mientras no se configure una propia en
`android/app/build.gradle.kts`.

La API gratuita de Render se duerme tras 15 minutos sin tráfico: el primer inicio de sesión del día
puede tardar alrededor de un minuto. La app espera hasta 60 segundos por pedido y, pasados 5, avisa
que el servidor se está despertando. Antes de una demostración conviene abrir `<URL>/health` en el
navegador.

## Supuestos que limitan lo que muestra la app

Decisiones tomadas sin respuesta del cliente, que cambian lo que ve quien usa la app. Cada ID está
registrado en `specs/<card>/ambiguedades.md`; los demás supuestos de cada card están ahí.

- CU-13-SUP-07 · la fecha de una reserva se elige en el calendario, que ofrece los próximos 7 días
  (siete días), y las horas son en punto; la duración llega hasta 4 horas (CU-13-SUP-08).
- CU-09-SUP-02 · el administrador no reserva: la app no le ofrece la sección de reservas y una
  respuesta 403 lleva a «Acceso denegado».
- CU-21-SUP-04 · el catálogo de deportes y tipos es fijo: la app lo pide a la API y no permite
  editarlo.
- CU-12-SUP-05 · la app muestra el precio y el total de la reserva, pero no hay pagos ni
  reintegros.
- CU-12-SUP-02 · la grilla de horarios se lee al entrar y al cambiar cancha, fecha o duración, y
  no se refresca sola: si el horario se ocupa antes de confirmar, la API responde 409.
- CU-16-SUP-06 · las fotos de sedes y canchas son imágenes fijas de la app; el administrador no
  carga fotos.
- CU-24.1-SUP-10 · el centro de avisos se abre desde una campana en el Home del usuario; el
  administrador no tiene centro de avisos.
