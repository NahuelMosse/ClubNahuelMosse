# SIM-02 · la API se lee fácil y hace lo mismo

status: proposed
cap: 6 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «tambien quiero que limpies el codigo, porque creo que esta muy sucio, dificil de leer» · «de funcionalidad no sacaria nada» · «quedas solo toda la noche, simplifica sin sacar fucionalidad y deja todo mas organizado»"
  - "relevamiento · plan del planner sobre la API ya por funcionalidad (2026-10-27): ruff C90/PLR/RET/N/ERA/FBT da 99 hallazgos en 68 archivos; 8 funciones de más de 40 líneas (encolar_cancelacion_forzosa 97, mover 77, historial 70, anular 64…); reservas/repositorio.py 476 líneas con SQL repetido; código muerto en sesion/usuario_actual.py"
  - "pendiente de SIM-01 (L80): lo que quedaba de esa card ya lo resolvieron NOT-01, DOC-01, ARQ-04 y DAT-01 con el kit 6.21 (la suite completa pasó en DAT-01; shape mira sólo lo que la card empeora)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "simplifica sin sacar fucionalidad" · acceptance: la API responde igual: el contrato publicado (`apps/api/openapi.json`) no cambia y la suite que pasaba sigue pasando
- S2 · "deja todo mas organizado" · acceptance: el código de la API pasa ruff con las reglas de código legible del kit (complejidad ≤ 10, ≤ 4 parámetros, sin parámetros booleanos posicionales, sin valores con regla sueltos, sin código comentado, retornos simples, nombres) y ninguna función pasa de 40 líneas
- S3 · "limpies el codigo, porque creo que esta muy sucio, dificil de leer" · acceptance: no queda código muerto (`peticion.state.usuario_id`, el alias `reemplaza`), el SQL que se repetía en reservas tiene un nombre y se usa desde un solo lugar, y cada valor con regla (el código de error `23P01`, los segundos de una hora, los intentos con agenda nueva) es una constante con nombre
- SIM-02-ASM-01 · las excepciones del dominio conservan sus nombres en castellano (`HorarioOcupado`, `NoEncontrada`): la regla N818 (sufijo `Error`) queda apagada en la configuración, con su motivo · S2
- SIM-02-ASM-02 · las rutas de FastAPI quedan fuera del tope de parámetros: cada `Depends` cuenta como parámetro y es la forma de inyectar del framework · S2
- SIM-02-ASM-03 · las firmas públicas de los casos de uso y los repositorios no cambian, porque las llaman muchos tests congelados; las que pasan el tope de parámetros llevan `# noqa: PLR0913` con el motivo, y se simplifica lo de adentro · S2
- SIM-02-ASM-04 · el orden en que una reserva toma sus bloqueos (cuenta, sede, espacio, reserva) y su SQL de concurrencia no se reordena: sólo se extrae a funciones con nombre · S1
- SIM-02-ASM-05 · lo organizado se mide con la regla de código legible del kit (`.claude/rules/architecture.md`): las reglas de ruff C90, PLR, RET, N, ERA y FBT con su complejidad y su tope de parámetros, y funciones de hasta 40 líneas · S2

## Tasks

- T1 · S2,S3,SIM-02-ASM-01,SIM-02-ASM-02 · apps/api/pyproject.toml, apps/api/tests/unit/test_codigo_legible.py, apps/api/app/modules/sesion/usuario_actual.py (presentation), apps/api/app/modules/usuarios/reglas.py (rule), apps/api/app/modules/horarios/reglas.py (rule), apps/api/app/shared/identidad.py (data), apps/api/app/modules/sedes/casos_de_uso.py (rule), apps/api/app/modules/usuarios/administradores.py (rule) · tests: apps/api/tests/unit/test_codigo_legible.py "la API pasa ruff con las reglas de código legible @SIM-02-S2 @assumption:SIM-02-ASM-01 @assumption:SIM-02-ASM-02 @assumption:SIM-02-ASM-05"; apps/api/tests/unit/test_codigo_legible.py "ninguna función de la API pasa de 40 líneas @SIM-02-S2 @assumption:SIM-02-ASM-05"; apps/api/tests/unit/test_codigo_legible.py "no queda código muerto ni valores con regla sin nombre @SIM-02-S3"; apps/api/tests/unit/test_codigo_legible.py "las firmas públicas de los casos de uso y los repositorios de cada módulo son las de main @assumption:SIM-02-ASM-03"
  reuses: apps/api/pyproject.toml `[tool.ruff.lint]`, que ya selecciona E, F, I, B, UP y SIM
