# Data Model: MOD-01

Ninguna fila se borra: las bajas son lógicas y un disparador rechaza el `DELETE`. Todas las tablas llevan `creado_en timestamptz NOT NULL DEFAULT now()` y `modificado_en
timestamptz NOT NULL DEFAULT now()`, que un disparador actualiza en cada `UPDATE`.

## usuario

| Campo | Tipo | Reglas |
|---|---|---|
| id | bigint identity | PK |
| firebase_uid | text | único, no nulo |
| correo | text | único sin distinguir mayúsculas entre las cuentas activas, no nulo, **no se puede cambiar** |
| nombre, apellido | text | no nulos |
| dni | text | 7 u 8 dígitos, único entre las cuentas activas |
| fecha_nacimiento | date | no nula; que sea pasada lo valida la API, porque depende del día |
| rol | text | `usuario` o `admin`, por defecto `usuario` |
| activo | boolean | por defecto `true` |
| dado_de_baja_en | timestamptz | nulo mientras está activo |

## sede

| Campo | Tipo | Reglas |
|---|---|---|
| id | bigint identity | PK |
| nombre | text | no nulo |
| calle | text | no nulo |
| altura | integer | positiva |
| apertura, cierre | time | en hora completa, apertura antes que cierre; cierre `00:00` es medianoche |
| dias | smallint[] | días de la semana que abre, 1 = lunes … 7 = domingo, al menos uno |
| activa | boolean | por defecto `true` |
| creado_por, modificado_por, dado_de_baja_por | bigint → usuario | autor de las acciones del admin |
| dado_de_baja_en | timestamptz | — |

## espacio

| Campo | Tipo | Reglas |
|---|---|---|
| id | bigint identity | PK |
| sede_id | bigint → sede | no nulo |
| deporte | text | no nulo |
| tipo | text | no nulo |
| numero | integer | positivo; único con (sede_id, deporte, tipo) |
| nombre | text | único; se guarda al crear y no cambia, igual que sede, deporte, tipo y número |
| techada, iluminada | boolean | no nulos |
| precio_por_hora | integer | pesos, mayor a cero |
| activo | boolean | por defecto `true` |
| creado_por, modificado_por, dado_de_baja_por | bigint → usuario | — |
| dado_de_baja_en | timestamptz | — |

## reserva

| Campo | Tipo | Reglas |
|---|---|---|
| id | bigint identity | PK |
| usuario_id | bigint → usuario | no nulo |
| espacio_id | bigint → espacio | no nulo |
| inicio, fin | timestamptz | fin posterior a inicio; minuto y segundo en cero; entre 1 y 4 horas |
| precio_por_hora, total | integer | precio del momento en que se reservó; total = precio × horas |
| estado | text | `activa`, `cancelada` o `anulada`, por defecto `activa` |
| cancelada_en | timestamptz | — |
| cancelada_por | bigint → usuario | el usuario que canceló o el admin que anuló |
| motivo | text | obligatorio si está anulada |

**Restricción**: dos reservas `activa` del mismo espacio no se superponen (`EXCLUDE`).

## Vista reserva_con_estado

Todas las columnas de `reserva` más `estado_actual`: `completada` si está activa y `fin <= now()`;
si no, el `estado` guardado.

## Relaciones

- sede 1 — N espacio
- usuario 1 — N reserva
- espacio 1 — N reserva
