# Ambigüedades — CU-15 · Anular reserva (admin)

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | la card dice: sin motivo «indica que el campo es obligatorio y no envía la solicitud» (FA2)
| Duplicados    | la card dice: si la reserva ya no está activa (ya anulada o cancelada) se rechaza (FA3)
| Validación    | la card dice: motivo obligatorio y la reserva tiene que seguir activa; no dice largo mínimo ni máximo del motivo → CU-15-AMB-01
| Error         | la card dice: FA4 «No pudimos anular la reserva», reintentar o volver, la reserva conserva su estado
| Estado        | la card dice: pasa a «Anulada por administración» y al listado de anuladas; el nombre choca con CU-14 (ver CU-14-AMB-01)
| Permisos      | la card dice: administrador con permisos de administración
| Límites       | la card dice: sólo reservas con horario futuro; no dice si hay una anticipación mínima para anular → CU-15-AMB-02
| Orden         | no aplica
| Concurrencia  | la card dice: FA3 la reserva «fue modificada, cancelada o comenzó antes de procesar la solicitud»
| Rastro        | la card dice: «con motivo, fecha, hora y administrador responsable»; no dice si se registra que la notificación se envió → CU-15-AMB-03

## Eventos
CU-15-AMB-01 · 2026-09-27 · abierta · ¿largo mínimo y máximo del motivo? ¿hay motivos predefinidos o siempre es texto libre?
CU-15-AMB-02 · 2026-09-27 · abierta · ¿se puede anular una reserva que empieza en minutos, o hay anticipación mínima?
CU-15-AMB-03 · 2026-09-27 · abierta · ¿se registra en la reserva cuándo se envió la notificación al usuario, como muestra el prototipo?
CU-15-AMB-04 · 2026-09-27 · abierta · ¿hay mensaje de éxito «Reserva anulada correctamente» (CU) o se muestra el detalle anulado (prototipo)?
CU-15-AMB-05 · 2026-09-27 · abierta · si la reserva fue modificada por el usuario (CU-11) mientras tanto, ¿se rechaza (FA3) aunque siga activa?
CU-15-AMB-00 · 2026-09-27 · snapshot · congelado en 8b53a1f
CU-15-AMB-01 · 2026-09-30 · sin canal · ¿largo mínimo y máximo del motivo, motivos predefinidos? → CU-15-SUP-01 · texto libre, recortado, que no puede quedar vacío, de hasta 500 caracteres (la API responde 422 con «El motivo es obligatorio para anular» o con el tope); sin lista de motivos
CU-15-AMB-02 · 2026-09-30 · sin canal · ¿anticipación mínima para anular? → CU-15-SUP-02 · se anula hasta el inicio del turno, sin anticipación mínima, igual que la cancelación del usuario (CU-10)
CU-15-AMB-03 · 2026-09-30 · sin canal · ¿se registra cuándo se envió la notificación? → CU-15-SUP-03 · esta card no guarda el envío: deja la reserva en «anulada» con quién, cuándo y motivo, que es lo que CU-24.2 lee; el registro del envío y la línea «Notificación enviada al usuario» del detalle los agrega CU-24.2
CU-15-AMB-04 · 2026-09-30 · sin canal · ¿mensaje «Reserva anulada correctamente» o detalle anulado? → CU-15-SUP-04 · se muestra el aviso «Reserva anulada correctamente» como overlay y el listado se vuelve a leer, donde la reserva ya figura anulada
CU-15-AMB-05 · 2026-09-30 · sin canal · ¿se rechaza si el usuario la modificó (CU-11) mientras tanto? → CU-15-SUP-05 · sí: el pedido lleva la cancha y el horario que el administrador vio, y si difieren la anulación se rechaza como FA3 («Esto cambió mientras tanto»); anular es lo que no se deshace
CU-15-AMB-06 · 2026-09-30 · sin canal · el CU pide «Anular» desde el listado y CU-14 deja la acción en el detalle → CU-15-SUP-06 · ANULAR RESERVA está en la tarjeta del listado de Activas (prototipo 55:482) y en el detalle, con la misma confirmación; sólo la ofrece una reserva que el servidor da por anulable (activa y sin empezar)
CU-15-AMB-07 · 2026-09-30 · sin canal · ¿qué pasa al repetir un pedido de anulación después de un corte? → CU-15-SUP-07 · si la reserva ya la anuló el mismo administrador con el mismo motivo, el pedido responde igual (200); cualquier otra reserva que no esté activa se rechaza (409)
CU-15-AMB-08 · 2026-09-30 · sin canal · la pantalla «No pudimos anular la reserva» del CU no está en el prototipo → CU-15-SUP-08 · se usan los overlays compartidos «Error de conexión» (REINTENTAR / Volver) y «Error del servidor» (ACEPTAR), como CU-10
CU-15-TESTS · 2026-09-30 · congelados en bd41351 · 9 escenarios (8 de app y 1 de API) congelados; rojo pendiente de la pasada final: sin emulador no se corrieron, y POST /reservas/{id}/anular todavía no existe
CU-15-TESTS · 2026-09-30 · precisión sobre congelados en bd41351 · los escenarios de app son 10 casos sobre 8 escenarios (H05-01 tiene tres casos); con el de API son 9 escenarios únicos
