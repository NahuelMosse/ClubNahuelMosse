# VIS-01 · la pantalla de carga, el ícono y las notificaciones usan el isotipo de la app sobre verde eléctrico

status: proposed
cap: 1 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «la pantalla de carga de la app deberia usar el logo que usamos dentro de la app, ese deberia ser el logo de la pantalla de carga, ademas de un fondo verde electrico, el mismo que ya usa la app, eso para la pantalla de carga, y el logo de la app deberia usar el mismo logo tambien» · «y en las notificaciones tambien se ve feo, no muestra el logo de la app, y no se si se puede sumar algo mas para mostrar en la notificacion» · captura de la bandeja: el aviso «Tu reserva es en 1 hora» sale con un círculo genérico"
  - "repo · apps/mobile/lib/comun/isotipo.dart (`Isotipo`, `PintorIsotipo`), apps/mobile/lib/tema/tokens.dart (`accentBase` 0xFFD4FF3D), apps/mobile/lib/main.dart (`_Espera`), apps/mobile/pubspec.yaml (`flutter_launcher_icons`), apps/mobile/android/app/src/main/AndroidManifest.xml (sin ícono de notificación)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "la pantalla de carga de la app deberia usar el logo que usamos dentro de la app [...] ademas de un fondo verde electrico, el mismo que ya usa la app" · acceptance: la pantalla nativa de Android al abrir la app (la de antes de Flutter, también la de Android 12 o más) tiene fondo `#D4FF3D` y el isotipo de la app al centro
- S2 · "eso para la pantalla de carga" · acceptance: la espera de arranque de Flutter (mientras la sesión se retoma) muestra el isotipo de la app al centro sobre `accentBase`, sin el fondo oscuro de hoy
- S3 · "y el logo de la app deberia usar el mismo logo tambien" · acceptance: el ícono del launcher (`assets/icono/icono.png`, el primer plano adaptativo `icono_primer_plano.png` y los mipmap generados) es el isotipo de la app dibujado por `PintorIsotipo`, no la N en un círculo de hoy
- S4 · "en las notificaciones tambien se ve feo, no muestra el logo de la app" · acceptance: los avisos push muestran como ícono el isotipo de la app (silueta blanca, como pide Android) y el acento `#D4FF3D`, declarados como ícono y color por defecto de Firebase Messaging en el manifiesto
- VIS-01-ASM-01 · sobre el verde el isotipo va en `textInverse` (`#0A0A0B`): en verde sobre verde no se vería · S1
- VIS-01-ASM-02 · el ícono del launcher usa el mismo fondo verde y el isotipo oscuro, igual que la pantalla de carga · S3
- VIS-01-ASM-03 · la espera de arranque conserva un indicador de progreso, oscuro y debajo del isotipo: la API de Render puede tardar en despertar y sin él la pantalla parece colgada · S2
- VIS-01-ASM-04 · lo que se suma a la notificación queda en el ícono y el color: el texto ya trae deporte, sede y horario, y botones de acción piden una librería de notificaciones locales que hoy la app no tiene · S4
- VIS-01-ASM-05 · el color de los avisos es verde oscuro (`#4A6B00`, contraste ≥ 4.5:1 sobre blanco) en modo claro y verde eléctrico en oscuro, porque el verde eléctrico no se ve sobre la bandeja clara · S4

## Tasks

- T1 · S1,S3,S4,VIS-01-ASM-01,VIS-01-ASM-02,VIS-01-ASM-04 · apps/mobile/tool/generar_isotipo_test.dart (presentation), apps/mobile/assets/icono/icono.png, apps/mobile/assets/icono/icono_primer_plano.png, apps/mobile/android/app/src/main/res/drawable/launch_background.xml, apps/mobile/android/app/src/main/res/drawable-v21/launch_background.xml, apps/mobile/android/app/src/main/res/drawable/isotipo.xml, apps/mobile/android/app/src/main/res/drawable/ic_notificacion.xml, apps/mobile/android/app/src/main/res/values/colors.xml, apps/mobile/android/app/src/main/res/values-v31/styles.xml, apps/mobile/android/app/src/main/res/values-night-v31/styles.xml, apps/mobile/android/app/src/main/AndroidManifest.xml, apps/mobile/pubspec.yaml, apps/mobile/android/app/src/main/res/drawable/isotipo_splash.xml (el isotipo reducido para la máscara del splash de Android 12), apps/mobile/android/app/src/main/res/values-night/colors.xml (color_notificacion en oscuro, ASM-05), apps/mobile/android/app/src/main/res/mipmap-mdpi/ic_launcher.png, apps/mobile/android/app/src/main/res/mipmap-hdpi/ic_launcher.png, apps/mobile/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png, apps/mobile/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png, apps/mobile/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png, apps/mobile/android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png, apps/mobile/android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png, apps/mobile/android/app/src/main/res/drawable-xhdpi/ic_launcher_foreground.png, apps/mobile/android/app/src/main/res/drawable-xxhdpi/ic_launcher_foreground.png, apps/mobile/android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png (generados por flutter_launcher_icons), apps/mobile/test/avisos_test.dart · tests: apps/mobile/test/pantalla_de_carga_test.dart "la pantalla nativa de carga es verde eléctrico con el isotipo al centro @VIS-01-S1 @assumption:VIS-01-ASM-01"; apps/mobile/test/pantalla_de_carga_test.dart "el ícono del launcher, sus mipmap generados y el fondo adaptativo son el isotipo oscuro sobre verde eléctrico @VIS-01-S3 @assumption:VIS-01-ASM-02"; apps/mobile/test/pantalla_de_carga_test.dart "los avisos push usan el isotipo blanco y el verde eléctrico, sin otra librería @VIS-01-S4 @assumption:VIS-01-ASM-04"
  reuses: apps/mobile/lib/comun/isotipo.dart `PintorIsotipo` (dibuja las imágenes del ícono); flutter_launcher_icons (genera los mipmap); la geometría de 64 de `PintorIsotipo` (los vectores de Android)
