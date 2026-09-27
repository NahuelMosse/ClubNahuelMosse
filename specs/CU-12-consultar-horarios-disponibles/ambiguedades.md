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
