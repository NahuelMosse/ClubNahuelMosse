# Implementation Plan: CU-24.3 · Recibir confirmación de cancelación

**Branch**: `card/CU-24.3` | **Date**: 2026-09-30 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

Al cancelar una reserva propia (CU-10), la API registra en la misma transacción la notificación
«Reserva cancelada» con el envío pendiente. Cuando la cancelación se confirma, un despacho la
manda por push a los dispositivos con permiso; lo que no llegó a salir lo retoma el barrido. Una
cancelación que falla no deja aviso y repetir una ya hecha no lo duplica. En la app la
confirmación usa el centro, el panel y la campana de CU-24.1; tocarla abre Mis reservas en el
historial con esa reserva resaltada, y si la persona sigue en Mis reservas el panel no la muestra:
ve sólo el mensaje de éxito de CU-10.

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Storage**: migración 0006 sobre `notificacion`
**Push**: el puerto `CanalPush` de CU-24.1; `canal_push` entra a la ruta de cancelar como dependencia
**Testing**: pytest (escenarios con canal de prueba inyectado por `dependency_overrides`; unitarios
con fakes), widget tests a 360 y 430 con texto al 200 %, `integration_test`

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Seis escenarios; pantallas 65:383, 65:401, 43:1462, 42:312 |
| II · Nada se supone en silencio | `CU-24.3-SUP-01` a `SUP-08`; AMB-03 resuelta por la decisión 10 |
| III · Tests antes del código | Escenarios congelados (evento `CU-24.3-TESTS`); rojo en el emulador pendiente de la pasada final |
| IV · El backend es la autoridad | La API decide si hay aviso (sólo si la cancelación se completó) y a quién sale |
| V · Rastro | `creada_en`, `enviada_en`, `leida_en`, `envio`, `reserva_inicio` de la notificación |

**Arquitectura.** Se reutilizan los puertos de CU-24.1; no hay puerto nuevo. `entregar` es la
única rutina que manda un aviso y la comparten el recordatorio y el despacho. El dominio arma el
texto; la infraestructura de reservas lo encola junto con la cancelación.

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-24.3-SUP-01 | Sin reintento propio; un envío fallido queda `fallida` y un token inválido se da de baja | `tests/unit/test_despacho_de_confirmaciones.py`; `test_confirmacion_cancelacion_reglas.py` |
| CU-24.3-SUP-02 | Una confirmación por reserva cancelada, sin agrupar; un reintento no la duplica | `test_confirmacion_cancelacion_reglas.py`; índice `notificacion_cancelacion_unica` |
| CU-24.3-SUP-03 | La app suprime la tarjeta si la ruta actual es exactamente Mis reservas | `@CU-24.3-H02-01`; `test/confirmacion_cancelacion_test.dart` |
| CU-24.3-SUP-04 | Encolada con la cancelación, despachada después; el barrido retoma lo pendiente; `enviando` evita el doble envío y un proceso que muere en el medio no reenvía. El despacho toma de a un aviso: el que falla queda `fallida` y los demás siguen `pendiente` hasta su turno; un fallo del despacho no corta los recordatorios del barrido | `test_confirmacion_cancelacion_reglas.py`; `test_confirmacion_cancelacion_atomicidad.py`; `test_despacho_robusto.py`; `tests/unit/test_despacho_de_confirmaciones.py` |
| CU-24.3-SUP-05 | Cuerpo «{tipo corto} · {sede} · {Día} {d}, {HH:MM}. El horario quedó liberado.» con el día del prototipo (Mié, no Mar) y el mismo texto en push, panel y centro | `@CU-24.3-H01-01`; `tests/unit/test_despacho_de_confirmaciones.py` |
| CU-24.3-SUP-06 | Tocarla abre Mis reservas en Historial con la reserva resaltada | `@CU-24.3-H01-02`; `test/confirmacion_cancelacion_test.dart` |
| CU-24.3-SUP-07 | La tarjeta suprimida queda sin leer y no vuelve al panel en esa sesión | `@CU-24.3-H02-01`; `test/confirmacion_cancelacion_test.dart` |
| CU-24.3-SUP-08 | El centro trae la confirmación tras cancelar (decisión 10); `CU-24.1-H05-01` afirma que no hay recordatorio, no que el centro esté vacío | `test_recordatorio.py` (recongelado) |

## Supuestos sin cobertura

