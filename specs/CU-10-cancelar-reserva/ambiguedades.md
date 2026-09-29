# Ambigüedades — CU-10 · Cancelar reserva

Doble lectura (épica de reservas): dos lecturas independientes que no se vieron entre sí, más la
propia. Coincidieron en los cinco flujos, en el choque DELETE contra cambio de estado y en que el CU
no valida que la reserva sea del usuario. Divergencias:
- Una marcó Caso vacío como pregunta abierta; la otra lo dio por no aplica por la precondición.
- Una marcó el doble toque como duplicado; la otra, como concurrencia.
La lectura propia agregó el estado de cancelada que el prototipo no tiene.

## Las diez preguntas
| Caso vacío    | no aplica: la precondición exige al menos una reserva activa; la lista vacía es de CU-08 FA1
| Duplicados    | la card no dice qué pasa si la cancelación llega dos veces (doble toque o reintento después de un timeout) → CU-10-AMB-01
| Validación    | la card dice: el backend rechaza turnos «pasados o en curso» (FA4); no dice si hay anticipación mínima → CU-10-AMB-02
| Error         | la card dice: FA2 error de conexión con reintento y reserva intacta; FA3 error de servidor con datos consistentes
| Estado        | la card dice: «El estado de la reserva cambia a cancelada»; no dice si se distingue de la anulada por el administrador → CU-10-AMB-03
| Permisos      | la card no dice que el backend verifique que la reserva sea del usuario que la cancela → CU-10-AMB-04
| Límites       | la card no dice hasta qué momento antes del inicio se puede cancelar → CU-10-AMB-02
| Orden         | no aplica: se cancela una reserva por vez
| Concurrencia  | la card dice en FA4 que el horario puede empezar «mientras el usuario estaba en la pantalla»; no dice qué pasa si un administrador la anuló (CU-15) mientras tanto → CU-10-AMB-05
| Rastro        | la card no dice que se estampe cuándo y quién canceló → CU-10-AMB-06

## Eventos
CU-10-AMB-01 · 2026-09-27 · abierta · si la cancelación ya se aplicó y llega de nuevo, ¿el backend responde éxito sin hacer nada?
CU-10-AMB-02 · 2026-09-27 · abierta · ¿se puede cancelar hasta el minuto anterior al inicio, o hay anticipación mínima?
CU-10-AMB-03 · 2026-09-27 · abierta · ¿«cancelada por el usuario» y «anulada por el administrador» son dos estados distintos en el historial?
CU-10-AMB-04 · 2026-09-27 · abierta · si alguien intenta cancelar una reserva ajena por la API, ¿qué responde (403 o 404)?
CU-10-AMB-05 · 2026-09-27 · abierta · si la reserva ya fue anulada por el administrador, ¿se muestra «Esto cambió mientras tanto»?
CU-10-AMB-06 · 2026-09-27 · abierta · ¿se guarda fecha y hora de la cancelación y quién la hizo?
CU-10-AMB-07 · 2026-09-27 · abierta · ¿la cancelación dispara la push de confirmación de cancelación (CU-24.3)?
CU-10-AMB-08 · 2026-09-27 · abierta · ¿el monto se devuelve o hay alguna política de reintegro? Ni el CU ni el enunciado hablan de pagos
CU-10-AMB-00 · 2026-09-27 · snapshot · congelado en f5fb98e
CU-10-AMB-02 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-10-AMB-02 · 2026-09-27 · resuelta · se cancela hasta el inicio, sin anticipación mínima; se muestra el precio pero no hay pagos ni reintegros (decisión 13)
CU-10-AMB-03 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-10-AMB-03 · 2026-09-27 · resuelta · estados Activa, Completada, Cancelada (por el usuario) y Anulada (por el club, con motivo) (decisión 3)
CU-10-AMB-06 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-10-AMB-06 · 2026-09-27 · resuelta · todas las entidades guardan fecha de creación y de modificación, las acciones del administrador guardan su autor, la reserva guarda el precio del momento; las bajas son lógicas y no borran historial (decisión 4)
CU-10-AMB-07 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-10-AMB-07 · 2026-09-27 · resuelta · las tres notificaciones van por push y quedan en el centro de notificaciones; una reserva hecha con menos de una hora de anticipación no recibe recordatorio (decisión 10)
CU-10-AMB-08 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-10-AMB-08 · 2026-09-27 · resuelta · se cancela hasta el inicio, sin anticipación mínima; se muestra el precio pero no hay pagos ni reintegros (decisión 13)
CU-10-AMB-09 · 2026-09-28 · abierta · FA4 pide avisar que no se puede cancelar un turno en curso: el prototipo no trae ese aviso, ¿qué dice?
CU-10-AMB-10 · 2026-09-28 · abierta · FA3 trae su propio texto («No se pudo cancelar la reserva en este momento. Intente más tarde»); el prototipo usa el overlay compartido del servidor: ¿cuál va?
CU-10-AMB-01 · 2026-09-28 · vencida → CU-10-SUP-01 · cancelar una reserva que la misma persona ya canceló responde como éxito sin cambiar nada: un doble toque o un reintento después de un corte no muestra un error
CU-10-AMB-04 · 2026-09-28 · vencida → CU-10-SUP-02 · la reserva de otra cuenta responde 404, como si no existiera: no se revela que hay una reserva con ese número
CU-10-AMB-05 · 2026-09-28 · vencida → CU-10-SUP-03 · si la reserva ya no está activa (anulada por el club o ya empezada), el overlay compartido «Esto cambió mientras tanto» (393:6532) con VER LO ACTUALIZADO, que vuelve a leer la lista
CU-10-AMB-09 · 2026-09-28 · vencida → CU-10-SUP-04 · una reserva en curso usa el mismo overlay «Esto cambió mientras tanto» (decisión 12): la lista se vuelve a leer; una reserva que ya empezó no muestra CANCELAR y pasa al historial cuando termina
CU-10-AMB-10 · 2026-09-28 · vencida → CU-10-SUP-05 · el overlay compartido de error del servidor, como el prototipo (decisión 12)
CU-10-TESTS · 2026-09-28 · congelados en 67f6c58 · 6 escenarios en rojo porque las tarjetas de Mis reservas no tienen CANCELAR ni existe la cancelación en la API
