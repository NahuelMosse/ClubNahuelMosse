# Handoff ARQ-04 T2+T3 (worktree D:/Temp/w/arq04)

## Hecho (committed as WIP, sin verificar)
- `git mv` a `app/shared/*` (config, db, errores [+ aplicacion/errores.py borrado], errores_http, entradas, respuestas, cuerpo, zona, identidad, credencial_firebase) y a `app/modules/{espacios,sedes,horarios}/{rutas,casos_de_uso,reglas,repositorio}.py` (+ horarios/disponibilidad.py, sesion/casos_de_uso.py).
- Escritos a mano: `modules/sesion/{__init__,perfil,repositorio,usuario_actual}.py` (PerfilesSql, repositorio_perfiles, Perfiles), `__init__.py` de espacios/sedes/horarios (exportan router, *Sql, repositorio_*, y lo que otros usan), `shared/__init__.py`, `modules/__init__.py`.
- `shared/db.py` tiene `Conexion`; `shared/identidad.py` tiene el provider `identidad()`; providers `repositorio_espacios/sedes/horarios` en cada repositorio.py.
- `app/dependencias.py` reducido a reservas/usuarios/notificaciones/enlaces/correo/push (viejo, T4-T5).
- `UsuariosSql.perfil_activo` y `Perfil`/`Rol` salieron de infraestructura/usuarios.py y dominio/usuarios.py (ahora en sesion).
- `interfaz/sesion.py` conserva sólo el router (/yo...), importa de `app.modules.sesion`; `main.py` importa `app.modules` (espacios, horarios, sedes) y `app.shared`.
- Imports reescritos en app/, tests/ y migraciones/env.py con `D:/Temp/w/herramientas/arq04_mover.py <apps/api>` (idempotente; saltea test_arquitectura, test_mapa_*, test_capas*.py). `shared/config.py`: RAIZ_API = parents[2].
- tests/unit/test_sin_sobreingenieria.py: `git rm` + archivo nuevo (ASM-07): `from app.shared import db` y `find_spec(f"app.shared.{modulo}")`.
- Se verificó solo: `python -c "import app.main"` sin error (antes del cambio de parents[2] ya corregido).

## Falta (verificar T2/T3)
1. Correr (desde la raíz del worktree, con UV_PROJECT_ENVIRONMENT del venv compartido): `ruff check app`, `ruff format --check app` (NO formatear tests enteros: mete ruido), `mypy --strict app` (desde apps/api, `uv run --no-sync`), y tests: `sh D:/Temp/w/herramientas/arq01-pytest.sh apps/api/tests/unit apps/api/tests/integracion` (ignorar test_capas*.py, que afirman capas y se reemplazan en T5/T6) y tests/escenarios.
2. Arreglar lo que falle (posibles: imports sin ordenar `ruff check --fix`, `Perfil` sin usar en infraestructura/usuarios.py, tests que parchean strings con rutas viejas, ciclos).
3. Anexar al `## Log` de card.md (Edit, al final): `- L<n> · <fecha> · replaces: apps/api/tests/** (≈31 archivos con imports a rutas viejas) · sólo cambian imports/strings de ruta (ASM-07) · by: los mismos archivos`, y una línea `T2`/`T3` con evidencia. Nota honesta: los tests se reescribieron con el script, no archivo por archivo con git rm (sólo test_sin_sobreingenieria.py fue git rm + Write por el guard).
4. Commit por tarea (T2, T3) si se quiere separar; hoy es un solo WIP.
5. T4-T6 sin tocar: reservas, notificaciones (ASM-04 dataclass), usuarios, recuperacion, main/salud/pruebas arriba, nombres de esquemas (ASM-05) y openapi.json, docs/mapa; test_arquitectura sigue rojo hasta T5.
6. interfaz/sesion.py: su `PedidoDeEdicion` renombrar en T5 a `PedidoDeEdicionDePerfil`.