| ID | Motivo |
|---|---|
| CU-24.3-SUP-01, 02, 03, 04, 05 (parte), 06, 07 | Los prueban tests de `tests/unit`, `tests/escenarios/test_confirmacion_cancelacion_reglas.py` y de widget con su tag `@supuesto`; ningún escenario de la card los ejercita por sí solo |
| Entrega real | La entrega por FCM, la bandeja del sistema y la pantalla bloqueada no se pueden ejecutar sin proyecto de Firebase ni teléfono (igual que CU-24.1-SUP-13) |
| Emulador | Los escenarios de `integration_test` de esta card están congelados pero no se corrieron: rojo y verde en el emulador quedan para la pasada final |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/migraciones/versions/0006_confirmacion_de_cancelacion.py` | estado `enviando`, índice único por reserva cancelada | una reserva se cancela una vez |
| `apps/api/app/dominio/notificaciones.py` | `mensaje_cancelacion`, `datos_del_aviso`, `DIAS` | el texto y los datos del aviso viven en el dominio |
| `apps/api/app/aplicacion/notificaciones.py` | `Pendiente`, `tomar_siguiente`, `entregar`, `despachar_pendientes` | `entregar` lo comparten recordatorio y despacho; un aviso que falla queda `fallida` y no corta el lote |
| `apps/api/app/infraestructura/notificaciones.py` | `tomar_siguiente` | un aviso por vez con `LIMIT 1 FOR UPDATE SKIP LOCKED` y paso a `enviando`; nunca toma recordatorios ni avisos reemplazados |
| `apps/api/app/infraestructura/reservas.py` | `cancelar` encola la notificación | misma transacción que la baja |
| `apps/api/app/interfaz/reservas.py` | la ruta de cancelar despacha después de responder | `BackgroundTasks` con su propia conexión y `canal_push` como dependencia |
| `apps/api/app/interfaz/barrido.py` | `despachar_de` y el despacho del barrido | un fallo no cambia la cancelación ni corta los recordatorios |
| `apps/api/tests/escenarios/test_confirmacion_cancelacion.py` | escenarios (congelado) | canal de prueba por `dependency_overrides` |
| `apps/api/tests/escenarios/test_confirmacion_cancelacion_reglas.py` | SUP-01, 02, 04 contra la base | sin tags de escenario |
| `apps/api/tests/escenarios/test_confirmacion_cancelacion_atomicidad.py` | la reserva sigue activa y no queda aviso si el INSERT del aviso falla | un disparador de la base hace fallar el INSERT |
| `apps/api/tests/escenarios/test_despacho_robusto.py` | un aviso que falla no deja a los demás en `enviando`; el barrido sigue | sin tags de escenario |
| `apps/api/tests/unit/test_despacho_de_confirmaciones.py` | mensaje y despacho con fakes | sin base |
| `apps/mobile/lib/notificaciones/centro.dart` | `ubicacion`, `enElPanel`, silenciadas | sólo silencia `cancelacion_usuario` llegadas en `/reservas` |
| `apps/mobile/lib/notificaciones/panel_avisos.dart` | el panel lista `enElPanel` | cambio de una línea |
| `apps/mobile/lib/app.dart` | ruta según el tipo del aviso, `ubicacion` conectada al enrutador, `historial` en `/reservas` | `?historial=1` |
| `apps/mobile/lib/reservas/pantalla_mis_reservas.dart` | `historial` inicial y resaltado en cualquier pestaña | |
| `apps/mobile/test/confirmacion_cancelacion_test.dart` | widget: panel, silencio, 200 % en 360 y 430, toque | sin tag de card |
| `apps/mobile/integration_test/notificaciones/confirmacion_cancelacion_test.dart` | escenarios (congelado) | la cancelación llega desde otro teléfono cuando se mira el panel |
| `apps/mobile/integration_test/soporte/red.dart` | `cancelarDesdeOtroTelefono` | |

## Perímetro

Auth: token de Firebase (emulador). Sin mocks de servicio propio. Afuera: CU-24.2, la entrega real
por FCM y la bandeja del sistema.

## Brief visual

**Invención 1 · densidad 4.** No hay pantalla nueva: la confirmación es una tarjeta más del centro
y del panel de CU-24.1, con el ícono de tilde y el tinte verde que esa tarjeta ya dibuja para el
tipo `cancelacion_usuario`.

- **Desde dónde.** La persona cancela en Mis reservas; la tarjeta aparece en el panel si ya salió
  de esa pantalla, y siempre queda en el centro, abierto desde la campana del Home.
- **Qué se lee.** «Reserva cancelada», qué reserva (deporte, sede, día y hora) y que el horario
  quedó liberado; el verde dice que salió bien.
- **Teléfono chico.** En 360 con el texto al 200 % el cuerpo crece en alto y no se recorta;
  «MARCAR TODAS» sigue dentro del ancho.
- **Material.** El de CU-24.1: sin cambios.
