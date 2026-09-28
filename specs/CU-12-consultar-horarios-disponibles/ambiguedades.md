# Ambigüedades — CU-12 · Consultar horarios disponibles

Una sola lectura del CU, declarada.

## Las diez preguntas
| Caso vacío    | la card dice: «reemplaza la grilla por un estado vacío indicando que no hay horarios disponibles y sugiere cambiar la fecha» (FA4)
| Duplicados    | no aplica: es una consulta; la superposición se valida en CU-09
| Validación    | la card dice: horas completas, dentro del horario de la sede, futuras; la duración elegida no puede pasar el cierre (paso 1, FA3)
| Error         | la card dice: FA5 alerta de conexión, FA6 error de servidor; en los dos «No se muestran horarios»
| Estado        | la card dice: «la selección no crea, bloquea ni reserva horarios» (poscondiciones)
| Permisos      | la card dice: usuario autenticado
| Límites       | la card dice duración 1 o 2 horas; el prototipo, 1 a 4; no dice cuántos días hacia adelante se ofrecen → CU-12-AMB-01, CU-12-AMB-02
| Orden         | la card no lo dice; el prototipo ordena la grilla por hora de inicio ascendente y los días desde hoy → CU-12-AMB-03
| Concurrencia  | la card dice que elegir no bloquea el horario; no dice qué pasa si otro lo reserva mientras tanto → CU-12-AMB-04
| Rastro        | no aplica: consulta de solo lectura

## Eventos
CU-12-AMB-01 · 2026-09-27 · abierta · ¿duración máxima de una reserva: 2 horas (CU), 4 horas (prototipo), o hasta el cierre de la sede (enunciado)?
CU-12-AMB-02 · 2026-09-27 · abierta · ¿cuántos días hacia adelante se pueden consultar? El prototipo muestra siete
CU-12-AMB-03 · 2026-09-27 · abierta · ¿la grilla muestra todas las horas del día con las ocupadas deshabilitadas o sólo las libres?
CU-12-AMB-04 · 2026-09-27 · abierta · si la franja elegida se ocupa antes de confirmar, ¿se resuelve en CU-09 FA1 o la grilla se refresca sola?
CU-12-AMB-05 · 2026-09-27 · abierta · ¿cada cancha es un espacio con su propio nombre (enunciado) y el selector de cancha agrupa los espacios del mismo tipo en la sede, o el espacio contiene canchas?
CU-12-AMB-06 · 2026-09-27 · abierta · ¿las sedes tienen días de funcionamiento además del horario? ¿el horario puede variar según el día?
CU-12-AMB-07 · 2026-09-27 · abierta · para el día de hoy, ¿la franja de la hora en curso se ofrece o se considera pasada?
CU-12-AMB-08 · 2026-09-27 · abierta · ¿el precio es por espacio y fijo, o puede variar por horario o día?
CU-12-AMB-00 · 2026-09-27 · snapshot · congelado en 292a301
CU-12-AMB-00 · 2026-09-27 · snapshot · congelado en 3aa4a53
CU-12-AMB-01 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-12-AMB-01 · 2026-09-27 · resuelta · duración de 1 a 4 horas y hasta 7 días de anticipación (decisión 6)
CU-12-AMB-02 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-12-AMB-02 · 2026-09-27 · resuelta · duración de 1 a 4 horas y hasta 7 días de anticipación (decisión 6)
CU-12-AMB-06 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-12-AMB-06 · 2026-09-27 · resuelta · la sede tiene apertura, cierre y los días de la semana en que abre; el horario es el mismo todos esos días (decisión 7)
CU-12-AMB-09 · 2026-09-28 · abierta · el prototipo sólo trae el estado vacío por duración: ¿qué dice cuando la sede no abre ese día o ya no quedan turnos libres?
CU-12-AMB-10 · 2026-09-28 · abierta · ¿qué cuenta la nota «N no disponibles» y qué pasa con las horas de hoy que ya pasaron?
CU-12-AMB-11 · 2026-09-28 · abierta · ¿adónde lleva CONTINUAR mientras CU-09 no existe, y qué datos le pasa?
CU-12-AMB-12 · 2026-09-28 · abierta · al cambiar cancha, fecha o duración, ¿se conserva la franja elegida?
CU-12-AMB-13 · 2026-09-28 · abierta · el CU cierra los errores con «Aceptar»; el overlay de conexión tiene REINTENTAR y Volver: ¿cuál va, y qué queda en la pantalla después?
CU-12-AMB-03 · 2026-09-28 · vencida → CU-12-SUP-01 · la grilla muestra todas las horas de inicio que entran en el horario de la sede con la duración elegida; las que no se pueden reservar van atenuadas y no se pueden tocar, como el prototipo (decisión 12)
CU-12-AMB-04 · 2026-09-28 · vencida → CU-12-SUP-02 · la grilla se lee al entrar y en cada cambio de cancha, fecha o duración, y no se refresca sola; si la franja se ocupa antes de confirmar, lo resuelve CU-09 (393:6553)
CU-12-AMB-05 · 2026-09-28 · vencida → CU-12-SUP-03 · cada cancha es un espacio (decisión 8); SELECCIONÁ CANCHA ofrece los espacios activos de la misma sede, deporte y tipo, por número, como «Cancha N» con su condición, y arranca en la que se tocó en la sede
CU-12-AMB-07 · 2026-09-28 · vencida → CU-12-SUP-04 · en la hora del club (Argentina), una franja que ya empezó no se ofrece: hoy la grilla arranca en la próxima hora en punto
CU-12-AMB-08 · 2026-09-28 · vencida → CU-12-SUP-05 · el precio es el del espacio, igual a toda hora; el total es precio por hora por cantidad de horas
CU-12-AMB-09 · 2026-09-28 · vencida → CU-12-SUP-06 · el título es siempre «No hay horarios disponibles»; el texto dice la causa: «La sede no abre ese día. Probá con otra fecha.», con más de una hora el del prototipo («Con N horas seguidas no entra ningún turno antes del cierre. Probá con una duración menor, otra fecha u otra cancha.»), y si no «Ya no quedan turnos libres ese día. Probá con otra fecha u otra cancha.»
CU-12-AMB-10 · 2026-09-28 · vencida → CU-12-SUP-07 · la nota cuenta las franjas de la grilla que no se pueden elegir; con 1 hora dice «Algunos horarios ya están ocupados · N no disponibles» y con más «Con N horas hay menos inicios posibles · M no disponibles», como el prototipo; sin franjas atenuadas no hay nota; las horas de hoy que ya pasaron no están en la grilla ni en la cuenta
CU-12-AMB-11 · 2026-09-28 · vencida → CU-12-SUP-08 · CONTINUAR abre «Confirmá tu reserva» (48:123) con la sede, la cancha, la fecha, el horario y el total; confirmar la reserva es de CU-09
CU-12-AMB-12 · 2026-09-28 · vencida → CU-12-SUP-09 · se conserva la hora de inicio elegida si sigue disponible con la nueva cancha, fecha o duración; si no, se quita y el resumen vuelve a «Sin horario elegido»
CU-12-AMB-13 · 2026-09-28 · vencida → CU-12-SUP-10 · los overlays compartidos (decisión 12, TP-07): conexión con REINTENTAR y Volver, servidor con ACEPTAR; al cerrarlos la grilla queda sin horarios y con REINTENTAR
CU-12-TESTS · 2026-09-28 · congelados en 77ba1d1 · 14 escenarios en rojo porque la pantalla de horarios no tiene fecha, duración, grilla ni resumen; en H06 y H07 queda esperando sin fin después del aviso
