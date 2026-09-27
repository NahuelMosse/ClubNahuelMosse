# Implementation Plan: MOD-01 · Modelo de datos

**Branch**: `card/MOD-01` | **Date**: 2026-09-27 | **Spec**: [card.snapshot.md](card.snapshot.md)

**Input**: `specs/MOD-01-modelo-de-datos/card.snapshot.md` y `ambiguedades.md`

## Summary

Esquema de PostgreSQL de las cuatro entidades que fija el enunciado —usuario, sede, espacio
deportivo y reserva—, con las reglas que la base puede garantizar sola: correo inmutable, espacio
único por sede, tipo y número, y reservas activas que no se superponen en el mismo espacio. El
esquema se crea con migraciones de Alembic. Como es la primera card del repo, monta además el
andamio de la API y de la suite.

## Technical Context

**Language/Version**: Python 3.13 (compatible con 3.12)
**Primary Dependencies**: SQLAlchemy 2, Alembic, psycopg 3, pydantic-settings; FastAPI queda
instalado para las cards siguientes
**Storage**: PostgreSQL 16, con la extensión `btree_gist` para la restricción de superposición
**Testing**: pytest contra una base PostgreSQL real en Docker; ruff y mypy estricto
**Target Platform**: servidor Linux en la nube; desarrollo en Windows
**Project Type**: API REST para una app móvil
**Performance Goals**: no aplica a esta card
**Constraints**: la superposición la garantiza la base, no sólo la aplicación (constitución IV)
**Scale/Scope**: 4 tablas, 1 vista, 1 función de dominio

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | La card es el texto del enunciado congelado; los seis escenarios salen de ahí |
| II · Nada se supone en silencio | Cinco ambigüedades resueltas por decisión del usuario; una vencida a `MOD-01-SUP-01` |
| III · Tests antes del código | Seis escenarios en `apps/api/tests/escenarios/test_modelo.py`, commiteados en rojo |
| IV · El backend es la autoridad | La superposición es una restricción `EXCLUDE` de la base |
| V · Rastro | `creado_en` y `modificado_en` en todas las tablas, autor en las acciones del admin, precio de la reserva guardado; bajas lógicas |

Sin violaciones.

## Project Structure

### Documentation (this feature)

```text
specs/MOD-01-modelo-de-datos/
├── card.snapshot.md
├── ambiguedades.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── tasks.md
```

### Source Code (repository root)

```text
apps/api/
├── pyproject.toml
├── alembic.ini
├── app/
│   ├── config.py
│   └── dominio/
│       └── espacios.py
├── migraciones/
│   ├── env.py
│   └── versions/0001_modelo_inicial.py
└── tests/
    ├── conftest.py
    ├── escenarios/test_modelo.py
    └── unit/test_nombre_compuesto.py
scripts/test.sh
```

**Structure Decision**: `apps/api` para el backend y, desde la primera card con pantalla,
`apps/mobile` para la app, como fija `.claude/STACK.md`.

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/pyproject.toml` | dependencias y configuración de pytest, ruff y mypy | `uv` maneja el entorno dentro de `apps/api/.venv` |
| `apps/api/uv.lock` | versiones exactas de las dependencias | lo genera `uv`; se versiona |
| `apps/api/app/__init__.py` | paquete de la aplicación | vacío |
| `apps/api/app/config.py` | lee `DATABASE_URL` del entorno o de `.env` | un solo objeto `config`; nada más lee variables de entorno |
| `apps/api/app/dominio/__init__.py` | paquete del dominio | el dominio no importa SQLAlchemy ni nada de afuera |
| `apps/api/app/dominio/espacios.py` | `nombre_compuesto(sede, calle, altura, deporte, tipo, numero)` | función pura. Saca el prefijo «Sede» y los de calle («Av.», «Avenida», «Calle»), quita tildes y espacios, une con `_`. El número lo asigna CU-21 |
| `apps/api/alembic.ini`, `migraciones/env.py`, `migraciones/script.py.mako` | configuración de Alembic | la URL sale de `config` salvo que la pase quien invoca |
| `apps/api/migraciones/versions/0001_modelo_inicial.py` | crea las cuatro tablas, la vista y los disparadores | ver `data-model.md`. Enums como `CHECK` sobre texto, no tipos de Postgres, para que agregar un estado sea una migración de una línea |
| `apps/api/tests/conftest.py` | motor contra la base de pruebas, migra una vez por sesión, transacción por test, filtro `--card` | la base de pruebas se recrea entera al arrancar la sesión |
| `apps/api/tests/escenarios/test_modelo.py` | los seis escenarios de la card | congelado en el paso 4 |
| `apps/api/tests/unit/test_nombre_compuesto.py` | casos borde de `nombre_compuesto` | del implementador |
| `apps/api/tests/unit/test_arquitectura.py` | el dominio no importa nada de afuera | lee los `import` con `ast` |
| `apps/api/tests/integracion/test_restricciones.py` | restricciones del esquema sin escenario: zona horaria, total, duración, motivo, medianoche, días, borrado, identidad del espacio, `creado_en`, baja que libera correo y DNI | del implementador |
| `scripts/test.sh` | corre todo lo que cuenta | ruff, mypy, pytest y, cuando exista, la app |
| `.gitignore` | ignora `.venv` y cachés | — |
| `specs/MOD-01-modelo-de-datos/*` | snapshot, ambigüedades, plan, research, data-model, quickstart y tasks | — |
| `specs/CU-07-dar-cuenta-de-baja/ambiguedades.md` | registra `CU-07-SUP-01`, que el esquema toma | append |

## Supuestos

| ID | Supuesto | Dónde vive |
|---|---|---|
| MOD-01-SUP-01 | Notificaciones y tokens de dispositivo no se modelan acá; los crea CU-24.1 | sin cobertura |
| CU-07-SUP-01 | Una cuenta dada de baja libera su correo y su DNI: se puede volver a registrar | `tests/integracion/test_restricciones.py::test_la_baja_libera_el_correo_y_el_dni` |

## Supuestos sin cobertura

| ID | Motivo |
|---|---|
| MOD-01-SUP-01 | Es la decisión de no crear tablas: no hay comportamiento que un test pueda ejercitar |

## Perímetro

- **Auth**: ninguna. El `firebase_uid` se guarda como texto; lo valida la card de login.
- **Mocks**: ninguno. Los tests corren contra PostgreSQL 16 real en Docker.
- **Afuera**: endpoints HTTP, reglas que dependen de la hora actual o de la sede (horario futuro,
  cierre, duración contra el catálogo de la sede) — son de CU-09; la asignación del número del
  espacio — CU-21; roles y permisos — CU-01.

## Hallazgos de la revisión que no se corrigen acá

| Hallazgo | Motivo |
|---|---|
| Coherencia entre `estado` y `cancelada_en` | El escenario congelado `MOD-01-H01-05` cancela una reserva sin fecha de cancelación; la regla la hace cumplir CU-10 al cancelar |
| `join_transaction_mode="create_savepoint"` en la fixture | Todavía no hay `Session` bajo test; lo agrega la primera card que la use |
| Días repetidos en `sede.dias` (`{1,1}`) | Un `CHECK` no puede verificarlo sin una función auxiliar; la API normaliza la lista en CU-17 |

## Brief visual

No aplica: la card no toca pantallas.
