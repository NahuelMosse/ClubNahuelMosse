# Implementation Plan: CU-09 · Reservar cancha

**Branch**: `card/CU-09` | **Date**: 2026-09-28 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

«Confirmá tu reserva» suma CONFIRMAR RESERVA: la app manda a la API el espacio, el día, la hora
de inicio y la duración, y la API vuelve a validar el horario (RF 3) y guarda la reserva activa
con el precio de ese momento. La base impide dos reservas activas superpuestas del mismo
espacio: la que pierde recibe 409 y la app muestra «Ese horario se ocupó» y vuelve a la grilla,
que se lee de nuevo. El comprobante espera a que la persona vaya a Mis reservas o al inicio.
Si la sesión venció, la elección queda guardada y, al volver a entrar con la misma cuenta, la
app abre la confirmación otra vez.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Storage**: la tabla `reserva` de la migración inicial, con su restricción de exclusión
**Testing**: escenarios de API (`tests/escenarios/test_reservar.py`) para los rechazos del
backend; `integration_test` para el flujo en pantalla; unitarios de `validar_reserva`;
integración de `POST /reservas`; widget de la confirmación

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Quince escenarios; pantallas 48:123, 48:183 y 393:6553 (decisión 12) |
| II · Nada se supone en silencio | `CU-09-SUP-01` a `SUP-07`; AMB-02, 03, 05, 07, 08, 10 y 12 resueltas |
| III · Tests antes del código | Congelados en rojo en `185537f`; H01-07 y H03-01 nacieron en verde por CU-12 |
| IV · El backend es la autoridad | La API valida horario, cuenta y espacio, y la base decide la superposición |
| V · Rastro | La reserva guarda autor, creación y precio del momento (decisión 4) |

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-09-SUP-01 | Se puede reservar a la misma hora en espacios distintos | la exclusión es por espacio |
| CU-09-SUP-02 | Sin tope; el administrador no reserva | `reservar` (403) |
| CU-09-SUP-03 | Gana una sola; la otra ve «Ese horario se ocupó» | `EXCLUDE` de `reserva`, `HorarioOcupado`; `@CU-09-H02-01`, `@CU-09-H02-02` |
| CU-09-SUP-04 | El comprobante espera | `PantallaReservaConfirmada`; `@CU-09-H01-09` |
| CU-09-SUP-05 | Tras la sesión vencida, vuelve a la confirmación con la misma cuenta | `ReservaPendiente`, `PantallaInicioSesion`; `@CU-09-H04-01` |
| CU-09-SUP-06 | Un pedido repetido dentro de cinco minutos devuelve la misma reserva | `ReservasSql.insertar` |
| CU-09-SUP-07 | Lo que falta se dice en los horarios | CU-12; `@CU-09-H03-01` |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/app/dominio/horarios.py` | `validar_reserva` | la duración va de 1 a 4 horas y no pasa de la medianoche; el resto son las reglas de `validar_rango` |
| `apps/api/app/aplicacion/reservas.py` | `reservar` | primero busca el mismo pedido hecho hace un momento (un reintento puede llegar con el turno ya empezado); después valida con la agenda |
| `apps/api/app/infraestructura/reservas.py` | `ReservasSql.insertar`, `repetida` | toma compartidas la cuenta y la sede, y exclusivo el espacio: dos reservas del mismo espacio pasan de a una, así la segunda choca con la exclusión (23P01, `HorarioOcupado`) en vez de abortar por bloqueo mutuo; la sede se bloquea antes que el espacio, el orden que tiene que usar la baja de sede |
| `apps/api/app/interfaz/reservas.py` | `POST /reservas` | 409 con `horario`, 422 con los errores por campo o `espacio_id` |
| `apps/mobile/lib/reservas/reservas.dart` | `Reservas.reservar` | — |
| `apps/mobile/lib/reservas/pantalla_confirmar_reserva.dart` | la confirmación | se abre encima de los horarios y les devuelve si el horario se ocupó, así la grilla se vuelve a leer; mientras se guarda no se puede salir; el total que muestra es el precio que se vio, y la API cobra el del momento (si un día se edita el precio, eso se revisa en esa card) |
| `apps/mobile/lib/reservas/pantalla_reserva_confirmada.dart` | el comprobante | el nombre del espacio va debajo de su rótulo, en mono, para no partirse |
| `apps/mobile/lib/reservas/reserva_pendiente.dart` | la reserva en curso al vencer la sesión | vive mientras la app está abierta; una cuenta distinta la descarta |
| `apps/mobile/lib/comun/dialogo_error.dart` | `mostrarHorarioOcupado` | el mismo `Modal` que los demás avisos |

## Brief visual

**Invención 2 · densidad 3.** El paso final de cualquier reserva: una tarjeta con lo elegido y
un botón para confirmarla, y después el comprobante.

- **Desde dónde.** Desde la grilla de horarios; volver no pierde lo elegido.
- **Teléfono chico.** En 360 entran la tarjeta entera y los dos botones fijos abajo.
- **Variables visuales.** Lima = el horario, el total y la acción de confirmar; rojo = cancelar;
  verde = el comprobante.
- **Material.** El de la sede: foto con velo arriba de la tarjeta, superficie con borde fino y
  radio 20.
