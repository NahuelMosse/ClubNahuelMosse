# Mutantes equivalentes

- apps/api/migraciones/versions/0009_avisos_sin_reintentos.py:13 · “None” → “0” · alembic descarta un `branch_labels` falso: la migración sube y baja igual y no hay ramas.
- apps/api/migraciones/versions/0009_avisos_sin_reintentos.py:14 · “None” → “0” · “bels=Nonedepends_on=@@defupgrade()->None:o” · alembic descarta un `depends_on` falso: la migración sube y baja igual y no hay otra revisión de la que dependa.
