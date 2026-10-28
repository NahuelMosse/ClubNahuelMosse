# ENG-01 rename map (apply EXACTLY; whole-word, case-sensitive)
Worktree: D:/Temp/w/eng01 (apps/api). Do NOT touch: apps/api/app/main.py, app/health.py, app/salud.py, app/pruebas.py, app/e2e_support.py, app/shared/** (another agent owns them), tests/unit/test_base_en_ingles.py, tests/unit/test_config_en_ingles.py, tests/unit/test_glosario*.py, migraciones/versions/**.
Never change: SQL text, JSON keys, user-visible messages, routes, test titles/docstrings/file names (Spanish stays), Spanish names owned by modules (module functions like `cambiar_contrasena` in usuarios/contrasena.py, `barrer_cada`, param/variable names such as `identidad=proveedor`, `correo`, etc.), comments/docstrings (leave as they are). Only change code identifiers, import lines, and strings that are dotted module paths / attribute names given to monkeypatch.setattr/getattr/patch.

## Module paths
app.salud -> app.health ; app.pruebas -> app.e2e_support
app.shared.credencial_firebase -> app.shared.firebase_credential ; app.shared.cuerpo -> app.shared.body_limit ; app.shared.entradas -> app.shared.input_validation ; app.shared.errores_http -> app.shared.http_errors ; app.shared.errores -> app.shared.errors ; app.shared.identidad -> app.shared.identity ; app.shared.respuestas -> app.shared.responses ; app.shared.zona -> app.shared.club_timezone
Also the `from app.shared import entradas, errores_http` / `from app import salud, pruebas` forms and the uses `entradas.x`, `errores.X` through them. Keep imports alphabetically sorted if ruff isort complains (run `uv run --no-sync ruff check --select I --fix <files>`).

## app.shared.errors classes
DatosInvalidos->InvalidData, Duplicado->Duplicate, NoAutenticado->NotAuthenticated, Demorado->RateLimited, CuentaExistente->AccountExists, Prohibido->Forbidden, NoDisponible->Unavailable, NumeroOcupado->NumberTaken, HorarioOcupado->SlotTaken, NoEncontrada->NotFound, Cambiado->ConcurrentChange, ReservasAfuera->BookingsOutsideHours, AgendaCambiada->OpeningHoursChanged, ConReservasFuturas->HasFutureBookings
Attributes of these exceptions (only on exception instances, by hand-checking each site): InvalidData.errores->.errors ; Duplicate.campos->.fields ; NumberTaken.siguiente->.next_number (and .nombre stays .name: `e.nombre`->`e.name`) ; BookingsOutsideHours.cantidad->.count. Constructor keyword args, if any, follow (errores->errors, campos->fields, siguiente->next_number, nombre->name, cantidad->count). Known sites: espacios/rutas.py ~186, sedes/rutas.py ~160, usuarios/rutas_registro.py ~75-76, usuarios/sembrar_admin.py ~64,68. `.cantidad`/.nombre on non-exception objects stay.

## app.shared.db
VENTANA_DE_REINTENTO->RETRY_WINDOW ; motor->engine (ONLY the symbol imported `from app.shared.db import motor`; in tests the pytest fixture `motor` in conftest and its params are NOT renamed, they are a different thing) ; conexion->connection (the dependency function imported from app.shared.db) ; Conexion->DbConnection ; en_transaccion->in_transaction ; restriccion_violada->violated_constraint.
If a file already has a local name `engine` or `connection` that would clash, rename that local to `eng`/`conn` style and mention it in your report.

## body_limit / input_validation / others
CuerpoAcotado->BodyLimit ; LIMITE_BYTES->LIMIT_BYTES ; PLAZO_SEGUNDOS->TIMEOUT_SECONDS
Identificador->Identifier ; leer_hora->parse_time ; instalar->install (only as `entradas.instalar`/`errores_http.instalar` or imported from those modules) ; errores_de_forma->shape_errors
conflicto->conflict (the function from app.shared.respuestas)
credencial_de_servicio->service_credential
ZONA_CLUB->CLUB_TIMEZONE ; NOMBRE_ZONA_CLUB->CLUB_TIMEZONE_NAME (keep local aliases like `ZONA_CLUB as ZONA`: becomes `CLUB_TIMEZONE as ZONA`)
crear_app->create_app (apps/api tests, README, scripts, docs: grep the whole repo for `crear_app`, excluding main.py itself)

## app.shared.identity
ProveedorFirebase->FirebaseProvider ; function `identidad` imported from app.shared.identidad (used as `Depends(identidad)`) -> `identity` ; identidad_log->identity_log ; _app_firebase->_firebase_app
Provider METHOD names (on FirebaseProvider, on the Protocols in app/modules/*/casos_de_uso.py|registro.py|baja.py|contrasena.py that mirror it, on every fake provider class in tests, and at their call sites `identidad.crear_cuenta(...)`): crear_cuenta->create_account, uid_de->uid_of, borrar_cuenta->delete_account, uid_del_token->uid_from_token, contrasena_correcta->password_matches, cambiar_contrasena (the METHOD only, not the module function usuarios.contrasena.cambiar_contrasena)->change_password.
Their parameters in those method signatures: correo->email, contrasena->password, nueva->new_password (all keep the same position; callers pass positionally, check for keyword callers).

## Config (app.shared.config)
class Config->Settings (the instance `config` stays; `from app.shared.config import Config` in tests -> Settings; `AlembicConfig` untouched)
attributes of `config` and of Settings(...) kwargs, and their string names in monkeypatch.setattr(config, "<name>", ...):
firebase_credenciales_json->firebase_credentials_json ; url_publica->public_url (ONLY `config.url_publica` / Settings attr, not the parameter `url_publica` of use-case functions) ; correo_modo->email_mode (and its compared value "buzon"->"outbox" in `config.email_mode == ...`; values assigned in tests stay valid: "smtp") ; smtp_puerto->smtp_port ; smtp_usuario->smtp_user ; smtp_contrasena->smtp_password ; correo_remitente->email_sender ; pruebas->e2e_testing (ONLY `config.pruebas`) ; recordatorios_cada->reminders_every. smtp_host, firebase_api_key, firebase_project_id, database_url, version stay.
Env var names in tests/conftest.py stay as they are (old names are still accepted).

When done run, per area, `cd apps/api && UV_PROJECT_ENVIRONMENT="D:/desktop folders/estudio/Universidad de moron/Electiva general/app-tp/apps/api/.venv" uv run --no-sync ruff check <your files>` (F821/F401 sanity) and finish with a grep that no old name survives in your area. Do not run pytest. Do not commit. Report in <=10 lines: files touched, clashes, anything ambiguous you left.
