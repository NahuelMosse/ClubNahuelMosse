# Implementation Plan: CU-08 · Consultar historial de reservas

**Branch**: `card/CU-08` | **Date**: 2026-09-28 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

«Mis reservas», desde la barra inferior, abre en Próximas: las reservas activas de quien
inició sesión que todavía no terminaron, de la más cercana a la más lejana. Historial trae las
completadas, canceladas y anuladas, de la más reciente a la más vieja, con el porqué de las
canceladas y anuladas. Cada tarjeta dice deporte y tipo, sede y dirección, el total que se
guardó al reservar, el estado, el espacio, la fecha y el horario en la hora del club.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Storage**: la tabla `reserva` y la vista `reserva_con_estado` de la migración inicial
**Testing**: `integration_test` con reservas de la cuenta cargadas por `/_pruebas/reservas`;
integración de `GET /reservas`; widget de la pantalla

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Nueve escenarios; pantallas 49:434, 49:544, 49:651 y 49:697 (decisión 12) |
| II · Nada se supone en silencio | `CU-08-SUP-01` a `SUP-09`; AMB-02 y 03 resueltas |
| III · Tests antes del código | Nueve escenarios congelados en rojo en `f17d8d3` |
| IV · El backend es la autoridad | La API decide de quién es cada reserva (el usuario de la sesión) y su estado de ahora |
| V · Rastro | No aplica: consulta de sólo lectura; muestra lo que estamparon la reserva y su cancelación |

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-08-SUP-01 | Sesión vencida: el overlay y al inicio de sesión | `PantallaMisReservas._cargar` |
| CU-08-SUP-02 | Sin paginación | `GET /reservas`; la pantalla construye todas las tarjetas |
| CU-08-SUP-03 | Próximas ascendente, historial descendente | `ReservasSql.de_usuario`; `@CU-08-H01-01`, `@CU-08-H01-03` |
| CU-08-SUP-04 | La reserva en curso sigue en Próximas | `reserva_con_estado` (activa hasta `fin`) |
| CU-08-SUP-05 | Cancelada o anulada va al Historial | `ReservasSql.de_usuario`; `@CU-08-H01-04` |
| CU-08-SUP-06 | Sin MODIFICAR ni CANCELAR hasta CU-11 y CU-10 | `TarjetaReserva` |
| CU-08-SUP-07 | Textos de cancelada y anulada del prototipo | `TarjetaReserva._porque`; `@CU-08-H01-04` |
| CU-08-SUP-08 | El total guardado al reservar | `reserva.total`; `@CU-08-H01-01` |
| CU-08-SUP-09 | La próxima reserva del inicio es de TP-01 | — |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/app/dominio/reservas.py` | `Reserva`, `Estado` | — |
| `apps/api/app/aplicacion/reservas.py` | `mis_reservas` | sólo las del perfil de la sesión |
| `apps/api/app/infraestructura/reservas.py` | `ReservasSql.de_usuario` | lee `reserva_con_estado`, así una activa que terminó es completada sin que nadie la actualice |
| `apps/api/app/interfaz/reservas.py` | `GET /reservas?cuando=proximas|historial` | — |
| `apps/mobile/lib/reservas/reservas.dart` | `Reservas.mias`, `Reserva` | las horas se pasan a la del club (UTC−3) |
| `apps/mobile/lib/reservas/pantalla_mis_reservas.dart` | la pantalla y `TarjetaReserva` | cambiar de pestaña vuelve a pedir la lista y descarta la respuesta de la otra; con el texto grande, precio y estado bajan debajo del título |
| `apps/api/tests/integracion/conftest.py` | cuentas y sede de prueba | los comparten los tests de espacios y de reservas |

## Brief visual

**Invención 2 · densidad 5.** La lista de reservas de cualquier app: una tarjeta por reserva con
el estado a la vista.

- **Desde dónde.** Desde la pestaña RESERVAS de la barra inferior.
- **Teléfono chico.** En 360 entran el título, las pestañas y la primera tarjeta entera.
- **Variables visuales.** Lima = el horario y el total; verde = ACTIVA; rojo = ANULADA y su
  motivo; gris = completada y cancelada.
- **Material.** El de las tarjetas de la sede: superficie con borde fino y radio 20, la foto del
  deporte en miniatura.
