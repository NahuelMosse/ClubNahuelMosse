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
