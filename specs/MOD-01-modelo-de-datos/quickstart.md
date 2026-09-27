# Quickstart: MOD-01

## Requisitos

- Docker, con PostgreSQL 16 escuchando en el puerto de `TEST_DATABASE_URL`.
- `uv` para el entorno de Python.

## Correr

```sh
cd apps/api
uv sync
TEST_DATABASE_URL=postgresql+psycopg://club:club@localhost:<puerto>/club_test uv run pytest --card MOD-01
```

## Qué se espera

Los seis escenarios `@MOD-01-H01-01` a `@MOD-01-H01-06` en verde. La sesión borra y recrea el
esquema de la base de pruebas y aplica las migraciones desde cero, así que también verifica que
`alembic upgrade head` funciona sobre una base vacía.
