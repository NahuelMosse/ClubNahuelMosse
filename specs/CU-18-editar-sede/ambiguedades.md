# Ambigüedades — CU-18 · Editar sede

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | la card dice: vaciar un obligatorio marca el campo y deshabilita «Guardar cambios» (FA2)
| Duplicados    | la card no dice si se puede renombrar la sede con el nombre de otra → CU-18-AMB-01
| Validación    | la card dice «valida en vivo» los obligatorios; no dice si la apertura tiene que ser anterior al cierre (misma pregunta que CU-17-AMB-03)
| Error         | la card dice: FA5 overlay compartido y datos conservados
| Estado        | la card dice: sólo se edita una sede «activa»; FA4 cubre la dada de baja en otra sesión
| Permisos      | la card dice: administrador con sesión iniciada
| Límites       | la card dice: achicar el horario con reservas afuera pide confirmación (FA3); no dice si se puede agrandar sin límite → CU-18-AMB-02
| Orden         | no aplica
| Concurrencia  | la card dice: FA4 sede dada de baja desde otra sesión; no dice qué pasa si otro administrador editó la misma sede → CU-18-AMB-03
| Rastro        | la card no dice que se estampe cuándo y quién editó, ni el horario anterior → CU-18-AMB-04

## Eventos
CU-18-AMB-01 · 2026-09-27 · abierta · ¿se rechaza renombrar la sede con un nombre que ya usa otra?
CU-18-AMB-02 · 2026-09-27 · abierta · ¿hay algún límite para el horario (por ejemplo, no antes de las 06:00 ni después de las 24:00)?
CU-18-AMB-03 · 2026-09-27 · abierta · con dos administradores editando la misma sede, ¿gana el último o se muestra «Esto cambió mientras tanto»?
CU-18-AMB-04 · 2026-09-27 · abierta · ¿se guarda quién y cuándo editó la sede, y los valores anteriores?
CU-18-AMB-05 · 2026-09-27 · abierta · si cambian el nombre o la dirección, ¿se renombran los espacios de la sede o conservan el nombre con el que se crearon?
CU-18-AMB-06 · 2026-09-27 · abierta · las reservas que quedan fuera del horario nuevo, ¿se mantienen (CU, prototipo) o se anulan y se avisa (CU-24.2)?
CU-18-AMB-00 · 2026-09-27 · snapshot · congelado en b7f6779
CU-18-AMB-04 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-18-AMB-04 · 2026-09-27 · resuelta · todas las entidades guardan fecha de creación y de modificación, las acciones del administrador guardan su autor, la reserva guarda el precio del momento; las bajas son lógicas y no borran historial (decisión 4)
CU-18-AMB-05 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-18-AMB-05 · 2026-09-27 · resuelta · cada cancha es un espacio; deporte y tipo salen de un catálogo fijo; el nombre lleva la altura, sin tildes ni espacios; el número no se reutiliza; el nombre no cambia si se edita la sede; el alta pide techada o al aire libre e iluminación (decisión 8)
CU-18-AMB-07 · 2026-09-29 · abierta · ¿la edición incluye DÍAS QUE ABRE, como el alta y el prototipo 62:1968, aunque el CU sólo nombre los horarios?
CU-18-AMB-08 · 2026-09-29 · abierta · con un obligatorio vacío, ¿GUARDAR CAMBIOS se deshabilita (CU FA2) o se ve atenuado y marca los campos al tocarlo, como el alta (CU-17-SUP-09)?
CU-18-AMB-09 · 2026-09-29 · abierta · FA4: ¿cómo se informa que la sede ya no está disponible?
CU-18-AMB-10 · 2026-09-29 · abierta · FA6: ¿hasta dónde llega esta card cuando se toca DAR DE BAJA LA SEDE?
CU-18-AMB-11 · 2026-09-29 · abierta · ¿cómo se muestra «Los cambios se guardaron correctamente» y adónde vuelve?
CU-18-AMB-01 · 2026-09-29 · vencida → CU-18-SUP-01 · renombrar con el nombre de otra sede activa se rechaza con «Ya existe una sede con ese nombre», como el alta (CU-17-SUP-02); la misma sede puede quedarse con su nombre
CU-18-AMB-02 · 2026-09-29 · vencida → CU-18-SUP-02 · los mismos límites que el alta (CU-17-SUP-03 y SUP-05): horas en punto, el cierre después de la apertura o a las 00:00, sin otro tope
CU-18-AMB-03 · 2026-09-29 · vencida → CU-18-SUP-03 · con dos administradores editando la misma sede gana el último que guarda; sólo la baja en otra sesión se avisa (FA4)
CU-18-AMB-06 · 2026-09-29 · vencida → CU-18-SUP-04 · las reservas que quedan fuera del horario nuevo se mantienen (CU, prototipo 393:6496); el aviso cuenta las futuras activas que empiezan antes de la apertura nueva, terminan después del cierre nuevo o caen en un día que la sede deja de abrir
CU-18-AMB-07 · 2026-09-29 · vencida → CU-18-SUP-05 · la edición incluye DÍAS QUE ABRE con las mismas opciones del alta, como el prototipo 62:1968
CU-18-AMB-08 · 2026-09-29 · vencida → CU-18-SUP-06 · GUARDAR CAMBIOS se deshabilita mientras un campo tenga error, como dice el CU: los datos vienen cargados, así que el error se ve apenas se vacía el campo
CU-18-AMB-09 · 2026-09-29 · vencida → CU-18-SUP-07 · el overlay compartido «Esto cambió mientras tanto» (393:6532); VER LO ACTUALIZADO vuelve al listado, que se lee de nuevo
CU-18-AMB-10 · 2026-09-29 · vencida → CU-18-SUP-08 · DAR DE BAJA LA SEDE abre la confirmación de CU-19 (42:329); lo que pasa al confirmar es de CU-19
CU-18-AMB-11 · 2026-09-29 · vencida → CU-18-SUP-09 · un aviso abajo con «Los cambios se guardaron correctamente» y vuelta al listado del panel, que se lee de nuevo
