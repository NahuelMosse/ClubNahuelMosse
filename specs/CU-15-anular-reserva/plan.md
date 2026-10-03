# Plan — CU-15 · Anular reserva (admin)

## Summary

El administrador anula una reserva activa que todavía no empezó, desde la tarjeta del listado de
CU-14 o desde su detalle. La API cambia el estado a `anulada` y estampa motivo, quién y cuándo
(`motivo`, `cancelada_por`, `cancelada_en`, columnas que el modelo ya tiene); el horario queda libre
porque la exclusión de superposición sólo rige para `activa`. La notificación al usuario es
CU-24.2: esta card le deja la reserva en `anulada` con esos tres datos.

## Technical Context

Flutter en `apps/mobile`, FastAPI en `apps/api`, PostgreSQL. Sin migración ni dependencias nuevas.
Endpoint nuevo: `POST /reservas/{id}/anular` con `{motivo, espacio_id, inicio}`. La respuesta es la
vista de administrador de CU-14 con un campo nuevo, `anulable`.

- **Bloqueos.** Se toman en el orden de siempre: cuenta del dueño `FOR SHARE`, sede `FOR SHARE`,
  espacio `FOR NO KEY UPDATE`, reserva `FOR UPDATE`. Como hay que conocer cuenta, sede y espacio
  antes de bloquear, se lee la reserva sin bloquear; si entre la lectura y el bloqueo la
  reserva se movió de espacio, se rechaza como cambiada.
- **Idempotencia.** Repetir el pedido de una reserva que el mismo administrador anuló con el mismo
  motivo responde 200 con la misma reserva; cualquier otra reserva no activa responde 409.
- **Reloj.** `anulable` y «ya empezó» se deciden con `now()` del servidor.
- **Zona.** La app manda `inicio` como instante (UTC) y la API lo compara con `timestamptz`.

## Mapa de archivos

API
- `apps/api/app/dominio/reservas.py` — `ReservaHistorial.anulable` (activa y sin empezar).
- `apps/api/app/aplicacion/reservas.py` — `Reservas.anular` (contrato) y `anular_reserva`: rol
  administrador, motivo recortado, obligatorio y de hasta 500 caracteres. Las reglas de estado
  viven en SQL, dentro de la transacción con los bloqueos.
- `apps/api/app/infraestructura/reservas.py` — `ReservasSql.anular` (bloqueos, idempotencia,
  estampa) y la columna `anulable` del historial.
- `apps/api/app/interfaz/reservas.py` — `POST /reservas/{id}/anular`; 403, 404, 409
  («Esto cambió mientras tanto») y 422 (`motivo`).
- `apps/api/tests/escenarios/test_anular_reserva.py` — H01-04 (congelado).
- `apps/api/tests/integracion/test_anular_reserva_api.py` — rastro, libera el horario, repetición,
  rechazos, `anulable`, concurrencia contra la cancelación del usuario y el rechazo de una reserva
  empezada aunque se mande su horario vigente.

App
- `apps/mobile/lib/admin/historial_reservas.dart` — `ReservaHistorial.anulable` y
  `HistorialDeReservas.anular`.
- `apps/mobile/lib/admin/dialogo_anular_reserva.dart` — la confirmación «¿Anular esta reserva?»
  con los datos y el motivo; devuelve el motivo o `null`.
- `apps/mobile/lib/admin/anular_reserva.dart` — el flujo: confirmación, pedido, reintento tras un
  corte, aviso de éxito, «Esto cambió mientras tanto», sesión vencida (deja los filtros del
  listado en `pendientes`, como la carga). Lo usan el listado y el detalle.
- `apps/mobile/lib/admin/pantalla_panel_admin.dart` — ANULAR RESERVA en la tarjeta, fuera de la
  zona que abre el detalle; vuelve a leer el listado al terminar.
- `apps/mobile/lib/admin/pantalla_detalle_reserva.dart` — ANULAR RESERVA en el detalle; vuelve con
  `true` si la reserva cambió. Con la anulación en camino no se sale (`PopScope`, flecha y
  VOLVER deshabilitados); el listado se relee siempre al volver.
