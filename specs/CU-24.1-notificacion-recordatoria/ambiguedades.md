# Ambigüedades — CU-24.1 · Recibir notificación recordatoria

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | la card dice: sin permiso, el centro muestra «Notificaciones desactivadas» con la acción para activarlas (FA2); no dice qué muestra el centro sin ninguna notificación → CU-24.1-AMB-01
| Duplicados    | la card dice: «Se envía una sola vez, una hora antes del inicio»
| Validación    | no aplica: no hay datos de entrada
| Error         | la card dice: FA5 el reintento lo maneja el servicio de notificaciones; no dice qué pasa si el envío falla del lado del backend → CU-24.1-AMB-02
| Estado        | la card dice: queda registrada como enviada y como no leída si se ignora (FA3); no dice cómo pasa a leída → CU-24.1-AMB-03
| Permisos      | la card dice: el usuario tiene que haber concedido el permiso del sistema operativo
| Límites       | la card no dice qué pasa con una reserva creada con menos de una hora de anticipación → CU-24.1-AMB-04
| Orden         | la card no lo dice; el prototipo ordena el centro de la más nueva a la más vieja, agrupada por día → CU-24.1-AMB-05
| Concurrencia  | la card dice: FA4 cancelación o modificación antes del envío descartan o reprograman el recordatorio
| Rastro        | la card dice: «queda registrada como enviada»; no dice que se guarde la hora de envío y de lectura → CU-24.1-AMB-06

## Eventos
CU-24.1-AMB-01 · 2026-09-27 · abierta · con el permiso concedido y sin ninguna notificación, ¿qué muestra el centro?
CU-24.1-AMB-02 · 2026-09-27 · abierta · si el backend no puede enviar (token vencido, servicio caído), ¿reintenta? ¿cuántas veces?
CU-24.1-AMB-03 · 2026-09-27 · abierta · ¿una notificación pasa a leída al tocarla, al abrir el centro, o con «Marcar todas»?
CU-24.1-AMB-04 · 2026-09-27 · abierta · una reserva hecha con menos de una hora de anticipación, ¿recibe recordatorio inmediato o ninguno?
CU-24.1-AMB-05 · 2026-09-27 · abierta · ¿el centro ordena de la más nueva a la más vieja y agrupa por día? ¿cuánto tiempo guarda las notificaciones?
CU-24.1-AMB-06 · 2026-09-27 · abierta · ¿se guarda la hora de envío y la de lectura de cada notificación?
CU-24.1-AMB-07 · 2026-09-27 · abierta · sin permiso, ¿el recordatorio aparece igual en el centro de la app (como en CU-24.2 FA3) o no se registra?
CU-24.1-AMB-08 · 2026-09-27 · abierta · si el usuario cerró sesión o tiene varios dispositivos, ¿a qué dispositivos llega?
CU-24.1-AMB-00 · 2026-09-27 · snapshot · congelado en c8f04f1
