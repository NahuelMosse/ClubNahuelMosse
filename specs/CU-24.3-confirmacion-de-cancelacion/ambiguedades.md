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
