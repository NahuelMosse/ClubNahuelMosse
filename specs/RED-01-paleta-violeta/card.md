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

- S1 · "con este dise;o actualicemos la app real" · acceptance: cada una de las 32 variables de la colección `Color` de ref/figma-spec.md es un campo de `Paleta` con su mismo nombre y su valor en modo oscuro y en modo claro, salvo las que corrige RED-01-ASM-01
- S2 · "accent/on-media = #D4FF3D | #D4FF3D" · acceptance: el acento sobre foto sale de `accentOnMedia` (lima en los dos modos) en: el botón de texto sobre foto (comun/boton.dart), el sobretítulo «BUENOS DÍAS,» del inicio (inicio/pantalla_inicio.dart), el sobretítulo de la cabecera de la sede (sedes/pantalla_sede.dart), el de confirmar reserva (reservas/pantalla_confirmar_reserva.dart), el de horarios (reservas/pantalla_horarios.dart) y el acento del login (sesion/pantalla_inicio_sesion.dart)
- S3 · "text/on-media = #FFFFFF | #FFFFFF" y "text/on-media-muted = #DCD8EE | #D4D4D8" · acceptance: el texto sobre foto sale de `textOnMedia` y `textOnMediaMuted`, no de la paleta oscura ni de colores escritos a mano, en: inicio/pantalla_inicio.dart, sedes/pantalla_sede.dart, sedes/pantalla_sedes.dart, reservas/pantalla_confirmar_reserva.dart, reservas/pantalla_horarios.dart y sesion/pantalla_inicio_sesion.dart
- S4 · "state/danger-strong = #E02D4A | #B91C1C" · acceptance: el botón de peligro relleno (comun/boton.dart) usa `stateDangerStrong`
- S5 · "bg/hero-from = #2A1A55 | #EEE8FF" y "bg/hero-to = #0B0A12 | #FFFFFF" · acceptance: la única cabecera con degradé, la del perfil (usuarios/pantalla_mi_perfil.dart), va de `bgHeroFrom` a `bgHeroTo`
- RED-01-ASM-01 · `textMuted` en modo oscuro queda en #8C86A4 y no en #87819F: el del Figma no llega a 4,5:1 sobre `bgSurfaceRaised`, que la app exige para todo texto (desvío mínimo, mismo tono) · S1
- RED-01-ASM-02 · los pares de contraste que la paleta cumple a 4,5:1 en los dos modos son: textPrimary, textSecondary, textMuted y accentInk sobre bgBase, bgSurface y bgSurfaceRaised; accentOn sobre accentBase; stateDangerInk sobre bgBase; blanco sobre stateDangerStrong; textOnMedia y accentOnMedia sobre negro. `accentBase` es relleno, nunca color de texto chico, y no entra · S1
- RED-01-ASM-03 · la etiqueta sobre foto sigue al Figma («Fútbol 5» en ref/sede-espacios.png): fondo `accentBase` violeta con texto `accentOn` blanco, y no lima · S2
- RED-01-ASM-04 · el contador de canchas de la tarjeta de sede (sedes/pantalla_sedes.dart) sigue al Figma (Card-Sede, «Contador» en `accent/base`): fondo `accentBase` con cifra `accentOn` · S2

## Tasks

