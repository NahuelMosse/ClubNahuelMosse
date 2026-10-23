# RED-01 · paleta violeta del rediseño

card: RED-01
status: proposed
cap: 3 h
sources:
  - "pedido (texto) · mensaje del usuario en la sesión, 2026-10-23: «con este dise;o actualicemos la app real»"
  - "Figma · https://www.figma.com/design/zCsUSxyy2QjwEJ7AyR6XWt (copia del usuario) · colección de variables `Color` (modos Dark y Light) y `Scale`, leídas enteras con use_figma; transcritas en specs/RED-01-paleta-violeta/ref/figma-spec.md"
  - "capturas del Figma · specs/RED-01-paleta-violeta/ref/*.png (11 pantallas exportadas con get_screenshot)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"
  - "pantallas del Figma que no se exportaron como captura (las 117 restantes): se leyeron sólo sus animaciones y transiciones, que son de RED-04"

## Specs

- S1 · "con este dise;o actualicemos la app real" · acceptance: cada color de `Paleta` toma el valor de la variable del Figma con su mismo nombre, en modo oscuro y en modo claro (tabla de ref/figma-spec.md)
- S2 · "accent/on-media = #D4FF3D | #D4FF3D" · acceptance: lo que va en lima sobre una foto (botón sobre foto, etiqueta sobre foto, acento del login) sigue en lima en los dos modos, aunque el acento pase a violeta
- S3 · "text/on-media = #FFFFFF | #FFFFFF" y "text/on-media-muted = #DCD8EE | #D4D4D8" · acceptance: el texto sobre foto usa esos tokens y no colores escritos a mano
- S4 · "state/danger-strong = #E02D4A | #B91C1C" · acceptance: el botón de peligro relleno usa `stateDangerStrong`
- S5 · "bg/hero-from = #2A1A55 | #EEE8FF" y "bg/hero-to = #0B0A12 | #FFFFFF" · acceptance: el degradé de las cabeceras va de `bgHeroFrom` a `bgHeroTo`
- RED-01-ASM-01 · `textMuted` en modo oscuro queda en #8C86A4 y no en #87819F: el del Figma no llega a 4,5:1 sobre `bgSurfaceRaised`, que la app exige para todo texto (desvío mínimo, mismo tono) · S1
- RED-01-ASM-02 · la regla de contraste de la app (4,5:1) manda sobre el Figma: si otro token del Figma no llega, se corrige el valor y se declara · S1

## Tasks

- T1 · S1,S2,S3,S4,S5,RED-01-ASM-01,RED-01-ASM-02 · apps/mobile/lib/tema/tokens.dart (presentation) · tests: apps/mobile/test/rediseno/paleta_rediseno_test.dart "cada color de la paleta oscura es el del Figma @RED-01-S1"; apps/mobile/test/rediseno/paleta_rediseno_test.dart "cada color de la paleta clara es el del Figma @RED-01-S1"; apps/mobile/test/rediseno/paleta_rediseno_test.dart "el textMuted oscuro es #8C86A4 y llega a 4,5:1 sobre las tres superficies @RED-01-ASM-01"; apps/mobile/test/rediseno/paleta_rediseno_test.dart "los textos y acentos de la paleta llegan a 4,5:1 en los dos modos @RED-01-ASM-02"
- T2 · S2,S3,S4,S5 · apps/mobile/lib/comun/boton.dart (presentation), apps/mobile/lib/comun/etiqueta.dart (presentation), apps/mobile/lib/sesion/pantalla_inicio_sesion.dart (presentation), apps/mobile/lib/sedes/pantalla_sedes.dart (presentation) · tests: apps/mobile/test/rediseno/paleta_rediseno_test.dart "el lima sobre foto sigue en lima en los dos modos @RED-01-S2"; apps/mobile/test/rediseno/paleta_rediseno_test.dart "el texto sobre foto usa los tokens on-media @RED-01-S3"; apps/mobile/test/rediseno/paleta_rediseno_test.dart "el botón de peligro relleno usa stateDangerStrong @RED-01-S4"; apps/mobile/test/rediseno/paleta_rediseno_test.dart "el degradé de cabecera va de bgHeroFrom a bgHeroTo @RED-01-S5"
- T3 · S1 · apps/mobile/test/capturas/ · tests: apps/mobile/test/rediseno/paleta_rediseno_test.dart "cada color de la paleta oscura es el del Figma @RED-01-S1"

## Changes to existing behavior

- Toda la app cambia de lima a violeta como acento; las cifras y la tinta de acento quedan en lima en modo oscuro
- Las capturas de `test/capturas/` se regeneran (commit propio)
- Rutas, pantallas y comportamiento quedan igual

## Look

- ref: specs/RED-01-paleta-violeta/ref/home-llegada.png · specs/RED-01-paleta-violeta/ref/perfil-claro.png · specs/RED-01-paleta-violeta/ref/figma-spec.md
- behavior: load · sin cambios de movimiento (es de RED-04)
- tokens: los de ref/figma-spec.md, colección `Color` (Dark | Light) y `Scale`

## Gate

```
suite: sh D:/Temp/w/herramientas/flutter-mobile.sh
lint: sh D:/Temp/w/herramientas/lint-mobile-red.sh
```

## Log

- L1 · con este dise;o actualicemos la app real (el diseño es el rediseño «Camiseta del club» del Figma https://www.figma.com/design/zCsUSxyy2QjwEJ7AyR6XWt: paleta violeta #7C4DFF con lima #D4FF3D para cifras y tinta, componentes de identidad —Marcador, Tile-Deporte, Ficha de socio, pase troquelado, Línea del día, Card-Sede con dorsal, Isotipo— y animaciones de entrada y transiciones; esta card toma la paleta; los componentes, las pantallas y el movimiento van en RED-02, RED-03 y RED-04)
