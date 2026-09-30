# Implementation Plan: CU-19 · Dar de baja sede

**Branch**: `card/CU-19` | **Date**: 2026-09-29 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

DAR DE BAJA LA SEDE, en la edición, y «Dar de baja», en la tarjeta del panel, piden
confirmación con el nombre y la dirección de la sede. Al confirmar, la API da de baja la sede y
sus espacios (baja lógica, con fecha y autor), y la app vuelve al listado con «La sede fue dada
de baja correctamente». Si la sede tiene reservas activas que todavía no terminaron, la baja no
se hace y se avisa. Si ya la dio de baja otra sesión, «Esto cambió mientras tanto» y el listado.
Con un error de red, el aviso compartido y la sede intacta.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Storage**: `activa`, `dado_de_baja_en` y `dado_de_baja_por` de `sede`, y `activo`,
`dado_de_baja_en` y `dado_de_baja_por` de sus espacios
**Testing**: `integration_test` con sedes, espacios y reservas cargadas por la API y
`/_pruebas`; integración de `DELETE /sedes/{id}`; widget del flujo

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Siete escenarios; pantallas 62:1648, 62:1968, 42:329, 42:345, 393:6532 y 42:410 |
| II · Nada se supone en silencio | `CU-19-SUP-01` a `SUP-06`; AMB-01, 04 y 05 resueltas |
| III · Tests antes del código | Siete escenarios congelados en rojo en `a72ed3a` |
| IV · El backend es la autoridad | La API decide si la sede sigue activa y si tiene reservas pendientes |
| V · Rastro | Baja lógica con fecha y autor en la sede y en cada espacio (decisión 4) |

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-19-SUP-01 | Una reserva en curso también impide la baja | `SedesSql.dar_de_baja` (`fin > now()`) |
| CU-19-SUP-02 | La baja toma la sede exclusiva | `SedesSql.dar_de_baja` |
| CU-19-SUP-03 | Desde la edición y desde la tarjeta; el aviso en el listado | `darDeBajaSede`, `TarjetaSedeAdmin`; `@CU-19-H01-03` |
| CU-19-SUP-04 | No se reactiva; el nombre queda libre | índice `sede_nombre_activa_unico` |
| CU-19-SUP-05 | Sus espacios se dan de baja con ella | `SedesSql.dar_de_baja`; `@CU-19-H01-02` |
| CU-19-SUP-06 | Los overlays compartidos para FA2 y FA4; el del prototipo para FA3 | `darDeBajaSede`, `mostrarSedeConReservas` |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/app/aplicacion/sedes.py` | `dar_de_baja_sede` | sólo un administrador; con reservas pendientes no se permite (decisión 5) |
| `apps/api/app/infraestructura/sedes.py` | `SedesSql.dar_de_baja` | la sede se toma exclusiva: una reserva que se está haciendo termina antes y cuenta, o espera y ve la sede inactiva; cuenta toda reserva activa que no terminó; espacios y sede en la misma transacción |
| `apps/api/app/interfaz/sedes.py` | `DELETE /sedes/{id}` | 204; 404 si no está activa; 409 `errores.sede` con reservas pendientes |
| `apps/mobile/lib/admin/baja_sede.dart` | la confirmación y el pedido | una sola función para la edición y la tarjeta; mientras el pedido está en camino, su botón espera y no se toca ninguna otra tarjeta ni el formulario; desde la edición termina en el listado, desde la tarjeta se queda; después de un corte, que la sede ya no esté es el éxito del pedido cortado |
| `apps/mobile/lib/admin/pantalla_sedes_admin.dart` | «Dar de baja» en la tarjeta | al lado de «Editar sede», apilados con cualquier agrandado del texto; cada uno nombra la sede |

## Brief visual

**Invención 1 · densidad 3.** Dar de baja como cualquier acción que no se deshace: un botón rojo,
una confirmación que dice qué se pierde y un aviso de que salió.

- **Desde dónde.** Desde la tarjeta de la sede en el panel o desde su edición; termina en el
  listado.
- **Teléfono chico.** En 360 «Editar sede» y «Dar de baja» van lado a lado; con el texto grande,
  uno abajo del otro.
- **Variables visuales.** Rojo = lo que no se deshace.
- **Material.** Los overlays compartidos del prototipo.
