# Ambigüedades — CU-09 · Reservar cancha

Doble lectura (épica de reservas): dos lecturas independientes que no se vieron entre sí, más la
propia. Coincidieron en los cuatro flujos, en la falta de flujos de error y en que las reglas del
enunciado (futuro, horas completas, cierre) no están en el CU. Divergencias:
- Una marcó Permisos como «no aplica»; la otra preguntó por un tope de reservas por usuario.
- Una dio Rastro por resuelto porque la reserva se liga al usuario; la otra preguntó por la fecha
  de creación.
- Sólo una marcó el choque de medio de notificación (correo contra push) y el precio que el
  enunciado no nombra.
La lectura propia agregó los choques con el prototipo: estado «Confirmada» contra «ACTIVA»,
redirección automática contra botones, y texto de FA1.

## Las diez preguntas
| Caso vacío    | la card no dice qué ve el usuario si la cancha no tiene ningún horario libre en la fecha; lo resuelve CU-12 FA4 («No hay horarios disponibles»)
| Duplicados    | la card dice: FA1 cuando «otro usuario lo reservó primero» y el enunciado prohíbe la superposición; no dice si el mismo usuario puede tener dos reservas superpuestas en espacios distintos → CU-09-AMB-01
| Validación    | la card dice: FA2 «Confirmar Reserva» deshabilitado si falta un campo; el enunciado agrega futuro, horas completas, mínimo una hora y fin antes del cierre, validados en el backend
| Error         | la card no lo dice; el enunciado exige manejar sin conexión y servidor caído → CU-09-AMB-02
| Estado        | la card dice: «La reserva queda registrada en estado "Confirmada"»; no dice los demás estados ni sus nombres → CU-09-AMB-03
| Permisos      | la card dice: usuario registrado; no dice si el administrador puede reservar ni si hay tope de reservas activas por usuario → CU-09-AMB-04
| Límites       | la card no dice duración máxima ni anticipación máxima (ver CU-12-AMB-01 y CU-12-AMB-02) → CU-09-AMB-05
| Orden         | la card dice el orden de los pasos: sede, cancha, fecha, horario, confirmar
| Concurrencia  | la card dice: FA1 cubre dos usuarios sobre el mismo horario, y el enunciado exige que el backend valide antes de registrar; no dice cómo se garantiza si dos confirman en el mismo instante → CU-09-AMB-06
| Rastro        | la card no dice que se estampe cuándo se creó la reserva ni el precio vigente en ese momento (CU-22 puede cambiarlo después) → CU-09-AMB-07

## Eventos
CU-09-AMB-01 · 2026-09-27 · abierta · ¿un usuario puede tener dos reservas en el mismo horario en espacios distintos?
CU-09-AMB-02 · 2026-09-27 · abierta · sin conexión o con el servidor caído al confirmar, ¿se usan los overlays compartidos y se vuelve a la confirmación sin crear nada?
CU-09-AMB-03 · 2026-09-27 · abierta · ¿cómo se llaman los estados de una reserva: Confirmada (CU-09) o Activa (prototipo, CU-11), y Completada, Cancelada, Anulada?
CU-09-AMB-04 · 2026-09-27 · abierta · ¿hay tope de reservas activas por usuario? ¿el administrador puede reservar?
CU-09-AMB-05 · 2026-09-27 · abierta · ¿duración máxima y anticipación máxima de una reserva? (mismas preguntas que CU-12-AMB-01 y CU-12-AMB-02)
CU-09-AMB-06 · 2026-09-27 · abierta · con dos confirmaciones simultáneas del mismo horario, ¿el backend garantiza que gane una sola (restricción en la base) y la otra cae en FA1?
CU-09-AMB-07 · 2026-09-27 · abierta · ¿la reserva guarda fecha de creación y el precio por hora y total vigentes al reservar, aunque el espacio cambie de precio después?
CU-09-AMB-08 · 2026-09-27 · abierta · ¿la confirmación se avisa por push, por correo, o sólo en pantalla? ¿«Te vamos a avisar una hora antes» es CU-24.1?
CU-09-AMB-09 · 2026-09-27 · abierta · ¿el comprobante redirige solo a Mis reservas (CU) o espera que el usuario elija (prototipo)?
CU-09-AMB-10 · 2026-09-27 · abierta · ¿se muestra y guarda precio? El enunciado no lo pide; el CU y el prototipo sí
CU-09-AMB-11 · 2026-09-27 · abierta · en FA3, ¿«guardar la intención» significa volver a la confirmación con los mismos datos después del login?
CU-09-AMB-12 · 2026-09-27 · abierta · ¿qué texto manda en FA1: el del CU o el del prototipo?
CU-09-AMB-00 · 2026-09-27 · snapshot · congelado en d198954
CU-09-AMB-00 · 2026-09-27 · snapshot · congelado en e51011e
