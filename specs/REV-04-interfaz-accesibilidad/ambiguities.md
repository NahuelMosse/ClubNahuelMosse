# Ambigüedades — REV-04 · interfaz y accesibilidad

## The ten questions

| Empty case    | the card says: "CREAR CUENTA está deshabilitado, y tocarlo con el formulario vacío muestra 0 errores"; the card does not say cómo se muestran los faltantes → REV-04-AMB-01
| Duplicates    | not applicable: la card no crea datos; sólo cambia cómo se muestran
| Validation    | the card says: "al salir de un campo vacío aparece el error"; CU-03 FA1: «Se muestra un mensaje/tooltip … indicando los campos faltantes»; CU-18 FA2: «Guardar cambios» se deshabilita → REV-04-AMB-01, REV-04-AMB-04
| Limits        | the card says: "4,06:1 con 15 px en negrita, debajo de AA", "con el texto al 200 %", "a 320×568"; the card does not say qué hace la barra cuando el texto no entra → REV-04-AMB-05
| Permissions   | not applicable: la card no cambia quién ve qué pantalla
| State         | the card says: "el rechazo de una reserva sale en un SnackBar de 4 s y la pantalla vuelve atrás al mismo tiempo"; the card does not say en qué pantalla queda la persona → REV-04-AMB-02
| Error         | the card says: "el error de cada campo es un nodo aparte, y el formato esperado («DD / MM / AAAA») queda oculto para el lector" → REV-04-AMB-02 para el rechazo de la reserva
| Order         | the card says: "ningún botón tiene `autofocus` y el primer Tab cae en el destructivo"; CU-09 pinta «Cancelar» de rojo → REV-04-AMB-03
| Concurrency   | not applicable: cada pantalla es de una sola persona y la card no cambia lo que se envía
| Trail         | not applicable: la card no registra ni guarda nada

## Events

REV-04-AMB-00 · 2026-10-20 · snapshot · frozen at 2025557
REV-04-AMB-01 · 2026-10-20 · no channel · Cuando alguien toca CREAR CUENTA con datos sin completar, ¿cómo se le muestra qué falta, y cuándo desaparece ese aviso? → REV-04-ASM-01
REV-04-AMB-02 · 2026-10-20 · no channel · Si el club rechaza una reserva o un cambio porque el turno ya se ocupó, ¿la persona vuelve a los horarios enseguida o primero lee el motivo y decide? → REV-04-ASM-02
REV-04-AMB-03 · 2026-10-20 · no channel · En una confirmación que no se puede deshacer, ¿qué botón queda elegido de entrada y en qué orden se recorren con el teclado? → REV-04-ASM-03
REV-04-AMB-04 · 2026-10-20 · no channel · La edición de sede deshabilita «Guardar cambios» mientras falta algo (lo dice su caso de uso) y el alta no: ¿se unifican mostrando qué falta al tocar guardar? → REV-04-ASM-04 · leaves without effect: «Guardar cambios se deshabilita» (CU-18 FA2)
REV-04-AMB-05 · 2026-10-20 · no channel · Con el texto del teléfono al doble de tamaño, ¿la barra de abajo puede achicar sus palabras para que entren enteras? → REV-04-ASM-05
REV-04-AMB-06 · 2026-10-20 · no channel · Las fechas y los precios se escriben con el formato del club y su hora fija: ¿alcanza, o hay que preparar la app para otras zonas y monedas? → REV-04-ASM-06 · leaves without effect: «sin zona IANA, sin `DateFormat` con locale ni ISO 4217»
REV-04-AMB-07 · 2026-10-20 · no channel · El botón «atenuado» es el de guardar que todavía no tiene todo: ¿tiene que seguir viéndose apagado, o alcanza con que se lea bien? → REV-04-ASM-07
REV-04-AMB-08 · 2026-10-20 · no channel · El calendario de fecha de nacimiento toma el día del teléfono: ¿tiene que tomar el día del club, igual que el de reservas? → REV-04-ASM-08
REV-04-OUT-01 · 2026-10-20 · medium · apps/mobile/lib/reservas/reservas.dart:161 · un 422 con un error que no es texto se descarta y errores.values.first revienta si queda vacío — not touched
REV-04-OUT-02 · 2026-10-20 · proposal · fechas y precios con DateFormat por locale, zona IANA e ISO 4217 (I26), fuera del alcance por REV-04-ASM-06 — not built
