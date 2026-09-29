# Implementation Plan: CU-11 · Modificar reserva

**Branch**: `card/CU-11` | **Date**: 2026-09-29 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

Cada próxima reserva que todavía no empezó tiene MODIFICAR en Mis reservas, al lado de CANCELAR.
MODIFICAR abre la grilla de horarios de esa cancha en modo modificación: el día de la reserva ya
elegido, la duración fija, la franja actual libre y marcada «(actual)», y CONTINUAR CON EL CAMBIO
deshabilitado mientras la elección sea la misma. «Confirmá el cambio» muestra el horario de antes,
el de ahora, la cancha, la fecha y el total nuevo. GUARDAR EL CAMBIO mueve la misma reserva (mismo
número) y el horario anterior queda libre. Si el horario nuevo se ocupó, el aviso compartido
«Esto cambió mientras tanto» vuelve a la grilla releída; si la reserva ya empezó o se anuló, a Mis
reservas.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Storage**: `UPDATE` de `inicio`, `fin`, `espacio_id` y `total` de la fila de `reserva`; la
restricción EXCLUDE de la tabla sigue siendo la que impide el solapamiento
**Testing**: `integration_test` con reservas cargadas por `/_pruebas/reservas`, `empezar` y
`anular`; integración de `POST /reservas/{id}/modificar` y de la grilla con `reserva_id`; widget
del flujo

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Diez escenarios; pantallas 49:434, 67:1089, 51:494 y 393:6532 |
| II · Nada se supone en silencio | `CU-11-SUP-01` a `SUP-08` |
| III · Tests antes del código | Diez escenarios congelados en rojo en `4840a22` |
| IV · El backend es la autoridad | La API decide si la reserva es de quien pide, si sigue activa y sin empezar, si el horario nuevo vale y si está libre |
| V · Rastro | La reserva conserva su número y su fecha de creación; el total se recalcula |

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-11-SUP-01 | La franja actual se ve libre y marcada «(actual)»; elegirla no habilita seguir | `PantallaHorarios._esLaActual`; `@CU-11-H04-01` |
| CU-11-SUP-02 | La reserva ajena es 404 | `ReservasSql.propia`, `POST /reservas/{id}/modificar` |
| CU-11-SUP-03 | Sin tope de modificaciones mientras siga activa y sin empezar | `modificar_reserva` |
| CU-11-SUP-04 | Misma duración; otra cancha del mismo tipo en la misma sede, otro día u otro horario | `modificar_reserva`; la grilla sin DURACIÓN |
| CU-11-SUP-05 | El total se recalcula con el precio del espacio nuevo | `ReservasSql.mover`; la confirmación lo muestra |
| CU-11-SUP-06 | El recordatorio sigue al horario vigente | CU-24.1 lo calcula de `inicio` |
| CU-11-SUP-07 | La grilla no cuenta como ocupada la reserva que se modifica, sólo si es de quien consulta | `GET /espacios/{id}/horarios?reserva_id`, `HorariosSql.ocupadas` |
| CU-11-SUP-08 | Vuelve a Mis reservas, releída, con «Reserva modificada» | `PantallaMisReservas._modificar`; `@CU-11-H01-01` |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/app/aplicacion/reservas.py` | `modificar_reserva` | exige la misma sede, deporte y tipo; mantiene la duración; valida el horario nuevo con las reglas de reservar; repetir un cambio que ya se hizo devuelve la reserva, como al reservar; un administrador no modifica |
| `apps/api/app/infraestructura/reservas.py` | `propia`, `tipo_de_espacio`, `mover` | la sede compartida, los espacios de antes y de ahora por número y recién después la reserva, en el mismo orden que al reservar: un cambio y una reserva, o dos cambios cruzados, se esperan en vez de trabarse; bajo el bloqueo se verifica que la reserva siga donde estaba; el solapamiento lo rechaza la base (23P01) |
| `apps/api/app/interfaz/reservas.py` | `POST /reservas/{id}/modificar`; `sede_id` en cada reserva | 404 si no es de quien pide, 409 `horario` si se ocupó, 409 `reserva` si ya no está activa o empezó, 422 por campo |
| `apps/api/app/interfaz/horarios.py` | `reserva_id` en la grilla | sólo excluye una reserva de quien consulta |
| `apps/mobile/lib/reservas/pantalla_mis_reservas.dart` | MODIFICAR | al lado de CANCELAR, apilados con el texto grande; cada botón nombra la reserva; al volver la lista se relee |
| `apps/mobile/lib/reservas/pantalla_horarios.dart` | el modo modificación | la misma pantalla con `modificando`: el aviso arriba, sin DURACIÓN, la franja actual marcada, el botón propio; si la cancha deja de estar disponible, «Esto cambió mientras tanto» y vuelta a Mis reservas |
| `apps/mobile/lib/reservas/pantalla_confirmar_cambio.dart` | «Confirmá el cambio» | la tarjeta de la confirmación de reserva con ANTES y AHORA; devuelve a la grilla o a Mis reservas cómo terminó, así la grilla sólo se relee cuando el horario se ocupó |

## Brief visual

**Invención 1 · densidad 3.** Cambiar un turno como en cualquier app de reservas: la misma grilla
que ya se conoce, con lo que no se puede cambiar fuera de la vista, y una confirmación que dice
qué se deja y qué se toma.

- **Desde dónde.** Desde la tarjeta de la reserva en Mis reservas; la grilla vuelve a Mis
  reservas.
- **Teléfono chico.** En 360 el aviso, las canchas y la fecha quedan arriba y CONTINUAR CON EL
  CAMBIO fijo abajo; en la confirmación ANTES y AHORA quedan a la vista sin scroll.
- **Variables visuales.** Lima = lo elegido y el horario nuevo; rojo con cruz = el horario que se
  deja; «(actual)» = el horario vigente.
- **Material.** El de la grilla y la confirmación de CU-09 y CU-12; los overlays compartidos.
- **Decisión.** El camino de vuelta de la grilla dice «Mis reservas», porque es a donde vuelve;
  el prototipo repite «Sedes» de CU-12.
