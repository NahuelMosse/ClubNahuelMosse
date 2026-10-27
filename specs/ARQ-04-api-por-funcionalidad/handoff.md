# Handoff ARQ-04 (worktree D:/Temp/w/arq04, rama card/ARQ-04)

## Hecho
T1 (RED), T2+T3 (shared, sesion, espacios, sedes, horarios) verificados: `ruff check app` limpio, `mypy --strict app` OK (69 archivos), integración verde. Log L7-L9 escrito. Migraciones idénticas a card/SIM-01 (comprobar `git diff --stat card/SIM-01 -- apps/api/migraciones/versions` vacío antes de cada commit; ruff sólo sobre app/ y tests/).

## Entorno
`export UV_PROJECT_ENVIRONMENT="D:/desktop folders/estudio/Universidad de moron/Electiva general/app-tp/apps/api/.venv"` en CADA llamada (no persiste; sin él uv crea apps/api/.venv y falla psycopg: borrarlo). Tests: `sh D:/Temp/w/herramientas/arq01-pytest.sh tests/unit tests/integracion -v -rf -p no:cacheprovider` (el script hace cd apps/api, rutas relativas a apps/api). Tarda ~12 min con la máquina cargada: background + `node .claude/tools/wait.mjs <log> --until '^exit ' --max 570`. No correr tests/escenarios enteros sin necesidad (muy lentos).

## T4 hecho (notificaciones + reservas, ASM-04; Log L10-L11)
`modules/notificaciones` y `modules/reservas` con `__init__`, `DatosDeReserva` en notificaciones/reglas.py, providers en cada repositorio.py, `Errores` propio en notificaciones/rutas.py, dependencias.py sólo con usuarios/enlaces/correo, main.py usa `app.modules`. ruff/mypy verdes. Lo que sigue es T5, T6 y los tests congelados (abajo). Archivos que aún citan rutas viejas: tests/escenarios/test_basquet.py (`app.interfaz.sembrar_admin`).

## T5 hecho (commit cdc2237 + siguiente; Log L12-L23)
usuarios y recuperacion planos en modules/, main/salud/pruebas arriba, interfaz/ dependencias.py/aplicacion/dominio/infraestructura borrados, 4 esquemas renombrados (ASM-05), openapi.json regenerado, rutas viejas de tests reescritas (también los 3 `from app.infraestructura import correo`). ruff app limpio, mypy --strict app ok, migraciones idénticas. Script: D:/Temp/w/herramientas/arq04_mover_t5.py.
`tests/unit/test_arquitectura.py` se hizo `git rm` y lo reemplaza `tests/unit/test_arquitectura_funcionalidades.py` (sin type: ignore; contrato comparado con el commit base 612d445, no con main, que tenía /metrics y /ready que la branch ya no tiene; Log tiene los 11 `replaces:`). 10/11 verdes; el que falta (`ningún test importa las rutas viejas`) pasa cuando se reemplacen test_capas.py y test_api_limpia*.py.
close.mjs --check: check 5 mira sólo los archivos con tag @ARQ-04 al RED (T1): el `git rm` de test_arquitectura.py figura como cambiado (D) aunque el Log lo declare reemplazado; declararlo en `## Could not run`/cierre. Las reescrituras en sitio de tests de otras cards (L10) NO entran en el check 5 de esta card. (No llegué a leer la salida completa del check: correrlo en background, tarda > 2 min.)

## Falta
1. Reemplazar con archivo nuevo mismo tag (y `git rm` del viejo, `replaces:` en Log por test, `by:` pasando): tests/unit/test_capas.py (rutas app/infraestructura, app/interfaz, dependencias.py, interfaz/reservas.py, `app.aplicacion.reservas`, dominio/zona), test_capas_integracion.py (texto "app.infraestructura"), test_api_limpia.py (línea 90: `interfaz/entradas.py` -> `shared/entradas.py`), test_api_limpia_plan.py, test_sin_supresiones.py si algo lo rompe aún. Escanear app/shared/* y app/modules/*/repositorio.py en lugar de infraestructura. Nombres nuevos sugeridos: *_funcionalidades.py.
2. T6: docs/technical/mapa-del-codigo.md (+arquitectura.md, system-design.md, runbook.md), docs/guia-basica.md, apps/api/README.md, README.md (comando de regenerar openapi y `python -m app.modules.usuarios.sembrar_admin` / `app.modules.notificaciones.barrido`), scripts/e2e.sh, .claude/rules/arquitectura.md; test_mapa_por_funcionalidad.py debe quedar verde.
3. Pytest completo (background): `sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider > /tmp/arq04.log 2>&1`; 7 fallos previos de ARQ-02 L23/L24 conocidos. Aún no corrido tras T5 (sólo ruff/mypy y test_arquitectura_funcionalidades).
4. test_basquet.py: ya reescrito por el script (sembrar_admin); comprobar en el pytest completo.
5. Antes de cada commit: `git diff --stat card/SIM-01 -- apps/api/migraciones/versions` vacío; ruff format sólo en app/ y tests/ propios, nunca migraciones.
Nota Windows: el FS no distingue mayúsculas (Perfil.py == perfil.py) al comprobar existencia de archivos en tests.
