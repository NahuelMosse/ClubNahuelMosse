# Ambigüedades — CU-06 · Editar perfil

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | la card no dice qué pasa si el usuario borra un campo y guarda (¿nombre vacío es inválido?) → CU-06-AMB-01
| Duplicados    | la card no dice qué pasa si cambia el DNI por uno que ya tiene otra cuenta (CU-03 FA2 lo prohíbe al registrar) → CU-06-AMB-02
| Validación    | la card dice: «El formato de los datos no es valido» (FA1) sin decir qué formato vale para cada campo → CU-06-AMB-03
| Error         | la card dice: FA2 «Error de conectividad» y vuelve al paso 3; no dice qué pasa si falla el servidor → CU-06-AMB-04
| Estado        | la card no dice cómo se sale del modo edición sin guardar → CU-06-AMB-05
| Permisos      | la card dice: el usuario edita su propio perfil; el enunciado dice «salvo la dirección de correo electrónico»; no dice si el DNI es editable → CU-06-AMB-06
| Límites       | la card no dice largos máximos ni rango de fecha de nacimiento → CU-06-AMB-07
| Orden         | no aplica
| Concurrencia  | la card no dice qué pasa si el perfil se editó desde otro dispositivo mientras tanto → CU-06-AMB-08
| Rastro        | la card no dice que se estampe cuándo se modificó el perfil → CU-06-AMB-09

## Eventos
CU-06-AMB-01 · 2026-09-27 · abierta · ¿nombre, apellido y fecha de nacimiento son obligatorios al editar? ¿qué mensaje tiene un campo vaciado?
CU-06-AMB-02 · 2026-09-27 · abierta · ¿un DNI nuevo que ya existe en otra cuenta se rechaza? ¿con qué mensaje?
CU-06-AMB-03 · 2026-09-27 · abierta · ¿qué formato vale para DNI, fecha, nombre y apellido? (mismas reglas que el registro, CU-03-AMB-02)
CU-06-AMB-04 · 2026-09-27 · abierta · con el servidor caído al guardar, ¿overlay compartido de error del servidor y se conserva lo escrito?
CU-06-AMB-05 · 2026-09-27 · abierta · ¿hay un «Cancelar» para salir de la edición? ¿volver atrás descarta los cambios sin preguntar?
CU-06-AMB-06 · 2026-09-27 · abierta · ¿el DNI se puede editar? ¿el correo aparece en el formulario como deshabilitado o no aparece?
CU-06-AMB-07 · 2026-09-27 · abierta · ¿largos máximos de nombre y apellido y rango válido de fecha de nacimiento?
CU-06-AMB-08 · 2026-09-27 · abierta · si otro dispositivo editó el perfil mientras tanto, ¿gana el último guardado o se muestra «Esto cambió mientras tanto»?
CU-06-AMB-09 · 2026-09-27 · abierta · ¿se guarda fecha y hora de la última modificación del perfil?
CU-06-AMB-10 · 2026-09-27 · abierta · ¿se marcan en verde los campos válidos (CU) o sólo en rojo los inválidos (prototipo)?
CU-06-AMB-00 · 2026-09-27 · snapshot · congelado en 8406dcb
CU-06-AMB-03 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-06-AMB-03 · 2026-09-27 · resuelta · la contraseña del registro sigue las reglas de CU-04; DNI de 7 u 8 dígitos, editable y único; fecha de nacimiento pasada, sin edad mínima (decisión 9)
CU-06-AMB-04 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-06-AMB-04 · 2026-09-27 · resuelta · se usan los overlays compartidos del prototipo en toda la app (decisión 11)
CU-06-AMB-06 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-06-AMB-06 · 2026-09-27 · resuelta · la contraseña del registro sigue las reglas de CU-04; DNI de 7 u 8 dígitos, editable y único; fecha de nacimiento pasada, sin edad mínima (decisión 9)
CU-06-AMB-09 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-06-AMB-09 · 2026-09-27 · resuelta · todas las entidades guardan fecha de creación y de modificación, las acciones del administrador guardan su autor, la reserva guarda el precio del momento; las bajas son lógicas y no borran historial (decisión 4)
CU-06-AMB-10 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-06-AMB-10 · 2026-09-27 · resuelta · si el CU y el prototipo dicen distinto, manda el prototipo (decisión 12)
CU-06-AMB-01 · 2026-09-27 · vencida → CU-06-SUP-01 · nombre, apellido, DNI y fecha son obligatorios también al editar; un campo vaciado se marca con el mismo «El formato de los datos no es válido»
CU-06-AMB-02 · 2026-09-27 · vencida → CU-06-SUP-02 · un DNI que ya tiene otra cuenta activa no se guarda: el campo muestra «Este DNI ya está registrado», como en el registro
CU-06-AMB-05 · 2026-09-27 · vencida → CU-06-SUP-03 · no hay «Cancelar» (el prototipo no lo tiene): salir de la pantalla descarta la edición sin preguntar
CU-06-AMB-07 · 2026-09-27 · vencida → CU-06-SUP-04 · los mismos límites que el registro: nombre y apellido de hasta 60 caracteres y fecha pasada
CU-06-AMB-08 · 2026-09-27 · vencida → CU-06-SUP-05 · gana el último guardado
CU-06-TESTS · 2026-09-27 · congelados en 01ffb51 · 4 escenarios de pantalla en rojo porque el modo edición no tiene campos; H01-03 nace en verde: el selector de tema lo trajo CU-05
