# Integraciones · ClubNahuelMosse

Los servicios externos que usa el sistema, para qué se usa cada uno y en qué archivos del repo se hace la integración.
Sólo se nombran variables, nunca sus valores. Para operarlos, el [runbook](runbook.md); para el contexto, la
[arquitectura](arquitectura.md) y el [diseño del sistema](system-design.md).

| Servicio | Para qué | Dónde |
|---|---|---|
| Firebase Authentication | Registro, inicio de sesión y recuperación de contraseña | `apps/api/app/shared/identity.py`, `apps/mobile/lib/sesion/firebase.dart` |
| Firebase Cloud Messaging | Avisos push al teléfono | `apps/api/app/modules/notifications/push.py`, `apps/mobile/lib/notificaciones/sistema_fcm.dart` |
| Brevo | Correos de recuperación, confirmación, recordatorio y avisos | `apps/api/app/shared/email.py` |
| PostgreSQL en Render | Todos los datos | `apps/api/app/shared/config.py`, `render.yaml` |
| Render | Hosting de la API y despliegue desde `main` | `render.yaml` |
| Monitor de la API | Mantenerla despierta | ninguno en el repo (UptimeRobot, fuera del código) |

## Firebase Authentication

**Para qué se usa.** Registro, inicio de sesión, cambio y recuperación de contraseña. La app inicia sesión contra
Firebase; la API verifica el token de cada pedido y comprueba contraseñas con la clave web del proyecto.

**Archivos.**
- API: `apps/api/app/shared/identity.py` (cliente de Firebase y verificación de tokens),
  `apps/api/app/shared/firebase_credential.py` (cuenta de servicio), `apps/api/app/modules/session/current_user.py`
  (la persona de cada pedido), `apps/api/app/modules/users/registration.py` (alta de la cuenta).
- App: `apps/mobile/lib/sesion/firebase.dart`, `apps/mobile/lib/sesion/sesion.dart`,
  `apps/mobile/lib/comun/configuracion.dart` (lee las variables de compilación).
- Configuración: `firebase.json` (emulador de Auth), `render.yaml`, `apps/mobile/definiciones.example.json`.

**Variables.**
- API: `FIREBASE_PROJECT_ID`, `FIREBASE_API_KEY`, `FIREBASE_CREDENCIALES_JSON`, `FIREBASE_AUTH_EMULATOR_HOST`.
- App (`--dart-define`): `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_SENDER_ID`, `FIREBASE_PROJECT_ID`,
  `AUTH_EMULADOR`.

En local: el emulador de Auth (`npm run emuladores`) reemplaza a Firebase y la app se arranca con `AUTH_EMULADOR`.

## Firebase Cloud Messaging

**Para qué se usa.** Los avisos push (recordatorio de una hora antes y avisos de la reserva). La app registra el token
del dispositivo en la API y la API manda el aviso por FCM.

**Archivos.**
- API: `apps/api/app/modules/notifications/push.py` (envío por `firebase-admin`),
  `apps/api/app/modules/notifications/use_cases.py` (cuándo se entrega),
  `apps/api/app/modules/notifications/sweep.py` (el reloj de los recordatorios),
  `apps/api/app/shared/firebase_credential.py`.
- App: `apps/mobile/lib/notificaciones/sistema_fcm.dart` (permiso, token y mensajes),
  `apps/mobile/lib/notificaciones/sistema_simulado.dart` (el sistema sin Firebase), `apps/mobile/lib/main.dart`,
  `apps/mobile/android/app/src/main/AndroidManifest.xml` (ícono y color de las notificaciones).
- Configuración: `render.yaml`.

**Variables.**
- API: `FIREBASE_CREDENCIALES_JSON`; el intervalo del barrido es `reminders_every` en `apps/api/app/shared/config.py`.
- App (`--dart-define`): `PUSH`, `FIREBASE_SENDER_ID`.

Si no responde: sin `FIREBASE_CREDENCIALES_JSON` el aviso queda `sin_canal`; si FCM falla, `fallida` (el runbook, en
«sin-recordatorios»). En local no hay credenciales y el canal push es el nulo.

## Brevo

**Para qué se usa.** El correo saliente: enlace de recuperación de contraseña, confirmación de reserva, recordatorios y
avisos. En producción sale por la API HTTP de Brevo, porque Render gratis bloquea el SMTP saliente. Hay dos
alternativas elegidas con `CORREO_MODO`: `smtp` (un servidor propio) y `buzon` (guarda el correo en la tabla
`correo_saliente`, sólo para desarrollo y pruebas).

**Archivos.**
- API: `apps/api/app/shared/email.py` (los tres modos y el envío), `apps/api/app/shared/email_template.py` (el HTML),
  `apps/api/app/modules/password_recovery/use_cases.py`, `apps/api/app/modules/bookings/email.py`,
  `apps/api/app/modules/notifications/rules.py` (los textos de cada correo).
- Configuración: `apps/api/app/shared/config.py`, `render.yaml`.

**Variables.** `CORREO_MODO`, `BREVO_API_KEY`, `CORREO_REMITENTE`, `SMTP_HOST`, `SMTP_PUERTO`, `SMTP_USUARIO`,
`SMTP_CONTRASENA`, `URL_PUBLICA` (los enlaces de los correos apuntan ahí).

Si no responde: el log trae «no se pudo enviar el correo»; revisar las variables del servicio (el runbook, en
«sin-correo»).

## PostgreSQL en Render

**Para qué se usa.** La base de datos de todo el sistema: socios, sedes, reservas, avisos y correos. La API la usa con
SQLAlchemy y las migraciones de Alembic corren en el build.

**Archivos.** `render.yaml` (la base `clubnahuelmosse-db`), `apps/api/app/shared/config.py` (la URL de conexión y el
driver), `apps/api/alembic.ini`.

**Variables.** `DATABASE_URL`. Render la entrega a la API desde la base; no se escribe a mano.

Si no responde: el runbook, en «base-caida» (en el plan free la base vence a los 30 días).

## Render

**Para qué se usa.** El hosting de la API (`clubnahuelmosse-api`, FastAPI) y el despliegue: cada commit a la rama
enlazada (`main`) despliega solo, con el build, las migraciones, el arranque y el health check.

**Archivos.** `render.yaml` (el Blueprint: build, arranque, `healthCheckPath` y variables de entorno),
`apps/api/README.md` (los pasos de la primera vez), `apps/api/app/main.py` (la aplicación que arranca).

**Variables.** `PYTHON_VERSION`, `URL_PUBLICA` y las de los demás servicios, que `render.yaml` declara con
`sync: false` para que no vivan en el repo.

Si no responde: el plan free duerme el servicio tras 15 minutos y el primer pedido tarda alrededor de un minuto
(el runbook, en «Deploy»).

## Monitor que mantiene despierta la API

**Para qué se usa.** Un monitor de UptimeRobot llama a `/health` cada 5 minutos para que Render no duerma la API. Eso
permite que el barrido de recordatorios, que corre dentro del proceso, mande los avisos a tiempo.

**Archivos.** Ninguno en el repo: el monitor se configura en UptimeRobot y apunta a `/health`, que responde la API en
`apps/api/app/health.py`. El runbook lo describe en `docs/technical/runbook.md`.

**Variables.** Ninguna.

Si no responde: sin el monitor no corre el barrido mientras Render duerme el servicio (el runbook, en
«sin-recordatorios»).
