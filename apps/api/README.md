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

La configuración llega por variables de entorno. `app/config.py` también lee un archivo `.env`
local, que no se versiona; `.env.example` lista las variables. `FIREBASE_AUTH_EMULATOR_HOST`,
`GOOGLE_APPLICATION_CREDENTIALS`, `ADMIN_CONTRASENA` y `TEST_DATABASE_URL` se leen sólo del
entorno del proceso: en el `.env` no tienen efecto.

| Variable | Qué es |
|---|---|
| `DATABASE_URL` | Conexión a PostgreSQL, `postgresql+psycopg://<usuario>:<contraseña>@host:puerto/base`. Por defecto, usuario, contraseña y base `club` en `localhost:5432` |
| `FIREBASE_PROJECT_ID` | Identificador del proyecto de Firebase que emite los tokens |
| `FIREBASE_API_KEY` | Clave web del proyecto; la API la usa para comprobar contraseñas. No hace falta con el emulador |
| `URL_PUBLICA` | Dirección pública de esta API; los enlaces de los correos apuntan ahí |
| `CORREO_MODO` | `smtp` (por defecto) envía los correos; `buzon` los deja en la tabla `correo_saliente` y sólo sirve para desarrollo |
| `SMTP_HOST`, `SMTP_PUERTO`, `SMTP_USUARIO`, `SMTP_CONTRASENA`, `CORREO_REMITENTE` | Servidor de correo saliente con `CORREO_MODO=smtp` |
| `PRUEBAS` | `1` habilita `/_pruebas`, que sólo se monta si además existe `FIREBASE_AUTH_EMULATOR_HOST`; en un ambiente real no se define |
| `RECORDATORIOS_CADA` | Cada cuántos segundos el barrido manda los recordatorios; 30 por defecto, 0 lo apaga |
| `GOOGLE_APPLICATION_CREDENTIALS` | Ruta al archivo de cuenta de servicio de Firebase. En producción hace falta ésta o `FIREBASE_CREDENCIALES_JSON`: sin el emulador, la API la necesita para crear y borrar usuarios, verificar tokens con `check_revoked` y mandar avisos por Firebase Cloud Messaging |
| `FIREBASE_CREDENCIALES_JSON` | El contenido del JSON de la cuenta de servicio, para plataformas que no montan archivos (Render, con un Blueprint). Si `GOOGLE_APPLICATION_CREDENTIALS` también está definida, manda el JSON |
| `FIREBASE_AUTH_EMULATOR_HOST` | `host:puerto` del emulador de Firebase Auth; con él la API no usa el proyecto real |
| `ADMIN_CONTRASENA` | Contraseña de la cuenta de administrador, sólo para el comando que la siembra |
| `TEST_DATABASE_URL` | Base de los tests (su nombre termina en `_test`); sólo la lee `tests/conftest.py` |
| `DATABASE_URL_APP` | Conexión de la API con el usuario `club_app`, que lee y escribe filas y no cambia el esquema. Sin definir, la API usa `DATABASE_URL`. Las migraciones usan siempre `DATABASE_URL` |
| `METRICAS_TOKEN` | Token que `GET /metrics` pide como `Authorization: Bearer`. Sin definir, `/metrics` responde 404 |
| `VERSION` | Versión que informa `/health` y que lleva cada línea del log; por defecto sale del `pyproject.toml` |
| `DETRAS_DE_PROXY` | `true` si un proxy (Render) delante de la API pone `X-Forwarded-For`; sin eso la API toma como cliente la dirección que ve |

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

## Supuestos de operación

- **Límites de frecuencia:** por origen (10 pedidos por minuto, sin sesión) y por cuenta (10 por
  hora, con sesión), en la memoria de cada instancia. Pasado el cupo responde 429 con `Retry-After`
  y `{"mensaje": ...}`.
- **Host:** un pedido con un Host que no sea el propio, el de `URL_PUBLICA` o uno de
  `HOSTS_PERMITIDOS` (coma) responde 400. `/health` responde siempre.
- **Proxy:** con `DETRAS_DE_PROXY=true` el origen es el último valor de `X-Forwarded-For`, el que
  agrega Render.
