# Ambigüedades — REV-05 · Básquet en el catálogo

## The ten questions

| Empty case    | the card says: "`GET /espacios/catalogo` devuelve Futbol, Tenis, Padel, Voley, Hockey y Golf"; una sede sin canchas de Básquet no muestra el filtro de Básquet (el filtro lista sólo deportes con canchas): not applicable a la card, sigue igual
| Duplicates    | not applicable: el alta de una cancha de Básquet sigue la regla de número por sede, deporte y tipo que ya existe
| Validation    | the card says: "El enunciado lo da como ejemplo de tipo filtrable («Fútbol, Paddle, Básquet, etc.»)"; the card does not say qué tipos de cancha tiene Básquet → REV-05-AMB-01
| Limits        | not applicable: Básquet usa los mismos límites de precio, horario y duración que el resto
| Permissions   | not applicable: el alta es del administrador y el filtro del socio, como en los demás deportes
| State         | not applicable: las canchas de Básquet tienen los mismos estados que las demás
| Error         | not applicable: los errores del alta son los de siempre («Elegí un tipo de la lista»)
| Order         | the card does not say en qué lugar del catálogo va Básquet → REV-05-AMB-02
| Concurrency   | not applicable: la card no agrega operaciones
| Trail         | not applicable: la card no agrega datos que se pierdan; y la app no tiene una foto de Básquet → REV-05-AMB-03

## Events

REV-05-AMB-00 · 2026-10-20 · snapshot · frozen at b7d7c30
REV-05-AMB-01 · 2026-10-20 · no channel · ¿Qué tipos de cancha de Básquet tiene el club: cancha completa, media cancha para 3 contra 3, o las dos? → REV-05-ASM-01
REV-05-AMB-02 · 2026-10-20 · no channel · ¿En qué lugar de la lista de deportes aparece Básquet? → REV-05-ASM-03
REV-05-AMB-03 · 2026-10-20 · no channel · La app no tiene una foto de una cancha de Básquet: ¿se usa por ahora otra portada del club o hay que conseguir una? → REV-05-ASM-02
REV-05-TESTS · 2026-10-20 · frozen at 8f752a4