- T1 · S1,RED-01-ASM-01,RED-01-ASM-02 · apps/mobile/lib/tema/tokens.dart (presentation) · tests: apps/mobile/test/rediseno/paleta_rediseno_test.dart "cada color de la paleta oscura es el del Figma, salvo textMuted @RED-01-S1"; apps/mobile/test/rediseno/paleta_rediseno_test.dart "cada color de la paleta clara es el del Figma @RED-01-S1"; apps/mobile/test/rediseno/paleta_rediseno_test.dart "el textMuted oscuro es #8C86A4 y llega a 4,5:1 sobre las tres superficies @RED-01-ASM-01"; apps/mobile/test/rediseno/paleta_rediseno_test.dart "cada par de contraste de la paleta llega a 4,5:1 en los dos modos @RED-01-ASM-02"
- T2 · S2,S3,S4,RED-01-ASM-03,RED-01-ASM-04 · apps/mobile/lib/comun/boton.dart (presentation), apps/mobile/lib/comun/etiqueta.dart (presentation), apps/mobile/lib/inicio/pantalla_inicio.dart (presentation), apps/mobile/lib/sedes/pantalla_sede.dart (presentation), apps/mobile/lib/sedes/pantalla_sedes.dart (presentation), apps/mobile/lib/reservas/pantalla_confirmar_reserva.dart (presentation), apps/mobile/lib/reservas/pantalla_horarios.dart (presentation), apps/mobile/lib/sesion/pantalla_inicio_sesion.dart (presentation) · tests: apps/mobile/test/rediseno/sobre_foto_test.dart "el botón sobre foto usa accentOnMedia @RED-01-S2"; apps/mobile/test/rediseno/sobre_foto_test.dart "el sobretítulo del inicio usa accentOnMedia @RED-01-S2"; apps/mobile/test/rediseno/sobre_foto_test.dart "el sobretítulo de la sede usa accentOnMedia @RED-01-S2"; apps/mobile/test/rediseno/sobre_foto_test.dart "el sobretítulo de confirmar reserva usa accentOnMedia @RED-01-S2"; apps/mobile/test/rediseno/sobre_foto_test.dart "el sobretítulo de horarios usa accentOnMedia @RED-01-S2"; apps/mobile/test/rediseno/sobre_foto_test.dart "el acento del login usa accentOnMedia @RED-01-S2"; apps/mobile/test/rediseno/sobre_foto_test.dart "el texto sobre foto de cada pantalla sale de los tokens on-media @RED-01-S3"; apps/mobile/test/rediseno/sobre_foto_test.dart "el botón de peligro relleno usa stateDangerStrong @RED-01-S4"; apps/mobile/test/rediseno/sobre_foto_test.dart "la etiqueta sobre foto, como «Fútbol 5», es violeta con texto blanco @RED-01-ASM-03"; apps/mobile/test/rediseno/sobre_foto_test.dart "el contador de la tarjeta de sede es violeta con cifra blanca @RED-01-ASM-04"
- T3 · S5 · apps/mobile/lib/usuarios/pantalla_mi_perfil.dart (presentation) · tests: apps/mobile/test/rediseno/sobre_foto_test.dart "la cabecera del perfil va de bgHeroFrom a bgHeroTo @RED-01-S5"
- T4 · S1 · apps/mobile/test/capturas/ · tests: apps/mobile/test/rediseno/paleta_rediseno_test.dart "cada color de la paleta clara es el del Figma @RED-01-S1"

## Changes to existing behavior

- Toda la app cambia de lima a violeta como acento; la tinta de acento queda en lima en modo oscuro y lo que va sobre foto sigue en lima
- La etiqueta sobre foto y el contador de la tarjeta de sede pasan de lima a violeta con texto blanco
- Las capturas de `test/capturas/` se regeneran (commit propio)
- Rutas, pantallas y comportamiento quedan igual

## Look

- ref: specs/RED-01-paleta-violeta/ref/home-llegada.png · specs/RED-01-paleta-violeta/ref/perfil-claro.png · specs/RED-01-paleta-violeta/ref/sede-espacios.png · specs/RED-01-paleta-violeta/ref/figma-spec.md
- behavior: load · sin cambios de movimiento (es de RED-04)
- tokens: los de ref/figma-spec.md, colección `Color` (Dark | Light) y `Scale`

## Gate

```
suite: sh D:/Temp/w/herramientas/flutter-mobile.sh
lint: sh D:/Temp/w/herramientas/dart-format-analyze-red.sh apps/mobile/test/rediseno/paleta_rediseno_test.dart apps/mobile/test/rediseno/sobre_foto_test.dart
```

## Log

- L1 · con este dise;o actualicemos la app real (el diseño es el rediseño «Camiseta del club» del Figma https://www.figma.com/design/zCsUSxyy2QjwEJ7AyR6XWt: paleta violeta #7C4DFF con lima #D4FF3D para cifras y tinta, componentes de identidad —Marcador, Tile-Deporte, Ficha de socio, pase troquelado, Línea del día, Card-Sede con dorsal, Isotipo— y animaciones de entrada y transiciones; esta card toma la paleta; los componentes, las pantallas y el movimiento van en RED-02, RED-03 y RED-04)
- L2 · 2026-10-23 · plan judge (oracle en el rol de judge, el agente judge no está en la sesión): ACT-01..06 cerrados en Specs y Tasks; ver judge.md
