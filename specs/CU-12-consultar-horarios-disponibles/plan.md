# Implementation Plan: CU-12 · Consultar horarios disponibles

**Branch**: `card/CU-12` | **Date**: 2026-09-28 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

La pantalla de horarios de una cancha deja elegir la cancha de ese tipo en la sede, uno de los
próximos siete días y una duración de 1 a 4 horas, y pide a la API la grilla: cada hora de
inicio en punto que entra en el horario de la sede con esa duración y todavía no empezó, con las
que pisan una reserva activa atenuadas. Elegir una franja completa el resumen y habilita
CONTINUAR, que abre «Confirmá tu reserva» con lo elegido. Nada de esto reserva.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Storage**: la tabla `reserva` de la migración inicial; sin migraciones nuevas
**Testing**: `integration_test` con reservas de otra persona cargadas por `/_pruebas/reservas`;
unitarios de la grilla; integración de `GET /espacios/{id}/horarios`; widget con la grilla del
prototipo

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Catorce escenarios; pantallas 45:359, 67:984, 334:6228, 47:555 y 48:123 (decisión 12) |
| II · Nada se supone en silencio | `CU-12-SUP-01` a `SUP-10`; AMB-01, 02 y 06 resueltas |
| III · Tests antes del código | Los catorce escenarios congelados en rojo en `77ba1d1` |
| IV · El backend es la autoridad | La API arma la grilla con la hora del club y las reservas activas; la app no calcula disponibilidad |
| V · Rastro | No aplica: consulta de sólo lectura |

El escenario de CU-16 que llega a los horarios buscaba la etiqueta del esqueleto de esta
pantalla; se recongeló en `ed2c39b` con la de la tarjeta de cancha, «Cancha 1, Techada».

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-12-SUP-01 | Todas las horas de inicio que entran; las no disponibles atenuadas y sin tocar | `grilla`, `_TarjetaFranja`; `@CU-12-H01-02` |
| CU-12-SUP-02 | Se lee al entrar y en cada cambio; no se refresca sola | `_consultar` |
| CU-12-SUP-03 | Cada cancha es un espacio; las del mismo tipo en la sede, por número | `_cargar`, `_TarjetaCancha`; `@CU-12-H03-01` |
| CU-12-SUP-04 | Una franja que ya empezó no se ofrece | `grilla` (`inicio > ahora`); `@CU-12-H01-01` |
| CU-12-SUP-05 | Precio fijo del espacio; total = precio × horas | `_Resumen`, `Eleccion.total`; `@CU-12-H04-02` |
| CU-12-SUP-06 | Textos del estado vacío según la causa | `_porQueNoHay`; `@CU-12-H05-01`, `@CU-12-H05-02` |
| CU-12-SUP-07 | Textos y cuenta de la nota | `Grilla.no_disponibles`, `_Nota`; `@CU-12-H01-05`, `@CU-12-H04-01` |
| CU-12-SUP-08 | CONTINUAR abre «Confirmá tu reserva» con lo elegido | `PantallaConfirmarReserva`, `Eleccion`; `@CU-12-H01-03` |
| CU-12-SUP-09 | La hora elegida queda si sigue disponible | `_consultar` |
| CU-12-SUP-10 | Overlays compartidos; después, sin horarios y con REINTENTAR | `_avisar`; `@CU-12-H06-01`, `@CU-12-H07-01` |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/app/dominio/horarios.py` | `Agenda`, `Franja`, `Grilla`, `grilla`, `validar_consulta` | un cierre a las 00:00 es la medianoche del mismo día; la zona la trae `ahora` |
| `apps/api/app/aplicacion/horarios.py` | `horarios_disponibles` | sin fecha es hoy; `NoDisponible` si el espacio o su sede no están activos |
| `apps/api/app/infraestructura/horarios.py` | `HorariosSql.agenda`, `ocupadas` | sólo las reservas `activa` |
| `apps/api/app/interfaz/horarios.py` | `GET /espacios/{id}/horarios?fecha=&horas=` | 404 si la cancha ya no está; 422 fuera de los siete días o de 1 a 4 horas; devuelve `hoy` para que la app arme los días sin depender del reloj del teléfono |
| `apps/api/app/interfaz/pruebas.py` | `POST /_pruebas/reservas` | la reserva es de la primera cuenta de la base |
| `apps/mobile/lib/reservas/horarios.dart` | `Horarios.de`, `Grilla`, `Franja` | — |
| `apps/mobile/lib/reservas/pantalla_horarios.dart` | la pantalla | una respuesta que ya no es la última se descarta; mientras llega otra grilla, la anterior queda atenuada, sin tocar y con una barra de progreso; FECHA y DURACIÓN aparecen con la primera grilla, que trae el día de hoy |
| `apps/mobile/lib/reservas/pantalla_confirmar_reserva.dart` | «Confirmá tu reserva» | CANCELAR vuelve a los horarios; CONFIRMAR RESERVA es de CU-09; sin una elección, la ruta vuelve a los horarios |
| `apps/mobile/lib/reservas/eleccion.dart`, `fechas.dart` | lo elegido y los textos de fecha y duración | — |

## Brief visual

**Invención 2 · densidad 5.** Un selector de turnos como el de cualquier app de reservas: lo
elegido en lima, lo que no se puede elegir atenuado.

- **Desde dónde.** Desde la cancha que se tocó en la sede; cambiar de cancha, día o duración no
  saca de la pantalla.
- **Teléfono chico.** En 360 entran la cancha, los días que se deslizan, la duración y el
  comienzo de la grilla; CONTINUAR queda fijo abajo. En 430 entra más grilla.
- **Variables visuales.** Lima = elegido; atenuado al 45 % = no disponible (sin piso de
  contraste por ser un control inactivo, WCAG 1.4.3); el total en lima es la cifra que manda.
- **Material.** El de la sede: foto con velo arriba, superficies con borde fino y radio 12 en
  los controles, 20 en el resumen; la tipografía y la escala del tema.
