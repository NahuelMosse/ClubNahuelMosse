# Implementation Plan: CU-24.2 · Recibir notificación de cancelación forzosa

**Branch**: `card/CU-24.2` | **Date**: 2026-10-03 | **Spec**: [card.snapshot.md](card.snapshot.md)

## Summary

Cuando el administrador anula una reserva (CU-15), la API registra en la misma transacción el aviso
«El club anuló tu reserva» para la persona afectada, con el envío pendiente. Confirmada la
anulación, un despacho lo manda por push a los dispositivos con permiso; lo que no llegó a salir lo
retoma el barrido. Repetir la anulación o fallar no deja avisos de más. Las reservas de una misma
persona se agrupan en un solo aviso con la cantidad mientras el anterior siga sin leer. El detalle
de administración muestra en la trazabilidad si el aviso salió. En la app el centro, el panel y la
campana de CU-24.1 ya dibujan el tipo `cancelacion_forzosa` con el tinte de alerta; tocar el aviso
abre Mis reservas en el historial (con la reserva resaltada si es una sola).

## Technical Context

**Language/Version**: Python 3.13 (API) · Dart 3.9 / Flutter 3.35 (app)
**Storage**: migración 0007: `notificacion_reserva`
**Push**: el puerto `CanalPush` de CU-24.1; `canal_push` entra a la ruta de anular como dependencia
**Testing**: pytest (escenarios con canal de prueba por `dependency_overrides`; unitarios sin base),
widget tests a 360 y 430 con texto al 200 %, `integration_test`

## Constitution Check

| Principio | Cómo se cumple |
|---|---|
| I · El CU es la especificación | Siete escenarios; pantallas 65:363, 65:401, 43:1462, 59:1336 |
| II · Nada se supone en silencio | `CU-24.2-SUP-01` a `SUP-08`; AMB-03 resuelta por la decisión 5 |
| III · Tests antes del código | Escenarios congelados (evento `CU-24.2-TESTS`); rojo en el emulador pendiente de la pasada final |
| IV · El backend es la autoridad | La API decide si hay aviso (sólo si la anulación se completó), a quién sale y cómo se agrupa |
| V · Rastro | `notificacion_reserva` liga cada reserva con su aviso; el estado y la fecha del envío salen en el detalle de administración |

**Arquitectura.** Sin puertos nuevos: se reutilizan los de CU-24.1/24.3. El dominio arma el texto;
`encolar_cancelacion_forzosa` es la única rutina que registra el aviso y la llama cualquier acción
que cancele reservas por el club, dentro de su transacción. `entregar` sigue siendo la única que
envía.

## Supuestos

| ID | Supuesto | Dónde se encoda |
|---|---|---|
| CU-24.2-SUP-01 | Sin reintento propio; envío fallido queda `fallida` y un token inválido se da de baja | `test_cancelacion_forzosa.py` (push que falla) |
| CU-24.2-SUP-02 | Se agrupa mientras el aviso anterior siga sin leer, o si llegan en una misma acción; uno ya leído no se reabre | `@CU-24.2-H03-01`; `test_cancelacion_forzosa.py`; `test_cancelacion_forzosa_reglas.py` |
| CU-24.2-SUP-03 | El encolado es una función compartida que recibe reservas ya canceladas por el club | `@CU-24.2-H02-01` |
| CU-24.2-SUP-04 | El aviso agrupado abre Mis reservas en Historial; el de una reserva la resalta | `@CU-24.2-H01-02`, `@CU-24.2-H03-01` |
| CU-24.2-SUP-05 | Achicar el horario de una sede no anula reservas ni avisa | Sin cobertura |
| CU-24.2-SUP-06 | Texto con el día del calendario y motivo recortado a 200 caracteres | `@CU-24.2-H01-01`, `@CU-24.2-H03-01`; `tests/unit/test_mensaje_cancelacion_forzosa.py` |
| CU-24.2-SUP-07 | El detalle de administración muestra cómo salió el aviso; pendiente no figura | `@CU-24.2-H01-03`, `@CU-24.2-H04-01`; `test/cancelacion_forzosa_test.dart` |
| CU-24.2-SUP-08 | Encolado en la transacción de la anulación, una vez por reserva, despachado después | `test_cancelacion_forzosa.py`; `test_cancelacion_forzosa_reglas.py` |

