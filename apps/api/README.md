# ClubNahuelMosse — API

API REST de reservas de espacios deportivos, en FastAPI con PostgreSQL. Firebase Authentication
identifica a las personas y Firebase Cloud Messaging manda los avisos. La documentación OpenAPI se
publica en `/docs` (Swagger) y `/openapi.json`.

## Requisitos

- Python 3.12 o posterior y [uv](https://docs.astral.sh/uv/).
- PostgreSQL, con una base vacía y un usuario que pueda crear tablas.
- Para los tests: Node.js (el emulador de Firebase Auth se instala con `npm ci` en la raíz del repo).

## Configurar

```sh
cd apps/api
uv sync
```

La configuración llega por variables de entorno (o un archivo `.env` local, que no se versiona):

| Variable | Qué es |
|---|---|
| `DATABASE_URL` | Conexión a PostgreSQL, `postgresql+psycopg://usuario:contraseña@host:puerto/base`. Por defecto, `postgresql+psycopg://club:club@localhost:5432/club` |
| `FIREBASE_PROJECT_ID` | Identificador del proyecto de Firebase que emite los tokens |
| `FIREBASE_API_KEY` | Clave web del proyecto; la API la usa para comprobar contraseñas. No hace falta con el emulador |
| `URL_PUBLICA` | Dirección pública de esta API; los enlaces de los correos apuntan ahí |
| `CORREO_MODO` | `smtp` (por defecto) envía los correos; `buzon` los deja en la tabla `correo_saliente` y sólo sirve para desarrollo |
| `SMTP_HOST`, `SMTP_PUERTO`, `SMTP_USUARIO`, `SMTP_CONTRASENA`, `CORREO_REMITENTE` | Servidor de correo saliente con `CORREO_MODO=smtp` |
| `PRUEBAS` | `1` habilita `/_pruebas`, que sólo se monta si además existe `FIREBASE_AUTH_EMULATOR_HOST`; en un ambiente real no se define |
| `RECORDATORIOS_CADA` | Cada cuántos segundos el barrido manda los recordatorios; 30 por defecto, 0 lo apaga |
| `GOOGLE_APPLICATION_CREDENTIALS` | Ruta a un archivo de cuenta de servicio de Firebase; con él la API manda avisos por Firebase Cloud Messaging, sin él no los envía |
| `FIREBASE_AUTH_EMULATOR_HOST` | `host:puerto` del emulador de Firebase Auth; con él la API no usa el proyecto real |
| `ADMIN_CONTRASENA` | Contraseña de la cuenta de administrador, sólo para el comando que la siembra |

Crear las tablas en la base de `DATABASE_URL`:

```sh
uv run alembic upgrade head
```

La cuenta de administrador no se registra desde la app; se siembra:

```sh
ADMIN_CONTRASENA=<contraseña> uv run python -m app.interfaz.sembrar_admin \
  --correo <correo> --nombre <nombre> --apellido <apellido> --dni <dni> --nacimiento AAAA-MM-DD
```

## Ejecutar

Local, contra el emulador de Firebase Auth (desde la raíz del repo, en otra terminal, `npm ci` la
primera vez y después `npm run emuladores`, que escucha en el puerto 9099):

```sh
cd apps/api
FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 FIREBASE_PROJECT_ID=demo-clubnahuelmosse \
  CORREO_MODO=buzon uv run uvicorn app.main:app --host 0.0.0.0 --port 8000
```

La documentación queda en `http://localhost:8000/docs`. Desde el emulador de Android la API se ve
como `http://10.0.2.2:8000`.

## Probar

Con el emulador de Firebase Auth levantado y una base cuyo nombre termine en `_test` (la suite borra
y recrea su esquema):

```sh
FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
DATABASE_URL=postgresql+psycopg://<usuario>:<contraseña>@<host>:<puerto>/<base>_test \
TEST_DATABASE_URL=postgresql+psycopg://<usuario>:<contraseña>@<host>:<puerto>/<base>_test \
  sh scripts/test.sh
```

`scripts/test.sh` (en la raíz del repo) corre `ruff`, `mypy` y `pytest` de la API y después
`flutter analyze`, el formato y `flutter test` de la app. Sólo la API:

```sh
cd apps/api
uv run ruff check .
uv run mypy app
uv run pytest
uv run pytest tests/escenarios --card <ID>
```

## Desplegar

La API es una aplicación ASGI común: sirve en cualquier plataforma que ejecute Python y ofrezca
PostgreSQL. Los pasos, sin importar cuál:

1. **Base de datos.** Crear una base PostgreSQL y tomar su cadena de conexión para `DATABASE_URL`.
2. **Variables de entorno.** Definir `DATABASE_URL`, `FIREBASE_PROJECT_ID`, `FIREBASE_API_KEY`,
   `URL_PUBLICA` (la dirección pública que le asigne la plataforma) y las `SMTP_*` con
   `CORREO_REMITENTE`. Dejar sin definir `PRUEBAS` y `FIREBASE_AUTH_EMULATOR_HOST`.
3. **Avisos push.** Descargar de la consola de Firebase una cuenta de servicio, ponerla como
   archivo secreto en la plataforma y apuntar `GOOGLE_APPLICATION_CREDENTIALS` a su ruta. El archivo
   no se sube al repositorio.
4. **Instalar.** `uv sync --no-dev` en `apps/api`.
5. **Migrar.** `uv run alembic upgrade head` antes de arrancar y en cada versión nueva.
6. **Arrancar.** `uv run uvicorn app.main:app --host 0.0.0.0 --port <puerto que indique la plataforma>`.
7. **Sembrar al administrador**, una vez, con el comando de «Configurar» contra la base de producción.
8. **Comprobar.** `<URL_PUBLICA>/docs` muestra la documentación y `GET <URL_PUBLICA>/sedes` sin
   sesión responde 401. Con la dirección en `API_URL_NUBE`, el escenario RNF-01-H06-01 hace esa
   comprobación: `uv run pytest tests/escenarios --card RNF-01`.

Un servicio que se apaga por inactividad tarda en contestar el primer pedido después de dormir;
conviene despertarlo antes de una demostración.

La app recibe la dirección con `--dart-define=API_URL=<URL_PUBLICA>` al construirse; ver el README de
`apps/mobile`.