- `apps/mobile/lib/comun/dialogo_error.dart` — overlay «Reserva anulada correctamente».
- `apps/mobile/lib/app.dart` — el detalle recibe el cliente y la sesión.
- `apps/mobile/integration_test/reservas/anular_reserva_test.dart` — 8 escenarios (congelado).
- `apps/mobile/integration_test/soporte/red.dart` — `cancelarProximasDe`, `reservaQueVeElAdmin`,
  `historialDe`.
- `apps/mobile/test/anular_reserva_test.dart` — widget tests, incluido texto al 200 % en 360.
- `apps/mobile/test/capturas/anular_reserva_capturas.dart` — capturas del paso 9.

## Supuestos

Cubiertos por un test con `@supuesto:` (en tests sin tag de card, no en `$E2E`):
- CU-15-SUP-01 · motivo libre, recortado, obligatorio, hasta 500 — `test_anular_reserva_api.py`.
- CU-15-SUP-04 · aviso «Reserva anulada correctamente» — `test/anular_reserva_test.dart`.
- CU-15-SUP-05 · cancha u horario distintos al visto se rechazan — `test_anular_reserva_api.py`.
- CU-15-SUP-06 · la acción está en la tarjeta y en el detalle y sólo si es `anulable` —
  `test/anular_reserva_test.dart`.
- CU-15-SUP-07 · repetir la anulación propia responde igual — `test_anular_reserva_api.py`.
- CU-15-SUP-08 · errores de red y servidor con los overlays compartidos — `test/anular_reserva_test.dart`.

## Supuestos sin cobertura

- CU-15-SUP-02 · sin anticipación mínima: ningún test anula una reserva que empieza en minutos
  pero todavía no empezó; los escenarios anulan una de mañana.
- CU-15-SUP-03 · la card no registra el envío de la notificación: no hay comportamiento que probar.
  CU-24.2 lee `estado = 'anulada'`, `cancelada_en`, `cancelada_por` y `motivo`.

Los tests de escenario (`$E2E`) no llevan `@supuesto:`; los tags de arriba viven en los unitarios y
de integración, que el implementador puede escribir.

## Perímetro

- Auth: administrador real del emulador de Firebase Auth; los usuarios de los escenarios se crean
  por la API.
- Sin mocks en los escenarios: API, base y emulador reales. Las fallas de red y de servidor salen de
  `ApiIntermedia`; «cancelada mientras tanto» y «ya empezó» salen de la API y de `/pruebas`.
- Afuera: la notificación (CU-24.2), el registro del envío, la línea «Notificación enviada al
  usuario» del detalle y la anulación masiva por bajas (CU-19/CU-23).

## Brief visual

Invención 2, densidad 5: es una confirmación sobre un listado que ya existe, y el prototipo la
resuelve con un overlay.

- **Listado (Activas).** Cada tarjeta anulable cierra con ANULAR RESERVA, contorno rojo, al ancho
  de la tarjeta (55:482). El resto de la tarjeta sigue abriendo el detalle. El rojo dice «no se
  deshace»; las completadas, canceladas y anuladas no lo llevan.
- **Confirmación (60:1559, 60:1595).** Overlay con ícono de alerta, «¿Anular esta reserva?», la
  tabla Usuario · Sede · Cancha · Cuándo · Importe, el campo MOTIVO DE LA ANULACIÓN de varias
  líneas, CONFIRMAR ANULACIÓN en rojo lleno y VOLVER en contorno. Sin motivo, el campo se marca en
  rojo y dice «El motivo es obligatorio para anular». En 360 de ancho y texto al 200 % los datos
  bajan de renglón y el overlay se desplaza; los dos botones quedan alcanzables.
- **Detalle.** ANULAR RESERVA arriba de VOLVER AL LISTADO, sólo si la reserva es anulable.
- **Dónde está parada la persona.** En el listado, con la reserva a la vista, o en su detalle; no
  hace falta salir de ahí para anular. Tras anular se vuelve a leer el listado y la reserva figura
  ANULADA.
- **Material.** Es el de la app (Inter, lienzo oscuro con superficie elevada, radio 20 en el
  overlay y 12 en la tabla y el campo, separación por cambio de fondo). El rojo codifica la acción
  irreversible y el verde del aviso de éxito codifica «hecho».
- **Cancha.** La fila muestra el nombre técnico del espacio, como el listado; el prototipo dice
  «Fútbol 5 · Cancha 1» y la API no entrega el número por separado.
