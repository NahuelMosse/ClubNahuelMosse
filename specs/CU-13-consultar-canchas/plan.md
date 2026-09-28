# Implementation Plan: CU-13 · Consultar canchas

**Branch**: `card/CU-13` | **Date**: 2026-09-28 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

Desde el inicio, «Buscar cancha» abre «Consultar canchas»: sede, deporte, tipo (opcional),
fecha y un rango DESDE–HASTA en horas en punto. La app bloquea la consulta mientras el rango no
cumple las reglas del enunciado y muestra el error en su campo; al consultar, la API devuelve
las canchas de esa sede sin reservas activas que pisen el rango. El resultado se filtra por
condición con chips y cada cancha lleva a su grilla con el día, la duración y la hora ya
elegidos. Consultar no reserva nada.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Storage**: sin cambios
**Testing**: `integration_test` con reservas de otra persona por `/_pruebas/reservas`;
unitarios de `validar_rango` y de `erroresDelRango`; integración de `GET /espacios/disponibles`;
widget de la pantalla

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Diez escenarios; pantallas 52:734, 52:1085, 52:824, 52:963, 201:6295 y el acceso de 37:147 (decisión 12) |
| II · Nada se supone en silencio | `CU-13-SUP-01` a `SUP-12`; AMB-01, 03 y 09 resueltas |
| III · Tests antes del código | Diez escenarios congelados en rojo en `1d5ee15` |
| IV · El backend es la autoridad | La API vuelve a validar el rango y decide qué canchas están libres; la app sólo evita consultas que la API rechazaría |
| V · Rastro | No aplica: consulta de sólo lectura |

Los escenarios se recongelaron dos veces: en `d5d1b28` la fecha pasó a «DD / MM / AAAA», el
formato del campo en el prototipo y en el registro; en `e8b8a39` H01-03 ocupa la Cancha 2
para que el resultado traiga una sola cancha que tocar.

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-13-SUP-01 | Sólo espacios activos de sedes activas | `HorariosSql.libres`, `agenda_de_sede` |
| CU-13-SUP-02 | Por deporte, tipo y número | `HorariosSql.libres` |
| CU-13-SUP-03 | El resultado no se refresca solo | `PantallaBuscarCancha._consultar` |
| CU-13-SUP-04 | Cada cancha abre su grilla con día, duración e inicio | `_aLosHorarios`, `PantallaHorarios(fecha, horas, inicio)`; `@CU-13-H01-03` |
| CU-13-SUP-05 | Sede, deporte, fecha y rango obligatorios; tipo opcional | `_completo`; `@CU-13-H03-01` |
| CU-13-SUP-06 | Un rango que ya empezó no es futuro | `validar_rango`, `erroresDelRango` |
| CU-13-SUP-07 | Fecha escrita o de calendario de 7 días; horas en punto; HASTA 00:00 es medianoche | `FormatoFecha`, `elegirDiaProximo`, `_elegirHora`; `@CU-13-H03-03` |
| CU-13-SUP-08 | Los mensajes de error por campo | `validar_rango`, `erroresDelRango`; `@CU-13-H03-01` a `H03-03` |
| CU-13-SUP-09 | Encabezado, subtítulo y chips de condición | `_resultados`, `_subtitulo`; `@CU-13-H01-01` |
| CU-13-SUP-10 | La tarjeta de error del prototipo para conexión y servidor | `_TarjetaError`; `@CU-13-H04-01`, `@CU-13-H05-01` |
| CU-13-SUP-11 | Cambiar un filtro quita el resultado | `_alCambiarFiltro`; `@CU-13-H01-04` |
| CU-13-SUP-12 | Se entra desde «Buscar cancha» del inicio | `PantallaInicio`, `/inicio/buscar` |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/app/dominio/horarios.py` | `rango`, `validar_rango` | los errores del rango se juntan por campo; una hora que no es en punto corta la validación del resto |
| `apps/api/app/aplicacion/disponibilidad.py` | `canchas_disponibles` | la sede inactiva es `NoDisponible` antes de validar |
| `apps/api/app/infraestructura/horarios.py` | `agenda_de_sede`, `libres` | una sola consulta con `NOT EXISTS` sobre las reservas activas |
| `apps/api/app/interfaz/horarios.py` | `GET /espacios/disponibles` | 422 con los errores por campo, también `sede_id` si la sede ya no está |
| `apps/mobile/lib/reservas/reglas_busqueda.dart` | `erroresDelRango`, `ahoraEnElClub` | los mismos mensajes que la API |
| `apps/mobile/lib/reservas/pantalla_buscar_cancha.dart` | la pantalla | la lista no es perezosa: todos los filtros existen para el lector de pantalla aunque estén fuera de la vista; los horarios se abren encima de la búsqueda, así que al volver siguen los filtros y el resultado; volver a elegir el mismo valor o tocar la fecha sin cambiarla no quita el resultado; sólo se ofrecen las sedes con canchas y los deportes que tiene la sede; los chips sin canchas no se pueden elegir y no hay chips sin resultado; la dirección de cada cancha va en su nombre compuesto (TP-05) |
| `apps/mobile/lib/inicio/pantalla_inicio.dart` | ACCESOS RÁPIDOS | «Buscar cancha» y «Ver sedes»; el resto del inicio es de TP-01; la búsqueda cuelga de `/inicio`, así el atrás del sistema vuelve al inicio |
| `apps/mobile/lib/comun/formato_fecha.dart`, `calendario.dart` | `leerFecha`, `formatearFecha`, `elegirDiaProximo` | las funciones de fecha dejan `usuarios/` porque las usan también las reservas |
| `apps/mobile/lib/sedes/pantalla_sede.dart` | `TarjetaCancha` | con el texto por encima de 1,3 veces el precio baja debajo de las etiquetas; si no, queda a la derecha como en la sede |

## Brief visual

**Invención 2 · densidad 5.** Un formulario de búsqueda con resultados debajo, como el de
cualquier app de reservas.

- **Desde dónde.** Desde el inicio; los resultados aparecen debajo de los mismos filtros, que no
  se van nunca.
- **Teléfono chico.** En 360 entran los cinco filtros; CONSULTAR y LIMPIAR quedan fijos abajo.
  Los resultados se ven al deslizar.
- **Variables visuales.** Lima = lo elegido y el total de canchas; rojo = el error de un campo o
  de la consulta.
- **Material.** El de las altas del administrador para los campos, y la tarjeta de cancha de la
  sede para los resultados.
