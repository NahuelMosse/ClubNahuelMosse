# Ambigüedades — REV-03 · datos

## The ten questions

| Empty case    | the card does not say qué devuelve una página pedida más allá de la última → REV-03-AMB-01
| Duplicates    | the card says: "si el proceso cae entre `tomar_siguiente` y `marcar_envio`, el aviso queda en `enviando` para siempre"; CU-24.1 dice «Se envía una sola vez»; the card does not say si reenviar puede duplicar un aviso que sí salió → REV-03-AMB-02
| Validation    | the card does not say qué se hace con un marcador de página que no se entiende → REV-03-AMB-01
| Limits        | the card says: "1,2 s en la página 500"; the card does not say cuántas filas por página tiene el historial propio ni cuánto espera un aviso «enviando» antes de darlo por perdido → REV-03-AMB-03, REV-03-AMB-04
| Permissions   | not applicable: la card no cambia quién ve qué; cada historial conserva sus permisos
| State         | the card says: "el aviso queda en `enviando` para siempre; un recordatorio registrado y no enviado tampoco se reintenta"; the card does not say la tabla de transiciones nueva → REV-03-AMB-05
| Error         | the card says: "Los downgrade de 0003, 0005 y 0007 borran tablas con datos"; the card does not say qué tiene que comprobar la ida y vuelta en esas → REV-03-AMB-06
| Order         | the card says (CU-14): historial ordenado por fecha y hora, más reciente primero; CU-08: «listado ordenado por fecha»; con empate en el inicio, the card does not say → REV-03-AMB-07
| Concurrency   | the card does not say qué pasa si dos barridos toman el mismo aviso varado, o si una reserva entra entre dos páginas → REV-03-AMB-08
| Trail         | the card says: "la trazabilidad del admin muestra «todavía no salió» indefinidamente"; the card does not say qué queda anotado de cada intento → REV-03-AMB-09; y CU-14: "Encabeza el listado el contador total" contra "hace dos `count(*)` por página" → REV-03-AMB-10

## Events

REV-03-AMB-00 · 2026-10-20 · snapshot · frozen at ab84031
REV-03-AMB-01 · 2026-10-20 · no channel · Si alguien pide una página que ya no existe o un marcador de página que no corresponde, ¿se le muestra una lista vacía o un error? → REV-03-ASM-01
REV-03-AMB-02 · 2026-10-20 · no channel · Si el servidor se cae justo mientras manda un aviso y no se sabe si salió, ¿se vuelve a mandar (con riesgo de que llegue dos veces) o se da por fallido? → REV-03-ASM-02 · leaves without effect: «se vuelve a enviar» para el recordatorio varado, que queda fallido por «Se envía una sola vez» de CU-24.1
REV-03-AMB-03 · 2026-10-20 · no channel · ¿Cuántas reservas trae cada tanda del historial propio antes de pedir más? → REV-03-ASM-03
REV-03-AMB-04 · 2026-10-20 · no channel · ¿Cuánto tiempo sin respuesta hace falta para dar por perdido un aviso que se estaba mandando, y cuántas veces se reintenta? → REV-03-ASM-04
REV-03-AMB-05 · 2026-10-20 · no channel · ¿Por qué estados pasa un aviso cuando se reintenta y cuándo deja de intentarse? → REV-03-ASM-05
REV-03-AMB-06 · 2026-10-20 · no channel · Volver atrás una versión de la base que creó una tabla borra sus datos: ¿alcanza con que vuelva a quedar como estaba, aunque esos datos se pierdan? → REV-03-ASM-06
REV-03-AMB-07 · 2026-10-20 · no channel · Si dos reservas empiezan a la misma hora, ¿cuál va primero en el historial? → REV-03-ASM-07
REV-03-AMB-08 · 2026-10-20 · no channel · Si entra una reserva nueva mientras alguien recorre el historial, ¿tiene que aparecer en las páginas que ya vio? → REV-03-ASM-08
REV-03-AMB-09 · 2026-10-20 · no channel · ¿Qué se anota de cada intento de envío de un aviso para que el administrador sepa qué pasó? → REV-03-ASM-09
REV-03-AMB-10 · 2026-10-20 · no channel · El historial global muestra el total de reservas arriba: ¿ese total tiene que seguir siendo exacto en cada página, aunque contarlo cueste recorrer la tabla? → REV-03-ASM-10 · leaves without effect: «sin recorrer ni contar toda la tabla» para la primera página, que sigue contando por índice para el total de CU-14