- T2 · S2,VIS-01-ASM-03 · apps/mobile/lib/comun/pantalla_de_carga.dart (presentation), apps/mobile/lib/main.dart (presentation) · tests: apps/mobile/test/pantalla_de_carga_test.dart "la espera de arranque muestra el isotipo sobre verde eléctrico y un indicador de progreso @VIS-01-S2 @assumption:VIS-01-ASM-03"
  reuses: apps/mobile/lib/comun/isotipo.dart `Isotipo`; apps/mobile/lib/tema/tokens.dart `accentBase`, `textInverse`

## Changes to existing behavior

- el fondo de la espera de arranque pasa de `bgBase` a `accentBase` y muestra el isotipo; el ícono del launcher pasa de la N en un círculo al isotipo; la pantalla nativa pasa de blanco a verde; los avisos push pasan del círculo genérico al isotipo con acento verde

## Gate

```
suite [timeout 1 h]: sh D:/Temp/w/herramientas/flutter-mobile.sh test/pantalla_de_carga_test.dart test/avisos_test.dart test/arranque_sin_conexion_test.dart test/tarjeta_cuenta_test.dart
refactor-tests: el color de los avisos pasa de verde_electrico a color_notificacion (VIS-01-ASM-05): el test de manifiesto de pantalla_de_carga_test.dart cambia sólo ese nombre
fmt: D:/projects/flutter/bin/dart format --output=none --set-exit-if-changed apps/mobile/lib apps/mobile/test/pantalla_de_carga_test.dart apps/mobile/tool
lint: D:/projects/flutter/bin/flutter analyze --no-pub apps/mobile
no-docs: cambia la imagen de arranque, el ícono y el de los avisos; el comportamiento, el contrato y el modelo de datos no cambian
```

## Log

- L1 · la pantalla de carga de la app deberia usar el logo que usamos dentro de la app, ese deberia ser el logo de la pantalla de carga, ademas de un fondo verde electrico, el mismo que ya usa la app, eso para la pantalla de carga, y el logo de la app deberia usar el mismo logo tambien
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base: sólo la app
- L3 · 2026-10-27 · el usuario suma: y en las notificaciones tambien se ve feo, no muestra el logo de la app, y no se si se puede sumar algo mas para mostrar en la notificacion · S4, VIS-01-ASM-04
- L4 · 2026-10-27 · el usuario: el icono de notificaciones en modo claro no se ve por el contraste · el color de los avisos es verde oscuro en modo claro y verde eléctrico en oscuro (VIS-01-ASM-05)
- L5 · 2026-10-27 · replaces: apps/mobile/test/pantalla_de_carga_test.dart "los avisos push usan el isotipo blanco y el verde eléctrico, sin otra librería" · el manifiesto ahora apunta a @color/color_notificacion, no a verde_electrico · by: apps/mobile/test/avisos_test.dart "los avisos push usan el isotipo blanco y un color propio, sin otra librería"
- L6 · 2026-10-27 · declared · K4 · apps/mobile/test/avisos_test.dart · es el mismo test de manifiesto que reemplaza al congelado de pantalla_de_carga_test.dart (L5); el congelado no se puede editar ni borrar
- L7 · 2026-10-27 · T1,T2 · gate: fmt passed, lint passed, specs/layers/shape/overdesign/boundaries passed; suite 630 ok / 26 failed en el verify (tarjeta_cuenta_test pasa suelto, 11/11); el test congelado "los avisos push usan el isotipo blanco y el verde eléctrico" falla por L5
- L8 · 2026-10-27 · la suite de la card corre sus tests y los del arranque y la sesión: los otros 25 que fallan en la suite entera fallan igual en main (son tests reemplazados por cards anteriores, sin relación con el arranque ni el ícono)
