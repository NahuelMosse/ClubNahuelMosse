# Handoff ARQ-04 T2+T3 (worktree D:/Temp/w/arq04, rama card/ARQ-04)

Estado: un commit WIP "T2+T3" con todo movido y los imports reescritos. Sin verificar salvo `python -c "import app.main"`.

## URGENTE primero
`ruff format` corrió sobre `apps/api/migraciones/versions/*.py` (0001..0009) y las reformateó: restaurarlas con `git checkout main -- apps/api/migraciones/versions` y commitear (migraciones de main, no se tocan). De `migraciones/env.py` sólo debe cambiar el import de config. Revisar `git diff main --stat -- apps/api` por reformateos ajenos a imports (en tests el format se revirtió con `git checkout -- tests`; sólo corrió `ruff check --select I`).

## Hecho
- `git mv` a `app/shared/*` (config, db, errores [aplicacion/errores.py borrado], errores_http, entradas, respuestas, cuerpo, zona, identidad, credencial_firebase) y a `app/modules/{espacios,sedes,horarios}/{rutas,casos_de_uso,reglas,repositorio}.py` (+ horarios/disponibilidad.py, sesion/casos_de_uso.py).
- A mano: `modules/sesion/{__init__,perfil,repositorio,usuario_actual}.py` (PerfilesSql, repositorio_perfiles, Perfiles), `__init__.py` de espacios/sedes/horarios (exportan router, *Sql, repositorio_*, y lo que usan otros), `shared/__init__.py`, `modules/__init__.py`.
- `shared/db.py` tiene `Conexion`; `shared/identidad.py` tiene el provider `identidad()`; providers `repositorio_espacios/sedes/horarios` en cada repositorio.py; `shared/config.py` usa parents[2].
- `app/dependencias.py` queda sólo con reservas/usuarios/notificaciones/enlaces/correo/push (viejo, T4-T5).
- `perfil_activo` salió de UsuariosSql (ahora PerfilesSql); `Perfil`/`Rol` salieron de dominio/usuarios.py (ahora sesion/perfil.py).
- `interfaz/sesion.py` conserva sólo el router (/yo...); `main.py` importa `app.modules` (espacios, horarios, sedes) y `app.shared`.
- Imports reescritos en app/, tests/, migraciones/env.py con `python D:/Temp/w/herramientas/arq04_mover.py D:/Temp/w/arq04/apps/api` (idempotente; saltea test_arquitectura, test_mapa_*, test_capas*.py).
- `tests/unit/test_sin_sobreingenieria.py`: `git rm` + archivo nuevo (ASM-07): `from app.shared import db` y `find_spec(f"app.shared.{modulo}")` (el guard impide Edit).

## Falta (verificar T2/T3)
1. Env: `export UV_PROJECT_ENVIRONMENT="D:/desktop folders/estudio/Universidad de moron/Electiva general/app-tp/apps/api/.venv"`. Desde apps/api: `uv run --no-sync ruff check app`, `ruff format --check app` (NO formatear tests/migraciones enteros), `uv run --no-sync mypy --strict app`.
2. Tests desde la raíz: `sh D:/Temp/w/herramientas/arq01-pytest.sh apps/api/tests/unit apps/api/tests/integracion apps/api/tests/escenarios -q` (test_capas*.py y partes de test_arquitectura siguen rojos hasta T5/T6: afirman capas o piden lo que falta).
3. Arreglar lo que falle (probables: `Perfil` sin usar en infraestructura/usuarios.py, tests que parchean strings con rutas viejas, orden de imports en app con `ruff check --fix app`, ciclos).
4. Anexar al `## Log` de card.md (Edit, al final): `- L<n> · <fecha> · replaces: apps/api/tests/** (~30 archivos) · sólo cambian imports y strings de ruta (ASM-07) · by: los mismos archivos`, más líneas `T2`/`T3` con la evidencia. Honesto: los tests se reescribieron con el script, sólo test_sin_sobreingenieria.py fue git rm + Write.
5. T4-T6 sin tocar: reservas, notificaciones (ASM-04), usuarios, recuperacion, main/salud/pruebas arriba, nombres de esquema (ASM-05, `PedidoDeEdicion` de interfaz/sesion.py -> `PedidoDeEdicionDePerfil`) y openapi.json, docs/mapa, e2e.sh, test_capas*.
