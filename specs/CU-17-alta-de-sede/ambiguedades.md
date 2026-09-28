# Ambigüedades — CU-17 · Alta de sede

Una sola lectura del CU (card chica), declarada.

## Las diez preguntas
| Caso vacío    | la card no dice qué muestra el listado del panel si todavía no hay sedes → CU-17-AMB-01
| Duplicados    | la card no dice si se rechaza una sede con el mismo nombre o la misma dirección que otra → CU-17-AMB-02
| Validación    | la card dice: nombre, dirección y horarios obligatorios (FA2); no dice si la apertura tiene que ser anterior al cierre ni si son horas completas → CU-17-AMB-03
| Error         | la card dice: FA3 «Error al guardar la sede», conserva los datos, «Reintentar» o «Volver»
| Estado        | la card dice: queda registrada «permanentemente» y se muestra en el listado; no dice si nace activa → CU-17-AMB-04
| Permisos      | la card dice: «El administrador debe estar autenticado y contar con permisos de administración»
| Límites       | la card no dice largo máximo de nombre y dirección ni si el horario puede cruzar la medianoche → CU-17-AMB-05
| Orden         | la card no dice en qué orden aparece la sede nueva en los listados → CU-17-AMB-06
| Concurrencia  | la card no dice qué pasa si dos administradores crean la misma sede a la vez → CU-17-AMB-02
| Rastro        | la card no dice que se estampe cuándo se creó y qué administrador la creó → CU-17-AMB-07

## Eventos
CU-17-AMB-01 · 2026-09-27 · abierta · sin sedes cargadas, ¿qué muestra el panel admin?
CU-17-AMB-02 · 2026-09-27 · abierta · ¿se rechaza una sede con nombre o dirección repetidos? ¿con qué mensaje?
CU-17-AMB-03 · 2026-09-27 · abierta · ¿la apertura tiene que ser anterior al cierre y en hora completa?
CU-17-AMB-04 · 2026-09-27 · abierta · ¿la sede nueva queda visible para los usuarios apenas se crea, aunque no tenga espacios?
CU-17-AMB-05 · 2026-09-27 · abierta · ¿largos máximos? ¿se admite un horario que cruza la medianoche?
CU-17-AMB-06 · 2026-09-27 · abierta · ¿en qué orden se listan las sedes?
CU-17-AMB-07 · 2026-09-27 · abierta · ¿se guarda fecha de alta y qué administrador la dio de alta?
CU-17-AMB-08 · 2026-09-27 · abierta · ¿el horario es uno solo para todos los días o varía por día de la semana? (ver CU-12-AMB-06)
CU-17-AMB-09 · 2026-09-27 · abierta · ¿cómo se escribe la dirección para que después sirva al nombre de los espacios (calle y altura separados)?
CU-17-AMB-00 · 2026-09-27 · snapshot · congelado en 29fa056
CU-17-AMB-00 · 2026-09-27 · snapshot · congelado en 7d94a0f
CU-17-AMB-00 · 2026-09-27 · snapshot · congelado en 452aaa4
CU-17-AMB-07 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-17-AMB-07 · 2026-09-27 · resuelta · todas las entidades guardan fecha de creación y de modificación, las acciones del administrador guardan su autor, la reserva guarda el precio del momento; las bajas son lógicas y no borran historial (decisión 4)
CU-17-AMB-08 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-17-AMB-08 · 2026-09-27 · resuelta · la sede tiene apertura, cierre y los días de la semana en que abre; el horario es el mismo todos esos días (decisión 7)
CU-17-AMB-10 · 2026-09-28 · abierta · ¿qué opciones ofrece «DÍAS QUE ABRE»? el prototipo muestra sólo «Lunes a domingo» y el listado también «Lunes a sábado» y «Todos los días»
CU-17-AMB-11 · 2026-09-28 · abierta · el CU (FA2) hace que el administrador intente guardar y se le marquen los faltantes; el prototipo deja GUARDAR SEDE al 40 % mientras falten datos: ¿se puede tocar?
CU-17-AMB-01 · 2026-09-28 · vencida → CU-17-SUP-01 · sin sedes, el panel dice «0 SEDES ACTIVAS» y «Todavía no hay sedes», con AGREGAR SEDE arriba como siempre
CU-17-AMB-02 · 2026-09-28 · vencida → CU-17-SUP-02 · no puede haber dos sedes activas con el mismo nombre, sin distinguir mayúsculas: «Ya existe una sede con ese nombre»; la dirección sí puede repetirse. Lo garantiza un índice único, así que dos altas a la vez no pasan las dos
CU-17-AMB-03 · 2026-09-28 · vencida → CU-17-SUP-03 · los horarios son horas en punto; el cierre va después de la apertura, y 00:00 como cierre es la medianoche: «El cierre tiene que ser después de la apertura»
CU-17-AMB-04 · 2026-09-28 · vencida → CU-17-SUP-04 · la sede nace activa y los usuarios la ven apenas se crea, aunque todavía no tenga canchas
CU-17-AMB-05 · 2026-09-28 · vencida → CU-17-SUP-05 · nombre hasta 60 caracteres y dirección hasta 80; el horario no cruza la medianoche salvo cerrar justo a las 00:00
CU-17-AMB-06 · 2026-09-28 · vencida → CU-17-SUP-06 · las sedes se listan por nombre, en orden alfabético
CU-17-AMB-09 · 2026-09-28 · vencida → CU-17-SUP-07 · la dirección es un solo campo «Calle y altura»; la altura es el número del final y, si falta, «Escribí la calle y la altura»
CU-17-AMB-10 · 2026-09-28 · vencida → CU-17-SUP-08 · «DÍAS QUE ABRE» ofrece «Lunes a domingo» (el que viene elegido), «Lunes a sábado» y «Lunes a viernes»
CU-17-AMB-11 · 2026-09-28 · vencida → CU-17-SUP-09 · GUARDAR SEDE se ve al 40 % mientras falten datos, como el prototipo, pero se puede tocar: no envía nada y marca en rojo cada campo que falta, como el CU. Un campo que se deja vacío se marca al salir de él
CU-17-TESTS · 2026-09-28 · congelados en bebde07 · 6 escenarios de pantalla en rojo porque el panel admin no tiene la sección SEDES, y H01-03 de API en rojo porque no existe POST /sedes (404)
