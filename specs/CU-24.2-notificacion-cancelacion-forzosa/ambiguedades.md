# Ambigüedades — CU-24.2 · Recibir notificación de cancelación forzosa

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | no aplica: sólo se dispara cuando hay una reserva afectada
| Duplicados    | la card dice: FA2 varias reservas del mismo usuario se agrupan en una notificación; FA4 una ya cancelada no se notifica
| Validación    | no aplica: no hay datos de entrada del usuario
| Error         | la card no dice qué pasa si el envío falla del lado del backend → CU-24.2-AMB-01
| Estado        | la card dice: la reserva pasa a «Cancelada» con trazabilidad; el nombre choca con CU-15 (ver CU-14-AMB-01)
| Permisos      | la card dice: sin permiso del sistema operativo no hay push, pero queda en el centro (FA3)
| Límites       | la card no dice en qué ventana se agrupan las reservas de FA2 (una misma baja o cualquier momento) → CU-24.2-AMB-02
| Orden         | no aplica: una notificación por evento
| Concurrencia  | la card dice: FA4 si el usuario ya la canceló no se envía nada
| Rastro        | la card dice: «el envío consta en la trazabilidad de la reserva»

## Eventos
CU-24.2-AMB-01 · 2026-09-27 · abierta · si el envío push falla, ¿se reintenta? ¿la trazabilidad registra «enviada» o «fallida»?
CU-24.2-AMB-02 · 2026-09-27 · abierta · la agrupación de FA2, ¿es por una misma acción del administrador (una baja) o por período?
CU-24.2-AMB-03 · 2026-09-27 · abierta · ¿la baja de sede o espacio cancela reservas futuras (este CU, CU-14 FA8) o se impide (CU-19 FA3)?
CU-24.2-AMB-04 · 2026-09-27 · abierta · ¿el historial del usuario tiene filtro por estado para abrir «filtrado por anuladas»?
CU-24.2-AMB-05 · 2026-09-27 · abierta · ¿achicar el horario de una sede (CU-18 FA3) anula reservas y dispara este aviso, o no?
CU-24.2-AMB-00 · 2026-09-27 · snapshot · congelado en f1e3ea7
CU-24.2-AMB-03 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-24.2-AMB-03 · 2026-09-27 · resuelta · la baja de una sede o de un espacio con reservas futuras no se permite; la cancelación forzosa sale sólo de CU-15 (decisión 5)
CU-24.2-AMB-01 · 2026-09-30 · sin canal · si el push falla no se reintenta: el aviso queda en el centro con el envío marcado como fallido y un token rechazado por inválido se da de baja (igual que CU-24.1 y CU-24.3) → CU-24.2-SUP-01
CU-24.2-AMB-02 · 2026-09-30 · sin canal · las reservas de una misma persona se agrupan en un solo aviso con la cantidad mientras su aviso de anulación anterior siga sin leer, o si llegan en una misma acción; al leerlo, la anulación siguiente abre un aviso nuevo → CU-24.2-SUP-02
CU-24.2-AMB-09 · 2026-09-30 · sin canal · con la decisión 5 la baja de sede (CU-19) y de espacio (CU-23) se rechaza si hay reservas pendientes, así que hoy sólo CU-15 cancela por el club; el encolado es una función compartida que recibe las reservas de una persona y su motivo («Baja de la sede», «Baja del espacio deportivo») para que una baja que las cancelara la llame en la misma transacción → CU-24.2-SUP-03
CU-24.2-AMB-04 · 2026-09-30 · sin canal · el historial de Mis reservas no tiene filtro por estado: tocar el aviso agrupado abre Mis reservas en Historial, donde las anuladas figuran como ANULADA con su motivo; el aviso de una sola reserva la resalta → CU-24.2-SUP-04
CU-24.2-AMB-05 · 2026-09-30 · sin canal · achicar el horario de una sede (CU-18 FA3) no anula reservas —las deja como están— y por eso no dispara este aviso → CU-24.2-SUP-05
CU-24.2-AMB-06 · 2026-09-30 · sin canal · el texto es «El club anuló tu reserva» con «{tipo corto} · {sede} · {Día} {d}, {HH:MM}. Motivo: {motivo}.», con el día que da el calendario (no el Jue del CU ni el Vie del prototipo) y el motivo recortado a 200 caracteres; agrupado, «El club anuló {n} de tus reservas» con «Tenés {n} reservas anuladas por el club. Mirá el detalle en tu historial.» → CU-24.2-SUP-06
CU-24.2-AMB-07 · 2026-09-30 · sin canal · el envío consta en la trazabilidad del detalle de administración como «Notificación enviada al usuario» con la fecha; si el push no salió (sin permiso, sin servicio o fallido) consta «Aviso en el centro del usuario» con «El push no salió»; mientras está pendiente no figura → CU-24.2-SUP-07
CU-24.2-AMB-08 · 2026-09-30 · sin canal · el aviso se encola en la misma transacción que la anulación, una reserva no genera dos, y se despacha recién confirmada; lo pendiente lo retoma el barrido → CU-24.2-SUP-08
CU-24.2-TESTS · 2026-10-03 · congelados en 51feb55 · rojo de pytest: ImportError de encolar_cancelacion_forzosa (no existe todavía); rojo del emulador pendiente de la pasada final
CU-24.2-AMB-02 · 2026-10-03 · sin canal · agrupar abre un aviso nuevo, con otro id y la cantidad total, y el anterior queda reemplazado y fuera del centro; cada reserva sigue ligada al aviso que se la informó (con su envío y su hora), salvo que ese aviso no hubiera salido, y entonces pasa al nuevo; un aviso leído o en envío no se agrupa → CU-24.2-SUP-02
CU-24.2-AMB-10 · 2026-10-03 · sin canal · el push de anulación lleva `collapse_key` y `tag` fijos («cancelacion_forzosa») para que el agrupado reemplace al anterior en la bandeja; los tokens son de una sola persona, así que la clave es estable por persona y tipo; el reemplazo en el teléfono no se puede ejecutar acá → CU-24.2-SUP-09
CU-24.2-AMB-11 · 2026-10-03 · sin canal · las anulaciones de una misma persona se serializan con `pg_advisory_xact_lock(2402, usuario_id)` al inicio del encolado, que es el último bloqueo de la transacción, y la cantidad se cuenta después de tomarlo → CU-24.2-SUP-10
CU-24.2-TESTS · 2026-10-03 · recongelados en f293722 · el escenario H05-01 tocaba la campana con el panel abierto en el Home, que lo cierra sin abrir el centro: entra sin permiso de notificaciones, con el que el panel no se abre solo
