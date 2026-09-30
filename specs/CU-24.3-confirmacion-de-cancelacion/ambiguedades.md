# Ambigüedades — CU-24.3 · Recibir confirmación de cancelación

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | no aplica: sólo se dispara cuando hay una cancelación confirmada
| Duplicados    | la card dice: FA1 no se duplica con el mensaje de CU-10 si el usuario sigue en Mis reservas
| Validación    | no aplica: no hay datos de entrada
| Error         | la card dice: FA3 si la cancelación falló no se envía nada; no dice qué pasa si falla el envío → CU-24.3-AMB-01
| Estado        | la card dice: no cambia ningún estado
| Permisos      | la card dice: sin permiso no hay push, queda sólo en el centro (FA2)
| Límites       | no aplica
| Orden         | no aplica: una notificación por cancelación
| Concurrencia  | la card no dice qué pasa si el usuario cancela varias reservas seguidas: ¿una por cada una o agrupadas como CU-24.2 FA2? → CU-24.3-AMB-02
| Rastro        | la card dice: queda registrada en el centro de notificaciones

## Eventos
CU-24.3-AMB-01 · 2026-09-27 · abierta · si el push falla, ¿se reintenta o alcanza con que quede en el centro?
CU-24.3-AMB-02 · 2026-09-27 · abierta · varias cancelaciones seguidas, ¿una confirmación por reserva o agrupadas?
CU-24.3-AMB-03 · 2026-09-27 · abierta · el enunciado sólo pide push de reservas próximas; ¿esta confirmación va por push o sólo en el centro de la app?
CU-24.3-AMB-04 · 2026-09-27 · abierta · la regla de FA1 («si sigue en Mis reservas») ¿cómo se decide: la app suprime la tarjeta si está en esa pantalla?
CU-24.3-AMB-00 · 2026-09-27 · snapshot · congelado en 9678210
CU-24.3-AMB-03 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-24.3-AMB-03 · 2026-09-27 · resuelta · las tres notificaciones van por push y quedan en el centro de notificaciones; una reserva hecha con menos de una hora de anticipación no recibe recordatorio (decisión 10)
CU-24.3-AMB-01 · 2026-09-30 · sin canal · si el push falla no se reintenta: la confirmación queda en el centro con el envío marcado como fallido y un token que el servicio rechaza por inválido se da de baja (igual que CU-24.1) → CU-24.3-SUP-01
CU-24.3-AMB-02 · 2026-09-30 · sin canal · una confirmación por cada reserva cancelada, sin agrupar; un reintento de la cancelación ya hecha no crea otra (índice único por reserva) → CU-24.3-SUP-02
CU-24.3-AMB-04 · 2026-09-30 · sin canal · la app decide al leer el centro: si la pantalla actual es exactamente Mis reservas, la tarjeta del panel no se muestra y queda sólo el mensaje de éxito de la cancelación → CU-24.3-SUP-03
CU-24.3-AMB-05 · 2026-09-30 · abierta · la confirmación se encola en la misma transacción que la cancelación, con el envío pendiente, y se despacha recién confirmada; lo pendiente que quede lo despacha el barrido; un despacho reserva la notificación pasándola a «enviando» y, si el proceso muere en el medio, no se reenvía
CU-24.3-AMB-05 · 2026-09-30 · sin canal · la confirmación se encola en la misma transacción que la cancelación, con el envío pendiente, y se despacha recién confirmada; lo pendiente que quede lo despacha el barrido; un despacho reserva la notificación pasándola a «enviando» y, si el proceso muere en el medio, no se reenvía → CU-24.3-SUP-04
CU-24.3-AMB-06 · 2026-09-30 · abierta · el cuerpo es «{tipo corto} · {sede} · {Día} {d}, {HH:MM}. El horario quedó liberado.» con el día abreviado del prototipo (Mié) y no el del CU (Mar), que contradice el calendario; el mismo texto en el push, el panel y el centro, sin el «Cancelaste» del overlay
CU-24.3-AMB-06 · 2026-09-30 · sin canal · el cuerpo es «{tipo corto} · {sede} · {Día} {d}, {HH:MM}. El horario quedó liberado.» con el día abreviado del prototipo (Mié) y no el del CU (Mar), que contradice el calendario; el mismo texto en el push, el panel y el centro, sin el «Cancelaste» del overlay → CU-24.3-SUP-05
CU-24.3-AMB-07 · 2026-09-30 · abierta · tocar la confirmación abre Mis reservas en Historial con esa reserva resaltada, que figura como cancelada
CU-24.3-AMB-07 · 2026-09-30 · sin canal · tocar la confirmación abre Mis reservas en Historial con esa reserva resaltada, que figura como cancelada → CU-24.3-SUP-06
CU-24.3-AMB-08 · 2026-09-30 · abierta · la tarjeta que FA1 suprime queda sin leer (cuenta en la campana y está en el centro) y no vuelve a salir en el panel durante esa sesión
CU-24.3-AMB-08 · 2026-09-30 · sin canal · la tarjeta que FA1 suprime queda sin leer (cuenta en la campana y está en el centro) y no vuelve a salir en el panel durante esa sesión → CU-24.3-SUP-07
CU-24.3-TESTS · 2026-09-30 · congelados en 4ec5358 · rojo pendiente de la pasada final
CU-24.3-AMB-09 · 2026-09-30 · abierta · Una reserva cancelada deja su confirmación en el centro, así que el escenario CU-24.1-H05-01 (congelado, de otra card) que afirma centro vacío tras cancelar deja de valer: tiene que afirmar que no hay recordatorio, no que no hay nada; lo corrige quien recongele CU-24.1 y acá queda sin cobertura
CU-24.3-AMB-09 · 2026-09-30 · sin canal · Una reserva cancelada deja su confirmación en el centro, así que el escenario CU-24.1-H05-01 (congelado, de otra card) que afirma centro vacío tras cancelar deja de valer: tiene que afirmar que no hay recordatorio, no que no hay nada; lo corrige quien recongele CU-24.1 y acá queda sin cobertura → CU-24.3-SUP-08
