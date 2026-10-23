# Mutantes equivalentes

- apps/api/app/dominio/reservas.py:69 · “None” → “0” · “spues:Marcador|None=@@@dataclass(frozen=Tr” · el único constructor de `FiltrosHistorial` (interfaz/reservas.py) siempre pasa `despues` explícito, así que el valor por defecto del campo no se lee nunca.
