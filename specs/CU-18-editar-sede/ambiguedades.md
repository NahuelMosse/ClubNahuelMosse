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