- **Documentación:** `DOCUMENTACION_INTERACTIVA=false` apaga `/docs` y `/redoc`; `/openapi.json`
  sigue. Render lo apaga y chequea por `/health`.
- **Errores:** 400 por Host ajeno o `Content-Length` inválido (`{"detail": ...}`); 422 por un dato
  inválido (`{"errores": {campo: mensaje}}`); 429 por límite.
- **Emulador:** con `FIREBASE_AUTH_EMULATOR_HOST` definida la API no arranca si hay credenciales
  (`FIREBASE_CREDENCIALES_JSON`, `GOOGLE_APPLICATION_CREDENTIALS`) o si el proyecto no empieza con
  `demo-`.

## Contrato

`apps/api/openapi.json` es el contrato versionado y un test lo compara con la API. Se regenera
después de cualquier cambio de rutas o modelos:

```sh
cd apps/api
FIREBASE_AUTH_EMULATOR_HOST= uv run --no-sync python -c "import json, pathlib; from app.main import crear_app; pathlib.Path('openapi.json').write_text(json.dumps(crear_app().openapi(), indent=2, ensure_ascii=False) + '\n', encoding='utf-8')"
```

## Catálogo de deportes

El catálogo es fijo y vive en `app/dominio/espacios.py`; la app lo pide con `GET /espacios/catalogo`.
Deportes y tipos: Fútbol (F5, F7, F8, F11), Tenis (PDL, CEM), Pádel (PAD), Vóley (IND, PLA), Básquet
(B5, 3X3), Hockey (H7) y Golf (DR, 9H). Decisiones sobre Básquet:

- REV-05-ASM-01: Básquet tiene dos tipos: «Básquet 5» (`B5`, cancha completa) y «Básquet 3x3» (`3X3`, media cancha).
- REV-05-ASM-02: hasta que haya una foto de Básquet, la cancha toma la portada 1 del club, que no es de ningún otro deporte.
- REV-05-ASM-03: Básquet va después de Vóley en el catálogo.

## Probar

Con el emulador de Firebase Auth levantado y una base cuyo nombre termine en `_test` (la suite borra
y recrea su esquema):

```sh
# desde la raíz del repo
FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
DATABASE_URL=postgresql+psycopg://<usuario>:<contraseña>@<host>:<puerto>/<base>_test \
TEST_DATABASE_URL=postgresql+psycopg://<usuario>:<contraseña>@<host>:<puerto>/<base>_test \
  sh scripts/test.sh
```

`scripts/test.sh` se corre desde la raíz del repo; corre `ruff`, `mypy` y `pytest` de la API y
después `flutter analyze`, el formato y `flutter test` de la app. Sólo la API:

```sh
cd apps/api
uv run ruff check .
uv run mypy app
uv run pytest
uv run pytest tests/escenarios --card <ID>
```

Sin el emulador (variable ausente o emulador apagado) la corrida falla con «hace falta el emulador
de Firebase Auth». `uv run pytest --sin-emulador` salta los tests que usan la API y corre el resto
(los unitarios no necesitan base ni emulador); la salida cuenta los saltados como `skipped`.

## Operar

**Recordatorios sin el servicio web.** El servicio gratuito duerme y con él el barrido. El mismo
barrido corre como un comando de una pasada, para que lo dispare un cron o una tarea de Render:

```sh
cd apps/api
uv run python -m app.interfaz.barrido --una-vez
```

Termina con código 0 si el barrido corrió y 1 si falló. Quién lo dispara no está decidido:
`render.yaml` no suma una tarea paga. Un aviso que no salió deja una línea de error
`aviso_sin_enviar` en el log, con el número de la notificación y el tipo del error, sin el token.

**Usuario de la API.** Con el dueño de la base, una vez (y de nuevo para cambiar la clave):

```sh
python scripts/usuario_de_la_app.py --url <DATABASE_URL del dueño> --clave <clave nueva>
```

Después se define `DATABASE_URL_APP` con ese usuario (`club_app`). Si Render no deja crear el rol,
se deja sin definir.

**Respaldo y vuelta atrás.** Hacen falta `pg_dump` y `pg_restore` (herramientas cliente de
PostgreSQL de la misma versión mayor que la base):

