# Implementation Plan: CU-10 · Cancelar reserva

**Branch**: `card/CU-10` | **Date**: 2026-09-28 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

Cada próxima reserva que todavía no empezó tiene CANCELAR en Mis reservas. Tocarlo pide
confirmación con el detalle del turno; al confirmar, la API cancela la reserva, estampa cuándo
y quién, y el horario vuelve a quedar libre. La app avisa el éxito y vuelve a leer la lista: la
reserva sale de Próximas y aparece como CANCELADA en el Historial. Si la reserva ya no está
activa o empezó mientras tanto, el aviso compartido «Esto cambió mientras tanto» actualiza la
lista.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Storage**: las columnas `estado`, `cancelada_en` y `cancelada_por` de `reserva`
**Testing**: `integration_test` con reservas de la cuenta cargadas por `/_pruebas/reservas` y
`/_pruebas/reservas/empezar`; integración de `POST /reservas/{id}/cancelar`; widget del flujo

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Seis escenarios; pantallas 42:296, 42:312 y 393:6532 (decisión 12) |
| II · Nada se supone en silencio | `CU-10-SUP-01` a `SUP-05`; AMB-02, 03, 06, 07 y 08 resueltas |
| III · Tests antes del código | Seis escenarios congelados en rojo en `67f6c58` |
| IV · El backend es la autoridad | La API decide si la reserva es de quien pide, si sigue activa y si ya empezó |
| V · Rastro | `cancelada_en` y `cancelada_por` (decisión 4) |

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-10-SUP-01 | Cancelar dos veces responde igual | `ReservasSql.cancelar` |
| CU-10-SUP-02 | La reserva ajena es 404 | `ReservasSql.cancelar`, `POST /reservas/{id}/cancelar` |
| CU-10-SUP-03 | Si ya no está activa, «Esto cambió mientras tanto» | `mostrarCambioMientrasTanto`; `@CU-10-H05-01` |
| CU-10-SUP-04 | Una reserva en curso no ofrece CANCELAR | `cancelable` de la API, `TarjetaReserva`; `@CU-10-H05-01` |
| CU-10-SUP-05 | El overlay compartido del servidor | `mostrarErrorDeRed`; `@CU-10-H04-01` |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/app/infraestructura/reservas.py` | `ReservasSql.cancelar` | la fila se toma exclusiva: dos cancelaciones o una cancelación y una anulación pasan de a una |
| `apps/api/app/aplicacion/reservas.py` | `cancelar_reserva` | hasta el inicio, sin anticipación mínima (decisión 13) |
| `apps/api/app/interfaz/reservas.py` | `POST /reservas/{id}/cancelar`; `cancelable` en cada reserva | 404 si no es de quien pide, 409 si cambió |
| `apps/mobile/lib/reservas/pantalla_mis_reservas.dart` | CANCELAR y el flujo | CANCELAR aparece si la API dice que la reserva es `cancelable` (con su reloj, no el del teléfono); la tarjeta se lee como un dato y CANCELAR es un botón aparte que nombra deporte, día y horario; mientras se cancela, ese botón espera, los demás quedan deshabilitados y no se sale de la pantalla; la cancelada sale de Próximas apenas la API responde; después de un error, la lista se vuelve a leer por si la cancelación llegó igual |
| `apps/mobile/lib/comun/dialogo_error.dart` | la confirmación, el éxito y «Esto cambió mientras tanto» | el mismo `Modal`, con la acción que no se deshace en rojo |

## Brief visual

**Invención 1 · densidad 3.** Cancelar como en cualquier app: un botón rojo en la tarjeta, una
confirmación que dice qué se pierde y un aviso de que salió bien.

- **Desde dónde.** Desde la tarjeta de la reserva en Mis reservas.
- **Teléfono chico.** En 360 el botón ocupa el ancho de la tarjeta, debajo de sus datos.
- **Variables visuales.** Rojo = lo que no se deshace; verde = el éxito.
- **Material.** Los overlays compartidos del prototipo.
