# Tasks: MOD-01 · Modelo de datos

**Input**: `plan.md`, `data-model.md`, `research.md`
**Tests**: los escenarios ya están escritos y congelados en `apps/api/tests/escenarios/test_modelo.py`.

## Phase 1: Setup

- [ ] T001 Entorno de la API con `uv` y dependencias en `apps/api/pyproject.toml`
- [ ] T002 Configuración de Alembic en `apps/api/alembic.ini` y `apps/api/migraciones/`
- [ ] T003 `scripts/test.sh` corre ruff, mypy y pytest

## Phase 2: Foundational

- [ ] T004 Fixtures de base de pruebas y filtro `--card` en `apps/api/tests/conftest.py`

## Phase 3: Modelo (escenarios MOD-01-H01-01 a H01-06)

- [ ] T005 [P] `nombre_compuesto` en `apps/api/app/dominio/espacios.py` (H01-03)
- [ ] T006 [P] Unitarios de `nombre_compuesto` en `apps/api/tests/unit/test_nombre_compuesto.py`
- [ ] T007 Migración `0001_modelo_inicial`: tablas `usuario`, `sede`, `espacio`, `reserva` (H01-01 a H01-04)
- [ ] T008 En la misma migración: disparador de correo inmutable y de `modificado_en` (H01-01)
- [ ] T009 En la misma migración: `btree_gist` y la restricción `EXCLUDE` de superposición (H01-05)
- [ ] T010 En la misma migración: vista `reserva_con_estado` (H01-06)

## Phase 4: Polish

- [ ] T011 `ruff check`, `mypy --strict app` y la suite entera en verde con `scripts/test.sh`

## Dependencies

T001 → T002 → T004 → T007 → T008, T009, T010. T005 y T006 son independientes.
