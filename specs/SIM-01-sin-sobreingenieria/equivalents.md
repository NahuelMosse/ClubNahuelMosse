# Mutantes equivalentes

- apps/api/migraciones/versions/0009_avisos_sin_reintentos.py:15 · “None” → “0” · “"0008"branch_labels=@@depends_on=Nonedefup” · alembic descarta un `branch_labels` falso: la migración sube y baja igual y no hay ramas.
- apps/api/migraciones/versions/0009_avisos_sin_reintentos.py:16 · “None” → “0” · “bels=Nonedepends_on=@@defupgrade()->None:o” · alembic descarta un `depends_on` falso: la migración sube y baja igual y no hay otra revisión de la que dependa.
