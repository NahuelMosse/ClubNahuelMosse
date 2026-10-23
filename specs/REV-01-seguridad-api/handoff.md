# Handoff REV-01 (arreglos del gate final)

## Hecho (commiteado)
1. lint: `ruff format` de `app/dominio/notificaciones.py`. `ruff check`, `ruff format --check` (Gate) y `mypy --strict app` pasan.
2. scenarios: `tests/conftest.py` acepta `@<ID>-H`, `@<ID>-S` y `@assumption:<ID>-ASM-`. `pytest tests/escenarios --card REV-01` = 70 passed.
3. suite:
   - `tests/integracion/test_rutas_protegidas.py`: `/health` agregado a PUBLICAS (ASM-07; test sin tags, editado).
   - `tests/unit/test_correo.py`: la aserción pasa de «faltan SMTP_HOST…» a «RuntimeError» (S11: el log no lleva el texto de la excepción; sin tags).
   - `tests/integracion/test_notificaciones_api.py`: renombrado `..._no_cambia_de_dueno`, el dueño sigue siendo la primera cuenta (S19/ASM-04; sin tags).
   - Reemplazo del test congelado `test_requisitos_no_funcionales.py::test_toda_operacion_de_la_api_sin_usuario_autenticado_se_rechaza` (@RNF-01-H06-02) por `tests/escenarios/test_requisitos_no_funcionales_con_salud.py` (mismo título y tags, `/health` público). El viejo sigue fallando por /health al correr la suite entera: hay que reportarlo al principal (no se puede editar).
4. mutate identidad.py:97: `tests/unit/test_identidad_ingreso.py` (2 tests, urlopen simulado) mata `False`→`None`. Falta correr la mutación: la línea `mutate ...identidad.py` del Gate ya suma ese archivo, pero la herramienta aborta porque la suite entera pasa el presupuesto de 10 min; hay que cambiar esa línea del Gate a solo `tests/unit/test_identidad_ingreso.py` y correr `node .claude/tools/mutate.mjs apps/api/app/infraestructura/identidad.py -- "<comando>"` en background.
5. K4 de producción: nuevo `app/interfaz/respuestas.py` (sin_permiso, no_encontrado, datos_invalidos, conflicto), usado en sedes, reservas, espacios y horarios; `_datos` en sedes; `_CamposDeReserva` base de `ReservaVista` y `ReservaHistorialVista` y `model_validate(from_attributes=True)` en lugar de las copias campo a campo. Un jscpd propio sobre apps/api ya no muestra clones entre los archivos de la card salvo el de abajo.

## Falta
- Tests sin volver a correr tras el último cambio de `reservas.py` (solo `--card REV-01` + notificaciones): correr la suite entera en segundo plano (`sh D:/Temp/w/herramientas/pytest-aislado.sh uv run --no-sync pytest -q -p no:cacheprovider > /tmp/rev01-g-N.log`, ~6 min) y comprobar que `openapi.json` versionado sigue coincidiendo (hay test).
- K4 de producción restante: `app/interfaz/reservas.py:399` vs `:230` (7 líneas, el try de `historial_global` contra el de `modificar`/`hacer_reserva`); extraer o revisar.
- K4 de tests: agregar al final de `## Log` una línea `- L<n> · <fecha> · declared · K4 · <archivo>:<líneas> · test congelado con tags, no se puede editar` para: `test_seguridad_api.py` (50-67 vs entradas_extra 26-43; 84-94 vs integracion/conftest.py 22-32; 130-139 vs entradas_extra 199-208), `test_requisitos_no_funcionales.py:168` (vs el reemplazo). El resto (tests/unit, tests/integracion de cards anteriores) no es de la card.
- Log (solo se agrega al final): una línea por arreglo con evidencia, más `- L<n> · <fecha> · replaces: apps/api/tests/escenarios/test_requisitos_no_funcionales.py "test_toda_operacion_de_la_api_sin_usuario_autenticado_se_rechaza" · /health es público (REV-01-ASM-07) · by: apps/api/tests/escenarios/test_requisitos_no_funcionales_con_salud.py "test_toda_operacion_de_la_api_sin_usuario_autenticado_se_rechaza"`.
- Sin tocar: `I-line` y `attacks:`.

## Cómo correr
`cd apps/api; export FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:8702; sh D:/Temp/w/herramientas/pytest-aislado.sh uv run --no-sync pytest <archivos>`. Clones: `npx -y jscpd@4 --silent --gitignore --reporters json --output .validation/jscpd2 --ignore "**/node_modules/**,**/.claude/**,**/specs/**,**/.validation/**,**/mobile/**" apps/api`.