```sh
python scripts/respaldo.py guardar --url <DATABASE_URL> --archivo club.dump
python scripts/respaldo.py restaurar --url <URL de una base vacía> --archivo club.dump
```

La vuelta atrás se prueba restaurando en otra base y comparando las filas, nunca sobre la de
producción. Mientras no haya plan pago, la base gratuita vence a los 30 días: se guarda un respaldo
antes. Objetivos que se asumen mientras una persona no decida otros: RPO igual al tiempo desde el
último respaldo (se recomienda uno por día y otro antes de cada despliegue con migraciones) y RTO de
una hora, que es lo que tarda crear una base, restaurar y cambiar `DATABASE_URL`.

**Métricas y logs.** `GET /metrics` (con `METRICAS_TOKEN`) expone los contadores; `/ready` dice si la
base responde y el esquema está al día. Cada error 500 devuelve una referencia que es el
`X-Request-ID` del pedido y que se busca en el log.

## Decisiones de datos

Lo que se asumió donde el requisito no lo dice (REV-03); cada una se cambia en un solo lugar.

- REV-03-ASM-02: un aviso de cancelación que quedó `enviando` por una caída del proceso se
  vuelve a mandar y puede llegar dos veces; un recordatorio varado queda `fallida` y no se repite
  («se envía una sola vez», CU-24.1). Si se prefiere no repetir nunca, el aviso de cancelación
  también pasa a `fallida` (`que_hacer_con_varado`, `app/dominio/notificaciones.py`).
- REV-03-ASM-03: el historial propio (`GET /reservas`) trae tandas de 20, igual que el global;
  `siguiente` es el valor de `despues` que pide la tanda que sigue y es `null` en la última. Un
  cliente que no manda `despues` ve las 20 más recientes.
- REV-03-ASM-04: un aviso `enviando` hace más de 5 minutos se da por varado (`TOMA_VENCIDA`).
- REV-03-ASM-05: cada toma de un aviso suma un intento (`notificacion.intentos`, con la hora en
  `tomada_en`); con 3 queda `fallida` y el log registra `aviso_sin_enviar` con el número y el
  tipo, sin datos de la persona.
- REV-03-ASM-11: `GET /reservas/todas` acepta `despues` y sigue aceptando `pagina` para las
  apps ya instaladas; con los dos, manda `despues`. Un `despues` que no sale de un `siguiente`
  es un 422.

## Desplegar en Render

El `render.yaml` de la raíz del repo describe todo: un web service de Python para la API
(`apps/api`) y una base Postgres gestionada, ambos en el plan `free`. Render instala con `uv sync`
(detecta `uv.lock`), migra con `alembic upgrade head` dentro del build, arranca `uvicorn` en el
`$PORT` que asigna y consulta `/docs` como health check.

1. **Cuenta de Render.** Crear la cuenta en <https://render.com> y autorizar el acceso a GitHub.
2. **Proyecto de Firebase.** En <https://console.firebase.google.com> crear un proyecto
   y, dentro de él:
   - *Authentication* → *Sign-in method*: habilitar «Correo electrónico y contraseña».
   - *Configuración del proyecto* → *General*: anotar el **ID del proyecto** (`FIREBASE_PROJECT_ID`)
     y la **clave de API web** (`FIREBASE_API_KEY`).
   - *Configuración del proyecto* → *Cuentas de servicio* → *Generar nueva clave privada*: se
     descarga un `.json`. Es un secreto: no se sube al repositorio.
3. **Repositorio en GitHub.** Subir este repo (el `render.yaml` tiene que estar en la raíz de la
   rama que Render va a seguir).
4. **Blueprint.** En Render: *New* → *Blueprint*, elegir el repo y la rama, y confirmar. Render
   crea `clubnahuelmosse-api` y `clubnahuelmosse-db` y pide los valores de las variables marcadas
   `sync: false`:

   | Variable | Valor |
   |---|---|
   | `FIREBASE_PROJECT_ID`, `FIREBASE_API_KEY` | los del paso 2 |
   | `FIREBASE_CREDENCIALES_JSON` | el **contenido completo** del `.json` de la cuenta de servicio |
   | `URL_PUBLICA` | `https://<nombre del servicio>.onrender.com`, la dirección que Render muestra para `clubnahuelmosse-api` |
   | `SMTP_HOST`, `SMTP_USUARIO`, `SMTP_CONTRASENA`, `CORREO_REMITENTE` | los de la cuenta de correo saliente (`SMTP_PUERTO` ya está en 587) |

   Render pide estos valores sólo al crear el Blueprint; para cambiarlos después, se editan en
   *Environment* del servicio. `DATABASE_URL` sale de la base: `config.py` le agrega el driver
   `psycopg` a la `postgresql://` que entrega Render. `PRUEBAS` y `FIREBASE_AUTH_EMULATOR_HOST`
   no se definen.
