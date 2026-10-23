# Mutantes equivalentes

- apps/api/app/dominio/reservas.py:69 · “None” → “0” · “spues:Marcador|None=@@@dataclass(frozen=Tr” · el único constructor de `FiltrosHistorial` (interfaz/reservas.py) siempre pasa `despues` explícito, así que el valor por defecto del campo no se lee nunca.
- apps/api/migraciones/versions/0008_indices_y_cola_recuperable.py:13 · “None” → “0” · “bels=Nonedepends_on=@@#Siunlocknoseconsigu” · alembic descarta un `depends_on` falso: la migración sube y baja igual y no hay otra revisión de la que dependa.
