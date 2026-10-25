# RED-05 · paleta verde eléctrico

card: RED-05
status: proposed
cap: 3 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión: «te dejo la noche para que mejores el figma a ver si encontras algo para mejorarle, creo que nos conviene volver al verde electrico, porque no me convence el violeta» (2026-10-24) y «quedo perfecto, pasa eso a la aplicacion» (2026-10-25)"
  - "Figma · https://www.figma.com/design/zCsUSxyy2QjwEJ7AyR6XWt (copia del usuario) · las 33 variables de la colección `Color` en sus modos Dark y Light, leídas con use_figma el 2026-10-25; el componente `Linea-Del-Dia` (2007:7132) y las variantes deshabilitadas de `Btn` (6:4, 6:18)"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "creo que nos conviene volver al verde electrico, porque no me convence el violeta" · acceptance: cada color de `Paleta.oscura` y `Paleta.clara` es el de su variable de la colección `Color` del Figma, en las 33 variables
- S2 · "pasa eso a la aplicacion" · acceptance: la línea del día pinta la hora libre con `accent/libre`, la ocupada con `state/disabled` y la elegida con `accent/ink`, como el componente `Linea-Del-Dia` del Figma; la leyenda usa los mismos tres colores
- S3 · "pasa eso a la aplicacion" · acceptance: el botón principal deshabilitado es gris como la variante deshabilitada de `Btn` del Figma: fondo `state/disabled`, texto `text/secondary`, sin opacidad
- RED-05-ASM-01 · el `text/muted` oscuro del Figma (#85858C) se toma tal cual, porque llega a 4,5:1 sobre las tres superficies oscuras ; el #8C86A4 de la paleta violeta era su corrección · S1
- RED-05-ASM-02 · el lima de `accent/base` queda igual en los dos modos, como en el Figma: en modo claro el acento como texto o borde fino usa `accent/ink`, y el lima va de fondo con `accent/on` encima · S1
- RED-05-ASM-03 · el botón atenuado (que se ve deshabilitado pero acepta el toque) no es el gris del deshabilitado: baja sólo el fondo del lima al 40 % y deja el texto en `text/primary`, porque se puede tocar y su texto tiene que llegar a 4,5:1, como ya pide el supuesto del botón atenuado de REV-04; el gris con `text/secondary` da 4,4:1 en modo oscuro · S3

## Tasks

- T1 · S1,RED-05-ASM-01,RED-05-ASM-02 · apps/mobile/lib/tema/tokens.dart (presentation) · tests: apps/mobile/test/rediseno/paleta_verde_test.dart "cada color de la paleta oscura es el del Figma @RED-01-S1 @RED-05-S1"; apps/mobile/test/rediseno/paleta_verde_test.dart "cada color de la paleta clara es el del Figma @RED-01-S1 @RED-05-S1"; apps/mobile/test/rediseno/paleta_verde_test.dart "el textMuted oscuro es el #85858C del Figma y llega a 4,5:1 sobre las tres superficies @RED-01-ASM-01 @RED-05-ASM-01"; apps/mobile/test/rediseno/paleta_verde_test.dart "el lima es el mismo en los dos modos y en modo claro la tinta del acento llega a 4,5:1 @RED-05-ASM-02"; apps/mobile/test/rediseno/paleta_verde_test.dart "la etiqueta sobre foto, como «Fútbol 5», es del acento con su texto @RED-01-ASM-03 @RED-05-ASM-02"
- T2 · S2 · apps/mobile/lib/comun/linea_del_dia.dart (presentation) · tests: apps/mobile/test/rediseno/linea_del_dia_verde_test.dart "libre es accentLibre, ocupado stateDisabled y elegido accentInk @RED-02-ASM-02 @RED-05-S2"
- T3 · S3,RED-05-ASM-03 · apps/mobile/lib/comun/boton.dart (presentation) · tests: apps/mobile/test/rediseno/boton_deshabilitado_test.dart "el botón principal deshabilitado es gris, con texto secundario y sin opacidad @RED-05-S3"; apps/mobile/test/rediseno/boton_atenuado_verde_test.dart "el botón atenuado baja sólo el fondo del lima, deja el texto principal y acepta el toque @RED-05-ASM-03"
- T4 · S1 · apps/mobile/test/capturas/ · tests: apps/mobile/test/rediseno/paleta_verde_test.dart "cada color de la paleta oscura es el del Figma @RED-01-S1 @RED-05-S1"

## Changes to existing behavior

- `lib/tema/tokens.dart`: la paleta pasa de violeta a verde eléctrico y suma `accentLibre` · apps/mobile/test/rediseno/paleta_rediseno_test.dart (dos de colores y el de textMuted) se reemplazan, ver Log
- La línea del día cambia los colores de libre y elegido · apps/mobile/test/rediseno/componentes_test.dart "libre es accentMuted, ocupado stateDisabled y elegido accentBase @RED-02-ASM-02" se reemplaza
- El botón principal deshabilitado pasa a gris; el atenuado sigue en lima translúcido
- Las capturas se regeneran (commit propio)

## Look

- ref: Figma zCsUSxyy2QjwEJ7AyR6XWt, página `03 · App · Prototipo` (variables de la colección `Color`, `Linea-Del-Dia`, `Btn`)
- behavior: load · sin cambios de movimiento; sólo cambian los colores
- tokens: lib/tema/tokens.dart, copia de la colección `Color` del Figma

## Gate

```
suite: sh D:/Temp/w/herramientas/flutter-mobile.sh
lint: D:/projects/flutter/bin/flutter analyze --no-pub apps/mobile
```

## Log

- L1 · te dejo la noche para que mejores el figma a ver si encontras algo para mejorarle, creo que nos conviene volver al verde electrico, porque no me convence el violeta · (sobre el Figma mejorado) quedo perfecto, pasa eso a la aplicacion
- L2 · 2026-10-25 · replaces: apps/mobile/test/rediseno/paleta_rediseno_test.dart "cada color de la paleta oscura es el del Figma, salvo textMuted @RED-01-S1" · fija los valores violeta y el Figma pasó al verde eléctrico · by: apps/mobile/test/rediseno/paleta_verde_test.dart "cada color de la paleta oscura es el del Figma @RED-01-S1 @RED-05-S1"
- L3 · 2026-10-25 · replaces: apps/mobile/test/rediseno/paleta_rediseno_test.dart "cada color de la paleta clara es el del Figma @RED-01-S1" · fija los valores violeta y el Figma pasó al verde eléctrico · by: apps/mobile/test/rediseno/paleta_verde_test.dart "cada color de la paleta clara es el del Figma @RED-01-S1 @RED-05-S1"
- L4 · 2026-10-25 · replaces: apps/mobile/test/rediseno/paleta_rediseno_test.dart "el textMuted oscuro es #8C86A4 y llega a 4,5:1 sobre las tres superficies @RED-01-ASM-01" · #8C86A4 corregía el gris violáceo; el gris neutro del Figma ya llega a 4,5:1 · by: apps/mobile/test/rediseno/paleta_verde_test.dart "el textMuted oscuro es el #85858C del Figma y llega a 4,5:1 sobre las tres superficies @RED-01-ASM-01 @RED-05-ASM-01"
- L5 · 2026-10-25 · replaces: apps/mobile/test/rediseno/sobre_foto_test.dart "la etiqueta sobre foto, como «Fútbol 5», es violeta con texto blanco @RED-01-ASM-03" · el acento ya no es violeta ni su texto blanco · by: apps/mobile/test/rediseno/paleta_verde_test.dart "la etiqueta sobre foto, como «Fútbol 5», es del acento con su texto @RED-01-ASM-03 @RED-05-ASM-02"
- L6 · 2026-10-25 · replaces: apps/mobile/test/rediseno/componentes_test.dart "libre es accentMuted, ocupado stateDisabled y elegido accentBase @RED-02-ASM-02" · en el Figma libre y elegido se confundían; el componente pasó a `accent/libre` y `accent/ink` · by: apps/mobile/test/rediseno/linea_del_dia_verde_test.dart "libre es accentLibre, ocupado stateDisabled y elegido accentInk @RED-02-ASM-02 @RED-05-S2"
- L7 · 2026-10-24 · replaces: apps/mobile/test/rediseno/movimiento_pantallas_test.dart "con reducir movimiento el festejo, el aviso y la entrada muestran su final en el primer cuadro @RED-04-S14" · exige que no quede ningún cuadro agendado justo después del primer montaje, pero MaterialApp siempre agenda el de su ruta inicial, con cualquier implementación · by: apps/mobile/test/rediseno/movimiento_reducido_reemplazo_test.dart "con reducir movimiento el festejo, el aviso y la entrada muestran su final en el primer cuadro @RED-04-S14" · (copiada de RED-04: la compuerta sólo lee el Log de la card en curso)
- L8 · 2026-10-24 · replaces: apps/mobile/test/rediseno/pantallas_test.dart "con «No hay horarios disponibles» no va la línea del día @RED-03-ASM-08" · monta la app dos veces en el mismo test y el segundo montaje reusa la API del primero (App crea sus servicios una vez), así que nunca ve la grilla vacía · by: apps/mobile/test/rediseno/pantallas_horarios_vacios_test.dart "con «No hay horarios disponibles» no va la línea del día @RED-03-ASM-08" · (copiada de RED-04: la compuerta sólo lee el Log de la card en curso)
- L9 · 2026-10-22 · replaces: apps/mobile/test/interfaz_accesible_test.dart "con un dato completado sólo se marca lo que falta, y escribirlo borra su error @REV-04-S1 @assumption:REV-04-ASM-01" · monta PantallaRegistro sin GoRouter y el alta exitosa llama context.go · by: apps/mobile/test/interfaz_accesible_registro_reemplazo_test.dart "con un dato completado sólo se marca lo que falta, y escribirlo borra su error @REV-04-S1 @assumption:REV-04-ASM-01" · (copiada de RED-04: la compuerta sólo lee el Log de la card en curso)
- L10 · 2026-10-23 · replaces: apps/mobile/test/operacion_cliente_limite_test.dart "el límite por defecto se agota justo a los 60 s, no un segundo después @REV-02-S8 @assumption:REV-02-ASM-06" · pide rutas de prueba (/lento, /a, /b, /rapido) y REV-08 hace fallar en debug toda ruta que la app no declara · by: apps/mobile/test/operacion_cliente_sin_verificar_rutas_test.dart "el límite por defecto se agota justo a los 60 s, no un segundo después @REV-02-S8 @assumption:REV-02-ASM-06 @INT-01-ASM-01" · (copiada de RED-04: la compuerta sólo lee el Log de la card en curso)
- L11 · 2026-10-23 · replaces: apps/mobile/test/operacion_cliente_test.dart "el límite por defecto es de 60 s y se agota con ServidorSinRespuesta @REV-02-S8 @assumption:REV-02-ASM-06" · pide rutas de prueba (/lento, /a, /b, /rapido) y REV-08 hace fallar en debug toda ruta que la app no declara · by: apps/mobile/test/operacion_cliente_sin_verificar_rutas_test.dart "el límite por defecto es de 60 s y se agota con ServidorSinRespuesta @REV-02-S8 @assumption:REV-02-ASM-06 @INT-01-ASM-01" · (copiada de RED-04: la compuerta sólo lee el Log de la card en curso)
- L12 · 2026-10-23 · replaces: apps/mobile/test/operacion_cliente_test.dart "despertando se enciende pasados 5 s y se apaga al terminar el pedido @REV-02-S8 @assumption:REV-02-ASM-11" · pide rutas de prueba (/lento, /a, /b, /rapido) y REV-08 hace fallar en debug toda ruta que la app no declara · by: apps/mobile/test/operacion_cliente_sin_verificar_rutas_test.dart "despertando se enciende pasados 5 s y se apaga al terminar el pedido @REV-02-S8 @assumption:REV-02-ASM-11 @INT-01-ASM-01" · (copiada de RED-04: la compuerta sólo lee el Log de la card en curso)
- L13 · 2026-10-23 · replaces: apps/mobile/test/operacion_cliente_test.dart "despertando sigue encendido mientras quede un pedido lento @REV-02-S8 @assumption:REV-02-ASM-11" · pide rutas de prueba (/lento, /a, /b, /rapido) y REV-08 hace fallar en debug toda ruta que la app no declara · by: apps/mobile/test/operacion_cliente_sin_verificar_rutas_test.dart "despertando sigue encendido mientras quede un pedido lento @REV-02-S8 @assumption:REV-02-ASM-11 @INT-01-ASM-01" · (copiada de RED-04: la compuerta sólo lee el Log de la card en curso)
- L14 · 2026-10-23 · replaces: apps/mobile/test/operacion_cliente_test.dart "un pedido rápido no cuenta como lento para despertando @REV-02-S8 @assumption:REV-02-ASM-11" · pide rutas de prueba (/lento, /a, /b, /rapido) y REV-08 hace fallar en debug toda ruta que la app no declara · by: apps/mobile/test/operacion_cliente_sin_verificar_rutas_test.dart "un pedido rápido no cuenta como lento para despertando @REV-02-S8 @assumption:REV-02-ASM-11 @INT-01-ASM-01" · (copiada de RED-04: la compuerta sólo lee el Log de la card en curso)
- L15 · 2026-10-24 · replaces: apps/mobile/test/rediseno/sobre_foto_test.dart "el contador de la tarjeta de sede es violeta con cifra blanca @RED-01-ASM-04" · el reemplazo tiene que llevar el tag del reemplazado; el dorsal ocupa el lugar del bloque violeta (RED-03-ASM-14) · by: apps/mobile/test/rediseno/contador_sede_reemplazo_test.dart "el contador de la tarjeta de sede es el dorsal sobre la foto, en el color del texto sobre foto @RED-01-ASM-04 @RED-03-ASM-14" · (copiada de RED-04: la compuerta sólo lee el Log de la card en curso)
- L16 · 2026-10-24 · replaces: apps/mobile/test/rediseno/pantallas_test.dart "horarios con «No hay horarios disponibles» no va la línea del día @RED-03-ASM-08" · el mismo test de L8 con el nombre que le da flutter test (antepone el grupo «horarios») · by: apps/mobile/test/rediseno/pantallas_horarios_vacios_test.dart "con «No hay horarios disponibles» no va la línea del día @RED-03-ASM-08" · (copiada de RED-04: la compuerta sólo lee el Log de la card en curso)
- L17 · 2026-10-25 · replaces: apps/mobile/test/rediseno/pantallas_test.dart "inicio los tiles usan las fotos de la app, no navegan y se anuncian sólo por su nombre @RED-03-ASM-03" · cada tile abre «Buscar cancha» con su deporte elegido · by: apps/mobile/test/rediseno/tiles_de_deporte_reemplazo_test.dart "los tiles usan las fotos de la app, ninguno está elegido y tocar uno abre «Buscar cancha» con ese deporte @RED-03-ASM-03" · (copiada de RED-04: la compuerta sólo lee el Log de la card en curso)
- L18 · 2026-10-25 · replaces: apps/mobile/test/rediseno/boton_deshabilitado_test.dart "el botón atenuado usa el mismo gris y acepta el toque @RED-05-ASM-03" · el atenuado se puede tocar y REV-04-ASM-07 le pide fondo más tenue que el activo y texto a 4,5:1; el gris con `text/secondary` da 4,4:1 en modo oscuro · by: apps/mobile/test/rediseno/boton_atenuado_verde_test.dart "el botón atenuado baja sólo el fondo del lima, deja el texto principal y acepta el toque @RED-05-ASM-03"
- L19 · 2026-10-25 · declared · K4 · apps/mobile/test/rediseno/paleta_verde_test.dart · reemplazo de tests congelados de paleta_rediseno_test.dart: repite su cálculo de contraste y su tabla porque el congelado no se puede editar para compartirlos
- L20 · 2026-10-25 · declared · K4 · apps/mobile/test/rediseno/boton_atenuado_verde_test.dart · test congelado de reemplazo: repite el cálculo de contraste de paleta_verde_test.dart, también congelado
- L21 · 2026-10-25 · declared · K4 · apps/mobile/lib/comun/boton.dart · los clones con barra_inferior.dart y pantalla_buscar_cancha.dart (líneas 199-216) son anteriores a esta card; RED-05 sólo cambió los colores de BotonPrimario
- L22 · 2026-10-25 · closing: publicación sin correr — la rama, el PR y el comentario de cierre no se publican sin un pedido expreso (CLAUDE.md del repo); la card se integra a main en local