5. **Sembrar al administrador**, una vez, desde esta máquina contra la base de Render. En la
   base (*Connections* en el dashboard) copiar la **External Database URL** y, desde `apps/api`:

   ```sh
   DATABASE_URL=<External Database URL>    FIREBASE_PROJECT_ID=<id del proyecto> FIREBASE_API_KEY=<clave web>    GOOGLE_APPLICATION_CREDENTIALS=<ruta al .json descargado>    ADMIN_CONTRASENA=<contraseña>    uv run python -m app.interfaz.sembrar_admin      --correo <correo> --nombre <nombre> --apellido <apellido> --dni <dni> --nacimiento AAAA-MM-DD
   ```

6. **Comprobar.** `https://<servicio>.onrender.com/openapi.json` devuelve el esquema y
   `GET /sedes` sin sesión responde 401. Con la dirección en `API_URL_NUBE`, el escenario
   RNF-01-H06-01 hace esa comprobación: `uv run pytest tests/escenarios --card RNF-01`.

Los despliegues siguientes salen solos con cada commit a la rama enlazada.

Límites del plan `free`:

- El servicio se duerme tras 15 minutos sin tráfico y el primer pedido después tarda alrededor
  de un minuto: conviene despertarlo antes de una demostración. Mientras duerme, el barrido de
  recordatorios no corre.
- La base gratuita vence a los 30 días de creada, sin backups, y hay una por workspace.
- `preDeployCommand` no existe en el plan gratuito; por eso las migraciones corren en el build.
  Con un plan pago, se mueve esa parte a `preDeployCommand` en el `render.yaml`.

La app recibe la dirección con `--dart-define=API_URL=<URL_PUBLICA>` al construirse; ver el README de
`apps/mobile`.

Para volver atrás un despliegue, rotar un secreto o atender un incidente: `docs/technical/runbook.md`.

## Supuestos que limitan lo que hace la API

Decisiones tomadas sin respuesta del cliente, que cambian lo que ve quien usa la API o lo que hace
quien la opera. Cada ID está registrado en `specs/<card>/ambiguedades.md`; los demás supuestos de
cada card están ahí.

- CU-13-SUP-08 · una reserva dura de 1 a 4 horas, en horas en punto; la API rechaza una duración
  menor a una hora o mayor a 4 horas.
- CU-13-SUP-07 · sólo se reserva hasta 7 días de anticipación (los próximos siete días) y en
  horarios futuros, en la hora del club.
- CU-09-SUP-02 · el administrador no reserva: la API le responde 403. No hay tope de reservas
  activas por usuario.
- CU-09-SUP-03 · si dos personas piden el mismo horario a la vez gana una: la restricción de
  exclusión de la base rechaza la segunda con 409.
- CU-21-SUP-04 · el catálogo de deportes y tipos de espacio es fijo, vive en el código de la API y
  no se edita desde la app (hoy no incluye Básquet).
- CU-12-SUP-05 · el precio es el del espacio, igual a toda hora; la app lo muestra pero no hay
  pagos ni reintegros (CU-09-AMB-10, CU-10-AMB-08).
- CU-24.1-SUP-02 · el backend no reintenta un aviso push fallido: queda en el centro de avisos
  como fallido, y un token que Firebase rechaza por inválido se da de baja.
- CU-01-SUP-02 · la API no bloquea por intentos fallidos de ingreso; sólo corta Firebase
  (`TOO_MANY_ATTEMPTS`, respondido como 429).
- CU-07-SUP-01 · una cuenta dada de baja libera su correo y su DNI para una cuenta nueva.