- T2 · S1,S2,S3,SIM-02-ASM-03,SIM-02-ASM-04 · apps/api/tests/integracion/test_api_legible.py, apps/api/app/modules/reservas/repositorio.py (data), apps/api/app/modules/reservas/casos_de_uso.py (rule), apps/api/app/modules/reservas/almacen.py (rule) · tests: apps/api/tests/unit/test_codigo_legible.py "el SQL que se repetía en reservas vive en un solo lugar: el total por hora y la superposición 23P01 @SIM-02-S3"; apps/api/tests/unit/test_codigo_legible.py "una reserva toma sus bloqueos en el mismo orden @assumption:SIM-02-ASM-04"; apps/api/tests/integracion/test_api_legible.py "una reserva hecha y movida sobrevive a reiniciar la API sobre la misma base @SIM-02-S1"
  reuses: el `en_transaccion` compartido; las consultas existentes de apps/api/app/modules/reservas/repositorio.py, extraídas con nombre
- T3 · S2,S3 · apps/api/app/modules/notificaciones/repositorio.py (data), apps/api/app/modules/notificaciones/casos_de_uso.py (rule), apps/api/app/modules/notificaciones/almacen.py (rule) · tests: apps/api/tests/unit/test_codigo_legible.py "ninguna función de la API pasa de 40 líneas @SIM-02-S2"
  reuses: las sentencias de encolar_cancelacion_forzosa y entregar, partidas en funciones privadas sin cambiar su orden
- T4 · S2 · apps/api/app/modules/espacios/casos_de_uso.py (rule), apps/api/app/modules/espacios/reglas.py (rule), apps/api/app/modules/espacios/repositorio.py (data), apps/api/app/modules/sedes/repositorio.py (data), apps/api/app/modules/horarios/disponibilidad.py (rule), apps/api/app/modules/horarios/casos_de_uso.py (rule), apps/api/app/modules/horarios/repositorio.py (data), apps/api/app/modules/recuperacion/casos_de_uso.py (rule), apps/api/app/modules/usuarios/sembrar_admin.py (presentation), apps/api/app/modules/sedes/rutas.py (presentation), apps/api/app/modules/usuarios/contrasena.py (rule) · tests: apps/api/tests/unit/test_codigo_legible.py "la API pasa ruff con las reglas de código legible @SIM-02-S2 @assumption:SIM-02-ASM-01 @assumption:SIM-02-ASM-02"
  reuses: las funciones existentes, partidas en privadas del mismo módulo

## Changes to existing behavior

- none: la API publica el mismo contrato y la app no cambia

## Gate

```
suite [timeout 2 h]: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider
fmt: cd apps/api && uv run --no-sync ruff format --check app tests/unit/test_codigo_legible.py
lint: sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/app apps/api/tests/unit/test_codigo_legible.py
migrate-upgrade: cd apps/api && sh -c "DATABASE_URL=postgresql+psycopg://club:club@127.0.0.1:8701/club_sim02_migra uv run --no-sync alembic upgrade head"
app: sh D:/Temp/w/herramientas/arq01-app.sh sim02_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh sim02_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --unique 'POST /sedes {"nombre": "Sede Unica Ataque", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5]}'
no-docs: refactor interno; el comportamiento, el contrato y el modelo de datos no cambian
mutate apps/api/app/modules/notificaciones/casos_de_uso.py: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/unit/test_despacho_de_confirmaciones.py tests/unit/test_cola_de_avisos.py tests/unit/test_recordatorios.py
mutate apps/api/app/modules/reservas/almacen.py: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/unit/test_casos_de_uso_reservas.py
mutate apps/api/app/modules/reservas/casos_de_uso.py: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/unit/test_casos_de_uso_reservas.py
mutate apps/api/app/modules/reservas/repositorio.py: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/integracion/test_reservas_api.py tests/integracion/test_api_limpia_reservas.py tests/integracion/test_api_limpia_reserva_movida.py tests/integracion/test_anular_reserva_api.py tests/integracion/test_historial_api.py tests/integracion/test_api_legible.py tests/escenarios/test_historial_reservas.py
mutate apps/api/app/modules/notificaciones/almacen.py: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/unit/test_despacho_de_confirmaciones.py tests/unit/test_cola_de_avisos.py tests/unit/test_recordatorios.py
mutate apps/api/app/modules/notificaciones/repositorio.py: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/escenarios/test_cancelacion_forzosa.py tests/escenarios/test_cancelacion_forzosa_agrupado.py tests/escenarios/test_confirmacion_cancelacion_reglas.py tests/integracion/test_notificaciones_api.py
```

