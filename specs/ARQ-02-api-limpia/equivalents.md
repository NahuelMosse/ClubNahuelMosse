# Mutantes equivalentes

- apps/api/app/infraestructura/db.py:74 · “None” → “0” · “tattr(e.orig,"diag",@@),"constraint_name",” · el `IntegrityError` de psycopg siempre trae `diag` en su `orig`, así que el valor por defecto del `getattr` de afuera nunca se usa
- apps/api/app/infraestructura/db.py:74 · “None” → “0” · “),"constraint_name",@@)defbase_disponible(” · el `diag` de psycopg siempre tiene el atributo `constraint_name` (vale `None` si el motor no lo informa), así que el valor por defecto nunca se usa
