# Ambigüedades — CU-11 · Modificar reserva

Doble lectura (épica de reservas): dos lecturas independientes que no se vieron entre sí, más la
propia. Coincidieron en los seis flujos, en que la concurrencia está cubierta por FA2 y en que falta
verificar que la reserva sea del usuario. Divergencias:
- Una preguntó por un estado transitorio «modificando».
- La otra preguntó cuántas veces se puede modificar una misma reserva.
- Caso vacío: una preguntó qué pasa si no hay ninguna franja libre; la otra lo dio por no aplica.
La lectura propia agregó los choques con el prototipo: duración fija, cambio de cancha y overlay
compartido.

## Las diez preguntas
| Caso vacío    | la card no dice qué ve el usuario si el espacio no tiene ninguna franja libre distinta de la actual → CU-11-AMB-01
| Duplicados    | la card dice: el horario nuevo no puede superponerse con otra reserva del mismo espacio, validado por el backend
| Validación    | la card dice: futuro, horas completas, mínimo una hora, fin antes del cierre, sin superposición (reglas que hereda del enunciado)
| Error         | la card dice: FA5 overlay compartido, «La reserva queda como estaba»
| Estado        | la card dice: sólo se modifica una reserva Activa con horario futuro; FA4 cubre anulada y espacio dado de baja
| Permisos      | la card no dice que el backend verifique que la reserva sea del usuario → CU-11-AMB-02
| Límites       | la card no dice cuántas veces se puede modificar una reserva ni si puede cambiar la duración o el espacio → CU-11-AMB-03, CU-11-AMB-04
| Orden         | no aplica: se modifica una reserva por vez
| Concurrencia  | la card dice: FA2, si el horario nuevo se ocupó, «conserva la reserva original intacta»
| Rastro        | la card no dice que se guarde el horario anterior ni cuándo se modificó → CU-11-AMB-05

## Eventos
CU-11-AMB-01 · 2026-09-27 · abierta · si no hay ninguna franja libre distinta de la actual, ¿se muestra el estado vacío de CU-12?
CU-11-AMB-02 · 2026-09-27 · abierta · si alguien intenta modificar una reserva ajena por la API, ¿qué responde?
CU-11-AMB-03 · 2026-09-27 · abierta · ¿hay tope de modificaciones por reserva?
CU-11-AMB-04 · 2026-09-27 · abierta · ¿se puede cambiar la duración (componente Segmented del CU) o se mantiene (prototipo)? ¿se puede pasar a otra cancha del mismo tipo (prototipo) o sólo cambiar fecha y horario del mismo espacio (CU)?
CU-11-AMB-05 · 2026-09-27 · abierta · ¿se guarda el horario anterior y la fecha de la modificación?
CU-11-AMB-06 · 2026-09-27 · abierta · si cambia a un espacio con otro precio, ¿se recalcula el total?
CU-11-AMB-07 · 2026-09-27 · abierta · ¿el recordatorio de CU-24.1 se reprograma para el horario nuevo?
CU-11-AMB-08 · 2026-09-27 · abierta · en FA2, ¿mensaje propio y vuelta a la grilla (CU) u overlay compartido (prototipo)?
CU-11-AMB-00 · 2026-09-27 · snapshot · congelado en 8422895
CU-11-AMB-05 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-11-AMB-05 · 2026-09-27 · resuelta · todas las entidades guardan fecha de creación y de modificación, las acciones del administrador guardan su autor, la reserva guarda el precio del momento; las bajas son lógicas y no borran historial (decisión 4)
CU-11-AMB-08 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-11-AMB-08 · 2026-09-27 · resuelta · se usan los overlays compartidos del prototipo en toda la app (decisión 11)
CU-11-AMB-09 · 2026-09-28 · abierta · la grilla marca «(actual)» la franja de la reserva: ¿cómo se consulta la disponibilidad sin que la propia reserva la ocupe?
CU-11-AMB-10 · 2026-09-28 · abierta · al guardar el cambio, ¿adónde vuelve y cómo se entera la persona de que salió bien?
CU-11-AMB-01 · 2026-09-28 · vencida → CU-11-SUP-01 · la franja actual se muestra libre y marcada «(actual)»; si no hay otra libre, la grilla muestra sólo esa y el botón queda deshabilitado (FA3)
CU-11-AMB-02 · 2026-09-28 · vencida → CU-11-SUP-02 · la reserva de otra cuenta responde 404, como al cancelar (CU-10-SUP-02)
CU-11-AMB-03 · 2026-09-28 · vencida → CU-11-SUP-03 · sin tope de modificaciones: se puede modificar mientras la reserva siga activa y no haya empezado
CU-11-AMB-04 · 2026-09-28 · vencida → CU-11-SUP-04 · como el prototipo (decisión 12): se mantiene la duración y se puede pasar a otra cancha del mismo tipo en la misma sede, a otro día y a otro horario
CU-11-AMB-06 · 2026-09-28 · vencida → CU-11-SUP-05 · el total se recalcula con el precio del espacio nuevo en el momento del cambio, y la confirmación lo muestra antes de guardar
CU-11-AMB-07 · 2026-09-28 · vencida → CU-11-SUP-06 · el recordatorio sigue al horario nuevo; se programa con CU-24.1, que lo calcula del horario vigente de la reserva
CU-11-AMB-09 · 2026-09-28 · vencida → CU-11-SUP-07 · la API de horarios recibe la reserva que se modifica y no la cuenta como ocupada, sólo si es de quien consulta
CU-11-AMB-10 · 2026-09-28 · vencida → CU-11-SUP-08 · vuelve a Mis reservas, que se lee de nuevo, con el aviso «Reserva modificada» y el horario nuevo en la tarjeta
CU-11-TESTS · 2026-09-29 · congelados en 4840a22 · 9 escenarios en rojo porque Mis reservas no tiene MODIFICAR ni existe POST /reservas/{id}/modificar