## Log

- L1 · tambien quiero que limpies el codigo, porque creo que esta muy sucio, dificil de leer · de funcionalidad no sacaria nada · quedas solo toda la noche, simplifica sin sacar fucionalidad y deja todo mas organizado
- L2 · 2026-10-27 · declared · fault-db · la base es Postgres, no un archivo; la suite de integración la usa como siempre
- L3 · 2026-10-27 · RED · tests/unit/test_codigo_legible.py (6 tests) + tests/integracion/test_api_legible.py (1) · arq01-pytest: 4 failed (ruff, 40 líneas, constantes, SQL único), 3 passed (firmas, bloqueos, reinicio) · commit 369231d
- L4 · 2026-10-27 · T1 · pyproject (C90,PLR,RET,N,ERA,FBT; N818 ignorado; rutas* sin PLR0913/0917), constantes MIN_LARGO_DE_CONTRASENA/HORAS_POR_DIA/HTTPStatus.BAD_REQUEST, validar_rango partida, `*` en confirmar/promover, noqa PLR0913 con motivo; peticion.state.usuario_id quitado (el parámetro `peticion` queda: el test de firmas lo exige) · mypy --strict app: Success; tests/unit + sedes/sesion/rutas_protegidas: 321 passed, 5 failed (los de test_codigo_legible que esperan T2-T4)
- L5 · 2026-10-27 · T2 · reservas: _TOTAL_SQL (único /3600) y EXCLUSION_VIOLATION (único 23P01) con _horario_ocupado, _DE_RESERVA, _sede_vigente/_bloquear_* partidos (mover/anular/insertar/historial <=40), _detalle delega en una_de_cualquiera, INTENTOS_CON_AGENDA_NUEVA, duración con timedelta; mismos SQL en el mismo orden · ruff check/format app/modules/reservas limpio, mypy --strict app: Success; 10 archivos guía: 76 passed; test_codigo_legible: bloqueos/firmas/SQL único pasan, quedan 40 líneas y ruff/reemplaza por T3/T4 · pyproject: ignore PLR2004/SIM102/C901 para test_codigo_legible (test congelado)
- L6 · 2026-10-27 · T3 · notificaciones: encolar_cancelacion_forzosa partida en _bloquear_anulaciones/_anuladas_sin_aviso/_aviso_sin_leer/_abrir_aviso/_reemplazar_aviso (mismo SQL y orden), registrar con _sigue_vigente, sin alias `reemplaza`, noqa en firmas fijas · arq01-pytest -k cancelacion_forzosa/despacho/aviso/cola/recordatorio/notificaciones_api: 75 passed
- L7 · 2026-10-27 · T4 · espacios (insertar/actualizar partidos, _calcular de 4 params), sedes (_verificar_reservas, _guardar, `*, confirmar`), horarios/recuperacion noqa en firmas fijas, sembrar_admin._leer, pyproject per-file N818 en app/ · ruff check app, ruff format --check app, mypy --strict app limpios; tests/unit 297 passed (incl. test_codigo_legible entero); -k espacios/sedes/horarios/usuarios 171 passed
- L8 · 2026-10-27 · Tasks suma los almacen.py (sus Protocols siguen las firmas), sedes/rutas.py (llama a `actualizar` con `confirmar=` por nombre) y usuarios/contrasena.py (noqa de su firma pública); las reglas de código legible no rigen en tests/ (estilo de pytest); mutación de los dos archivos de notificaciones que el grado mvp pide
- L9 · 2026-10-27 · declared · K4 · apps/api/tests/integracion/test_api_legible.py · arma la reserva como el test de reinicio de SIM-01, congelado, que no se importa
