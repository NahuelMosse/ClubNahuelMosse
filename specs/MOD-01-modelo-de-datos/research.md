# Research: MOD-01 · Modelo de datos

## Superposición de reservas

- **Decision**: restricción `EXCLUDE USING gist (espacio_id WITH =, tstzrange(inicio, fin) WITH &&)
  WHERE (estado = 'activa')`, con la extensión `btree_gist`.
- **Rationale**: el enunciado exige que el backend valide la disponibilidad antes de registrar. Con
  la restricción en la base, dos confirmaciones simultáneas no pueden entrar las dos
  (CU-09-AMB-06); la aplicación sólo traduce el error.
- **Alternatives considered**: validar con un `SELECT` antes del `INSERT` — tiene carrera entre la
  consulta y la escritura; bloqueo de fila por espacio — funciona pero serializa todo el espacio.

## Estado de la reserva

- **Decision**: se guarda `activa`, `cancelada` o `anulada`; `completada` se deriva en la vista
  `reserva_con_estado` cuando una activa ya terminó.
- **Rationale**: «completada» depende del reloj. Guardarla obliga a un proceso que la actualice, y
  mientras no corre la base miente.
- **Alternatives considered**: tarea programada que marque completadas — un proceso más que
  mantener.

## Correo inmutable

- **Decision**: disparador `BEFORE UPDATE` que rechaza cambiar `usuario.correo`.
- **Rationale**: el enunciado dice que el perfil se edita «salvo la dirección de correo
  electrónico»; en la base la regla no depende de que cada endpoint se acuerde.
- **Alternatives considered**: sólo validar en el endpoint de edición.

## Fechas y horas

- **Decision**: `timestamptz` para inicio y fin de la reserva; `time` para apertura y cierre de la
  sede; zona horaria de la app `America/Argentina/Buenos_Aires`.
- **Rationale**: evita ambigüedad al comparar con «ahora» en el servidor en la nube.

## Enumeraciones

- **Decision**: texto con `CHECK (x IN (…))`.
- **Rationale**: agregar un valor es cambiar la restricción; un tipo `ENUM` de Postgres no admite
  quitar valores y complica las migraciones.
