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
CU-22-AMB-06 · 2026-09-30 · abierta · el mensaje de precio inválido: ¿el del CU, el del prototipo 390:6522 o el del alta (CU-21)?
CU-22-AMB-07 · 2026-09-30 · abierta · con el precio inválido, ¿GUARDAR ESPACIO se deshabilita (CU FA2) o se ve atenuado y marca el campo al tocarlo, como el alta?
CU-22-AMB-08 · 2026-09-30 · abierta · ¿cómo se muestra «Los cambios se guardaron correctamente» y adónde vuelve? ¿y cómo se informa FA4?
CU-22-AMB-01 · 2026-09-30 · vencida → CU-22-SUP-01 · la «condición» es techada o al aire libre, más la iluminación, editables como en el prototipo 63:2302; no hay un estado «fuera de servicio»: sacar un espacio de servicio es darlo de baja (CU-23)
CU-22-AMB-02 · 2026-09-30 · vencida → CU-22-SUP-02 · pesos enteros entre $ 1 y $ 9.999.999, los mismos límites del alta (CU-21)
CU-22-AMB-03 · 2026-09-30 · vencida → CU-22-SUP-03 · con dos administradores editando el mismo espacio gana el último que guarda; sólo la baja en otra sesión se avisa (FA4)
CU-22-AMB-05 · 2026-09-30 · vencida → CU-22-SUP-04 · la baja se inicia desde la edición con DAR DE BAJA EL ESPACIO (CU FA6) y también desde «Baja» en la tarjeta del listado (prototipo 63:1895, CU-23); en esta card el botón abre la confirmación de CU-23
CU-22-AMB-06 · 2026-09-30 · vencida → CU-22-SUP-05 · los mensajes del alta: vacío «Este campo es obligatorio», fuera de rango «Ingresá un precio entre $ 1 y $ 9.999.999»; el campo sólo acepta dígitos, así que las letras no llegan a escribirse
CU-22-AMB-07 · 2026-09-30 · vencida → CU-22-SUP-06 · GUARDAR ESPACIO se deshabilita mientras el precio sea inválido o no haya cambios (CU FA2 y FA3), como la edición de sede (CU-18-SUP-06)
CU-22-AMB-08 · 2026-09-30 · vencida → CU-22-SUP-07 · al guardar, un aviso abajo con «Los cambios se guardaron correctamente» y el listado releído; FA4 con el overlay compartido «Esto cambió mientras tanto» (393:6532) y el listado