## Supuestos sin cobertura

| ID | Motivo |
|---|---|
| CU-24.2-SUP-05 | Es la ausencia de un comportamiento en CU-18; ningún test lo afirma |
| Entrega real | La entrega por FCM y la bandeja del sistema no se pueden ejecutar sin proyecto de Firebase ni teléfono (igual que CU-24.1-SUP-13); en la corrida del emulador el aviso consta como «el push no salió» |
| Baja de sede y de espacio | CU-19 y CU-23 rechazan la baja con reservas futuras (decisión 5): nada las dispara hoy; `@CU-24.2-H02-01` ejercita la función compartida directo |
| Emulador | Los escenarios de `integration_test` están congelados pero no se corrieron: rojo y verde quedan para la pasada final |

## Mapa de archivos

| Ruta | Responsabilidad | Decisiones ya tomadas |
|---|---|---|
| `apps/api/migraciones/versions/0007_aviso_de_cancelacion_forzosa.py` | `notificacion_reserva` | una reserva tiene a lo sumo un aviso (único por reserva) |
| `apps/api/app/dominio/notificaciones.py` | `ReservaAnulada`, `mensaje_cancelacion_forzosa` | el texto, el agrupado y el recorte del motivo viven en el dominio |
| `apps/api/app/infraestructura/notificaciones.py` | `encolar_cancelacion_forzosa(conn, usuario_id, reserva_ids)` | corre en la transacción de quien llama, sin commit; no agrupa en un aviso `enviando` |
| `apps/api/app/infraestructura/reservas.py` | `anular` encola; el historial trae `aviso_envio` y `aviso_en` | orden de bloqueos intacto: cuenta, sede, espacio, reserva, y recién después el aviso |
| `apps/api/app/dominio/reservas.py` | `aviso_envio`, `aviso_en` en `ReservaHistorial` | pendiente se ve como `None` |
| `apps/api/app/interfaz/reservas.py` | la ruta de anular despacha después de responder | `BackgroundTasks` y `canal_push` como dependencia |
| `apps/api/tests/escenarios/test_cancelacion_forzosa.py` | escenarios (congelado) | canal de prueba por `dependency_overrides` |
| `apps/api/tests/escenarios/test_cancelacion_forzosa_reglas.py` | SUP-02 y SUP-08 contra la base | sin tags de escenario |
| `apps/api/tests/unit/test_mensaje_cancelacion_forzosa.py` | texto, agrupado y recorte | sin base |
| `apps/mobile/lib/admin/historial_reservas.dart` | `avisoEnvio`, `avisoEn` en `ReservaHistorial` | claves opcionales |
| `apps/mobile/lib/admin/pantalla_detalle_reserva.dart` | paso de trazabilidad del aviso | sólo en reservas anuladas con envío conocido |
| `apps/mobile/test/cancelacion_forzosa_test.dart` | widget: trazabilidad del aviso al 200 % en 360 y 430 | sin tag de card |
| `apps/mobile/integration_test/notificaciones/cancelacion_forzosa_test.dart` | escenarios (congelado) | la anulación llega desde la API con el administrador |
| `apps/mobile/integration_test/soporte/red.dart` | `proximasDe`, `anularDesdeElAdmin`, `esperarElEnvioDelAviso` | |

## Perímetro

Auth: token de Firebase (emulador). Sin mocks de servicio propio. Afuera: la entrega real por FCM y
la bandeja del sistema. El atajo de pruebas `reservas/anular` no encola avisos: no es una anulación
del administrador.

## Brief visual

**Invención 1 · densidad 4.** Sin pantalla nueva: el aviso es una tarjeta más del centro y del panel
de CU-24.1, con el triángulo de alerta y el tinte rojo del tipo `cancelacion_forzosa`; en el detalle
de administración, un paso más de la trazabilidad.

- **Qué se lee.** «El club anuló tu reserva», qué reserva (deporte, sede, día y hora) y el motivo;
  agrupado, cuántas son.
- **Detalle de administración.** Tras «Anulada por el administrador», un paso con el ícono de envío:
  «Notificación enviada al usuario» con la fecha, o «Aviso en el centro del usuario» con «El push no
  salió».
- **Teléfono chico.** En 360 con el texto al 200 % los pasos crecen en alto y no se recortan.
- **Material.** El de CU-24.1 y CU-14: sin cambios.
