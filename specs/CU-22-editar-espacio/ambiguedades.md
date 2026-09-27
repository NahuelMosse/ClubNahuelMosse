# Ambigüedades — CU-22 · Editar espacio deportivo

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | la card dice: precio vacío marca el campo y deshabilita el botón (FA2)
| Duplicados    | no aplica: el nombre no se edita, así que no puede chocar con otro
| Validación    | la card dice: «numérico y mayor a cero» (paso 3, FA2)
| Error         | la card dice: FA5 overlay compartido y datos conservados
| Estado        | la card dice que se edita la «condición» o «disponibilidad» sin decir qué valores tiene ni qué pasa con las reservas de un espacio fuera de servicio → CU-22-AMB-01
| Permisos      | la card dice: administrador con sesión iniciada
| Límites       | la card no dice si hay precio máximo ni decimales → CU-22-AMB-02
| Orden         | no aplica
| Concurrencia  | la card dice: FA4 espacio dado de baja en otra sesión; no dice qué pasa si otro administrador cambió el precio → CU-22-AMB-03
| Rastro        | la card dice: las reservas conservan el precio con el que se hicieron; no dice que se guarde el historial de precios ni quién lo cambió → CU-22-AMB-04

## Eventos
CU-22-AMB-01 · 2026-09-27 · abierta · ¿existe un estado «fuera de servicio temporal»? Si existe, ¿qué pasa con las reservas futuras de ese espacio y cómo se vuelve a habilitar?
CU-22-AMB-02 · 2026-09-27 · abierta · ¿el precio admite centavos? ¿hay tope?
CU-22-AMB-03 · 2026-09-27 · abierta · con dos administradores editando el mismo espacio, ¿gana el último o «Esto cambió mientras tanto»?
CU-22-AMB-04 · 2026-09-27 · abierta · ¿se guarda quién cambió el precio, cuándo y el valor anterior?
CU-22-AMB-05 · 2026-09-27 · abierta · ¿la baja se inicia desde la edición (CU) o sólo desde el listado (prototipo)?
CU-22-AMB-00 · 2026-09-27 · snapshot · congelado en c75c540
CU-22-AMB-04 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-22-AMB-04 · 2026-09-27 · resuelta · todas las entidades guardan fecha de creación y de modificación, las acciones del administrador guardan su autor, la reserva guarda el precio del momento; las bajas son lógicas y no borran historial (decisión 4)
