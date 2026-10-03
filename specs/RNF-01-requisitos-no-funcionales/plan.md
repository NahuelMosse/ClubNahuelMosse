# Plan — RNF-01 · Requisitos no funcionales y entregables

Escenarios: RNF-01-H01-01, H02-01, H03-01, H04-01, H05-01, H06-01, H06-02, H06-03, H07-01, H07-02 y
H08-01, todos en `apps/api/tests/escenarios/test_requisitos_no_funcionales.py`.

La card no agrega comportamiento de negocio: verifica lo que el repo ya hace y completa lo que falta
(nombre visible, ícono, READMEs) y el despliegue en Render. H06-01 necesita la API ya desplegada, con
las cuentas del usuario: su test se salta sin `API_URL_NUBE` y el resultado es «no se pudo correr»
hasta que se despliegue y se corra con esa variable.

## Mapa de archivos

| Ruta | Responsabilidad y decisiones |
|---|---|
| `apps/api/tests/escenarios/test_requisitos_no_funcionales.py` | Los once escenarios. Los de repo leen archivos; los de API usan `api` y `motor` del conftest. Compara las llamadas de la app (`_api.get('/x')`, `_get`, `Uri(path:)`) con `/openapi.json` |
| `apps/mobile/android/app/src/main/AndroidManifest.xml` | `android:label="ClubNahuelMosse"`; el `applicationId` ya es `ar.edu.unimoron.clubnahuelmosse` |
| `apps/mobile/pubspec.yaml` | `flutter_launcher_icons` en `dev_dependencies` y su configuración (`image_path`, fondo adaptativo) |
| `apps/mobile/assets/icono/icono.png` | Imagen fuente del ícono, lima `#D4FF3D` sobre `#0A0A0B` (tokens de `tema/tokens.dart`) |
| `apps/mobile/android/app/src/main/res/mipmap-*` | Íconos generados con `dart run flutter_launcher_icons`, incluido el adaptativo |
| `apps/mobile/README.md` | Configurar, ejecutar, probar y construir la app; variables `--dart-define` de `configuracion.dart` |
| `apps/api/.env.example` | Variables de `config.py` sin valores secretos; las que sólo se leen del entorno, comentadas |
| `apps/api/tests/integracion/test_rutas_protegidas.py` | Recorre `app.routes` (también lo que no está en OpenAPI) y exige 401 en las 28 operaciones fuera de las públicas |
| `apps/api/README.md` | Configurar, ejecutar, probar y desplegar la API; variables de `app/config.py`, migraciones, Auth, pasos de Render |
| `render.yaml` | Blueprint de Render (RNF-01-AMB-05): web service Python `clubnahuelmosse-api` con `rootDir: apps/api` y Postgres `clubnahuelmosse-db`, ambos `free`. Build `uv sync --frozen --no-dev` más `alembic upgrade head` (el plan free no tiene `preDeployCommand`); start `uvicorn` en `$PORT`; health check `/docs` (público, las demás rutas dan 401). `DATABASE_URL` viene de la base con `fromDatabase`; los secretos y los datos de Firebase y del correo son `sync: false` |
| `apps/api/app/config.py` | `database_url` se normaliza: `postgres://` y `postgresql://` (lo que entrega Render) pasan a `postgresql+psycopg://`. `firebase_credenciales_json` trae la cuenta de servicio en una variable, porque un Blueprint no declara Secret Files |
| `apps/api/app/infraestructura/credencial_firebase.py` | Convierte `FIREBASE_CREDENCIALES_JSON` en credencial de `firebase-admin`; sin ella, queda `GOOGLE_APPLICATION_CREDENTIALS`. La usan `identidad.py` y `push.py` |
| `apps/api/tests/unit/test_config.py`, `test_credencial_firebase.py` | El normalizador de la URL y la lectura del JSON, sin tag de card |
| `apps/mobile/android/app/src/main/AndroidManifest.xml` | `INTERNET` declarado también en el manifiesto principal, para que el APK `release` llegue a Render |
| `specs/RNF-01-requisitos-no-funcionales/{plan,tasks,ambiguedades}.md` | Registro de la card |

Sin código de `apps/mobile/lib`. En `apps/api/app`, sólo lo que pide Render: la URL de la base y la credencial de Firebase.

## Supuestos

- RNF-01-SUP-01 · sedes y espacios requieren sesión · `@supuesto:RNF-01-SUP-01` en H06-02
- RNF-01-SUP-05 · README verificado contra el código, no desde una máquina limpia · `@supuesto:RNF-01-SUP-05` en H07-01 y H07-02
- RNF-01-SUP-06 · historial: al menos 50 commits en 3 días distintos · `@supuesto:RNF-01-SUP-06` en H03-01

## Supuestos sin cobertura

| Supuesto | Motivo |
|---|---|
| RNF-01-SUP-02 · el plan gratuito de Render alcanza | depende de la demostración: el servicio duerme a los 15 minutos y la base gratuita vence a los 30 días |
| RNF-01-SUP-03 · repo único con app y API cumple | es una lectura del enunciado, no un comportamiento |
| RNF-01-SUP-04 · ícono lima sobre oscuro | juicio visual; el test sólo verifica que no es el de Flutter |

## Perímetro

Auth: emulador de Firebase Auth y base `*_test` locales; el repo no lleva cuentas ni credenciales.
Afuera: el deploy real en Render (lo hace el usuario con el README de la API), la instalación en
emulador y la corrida de integration_test (pasada final), la subida a Blackboard y la defensa.
