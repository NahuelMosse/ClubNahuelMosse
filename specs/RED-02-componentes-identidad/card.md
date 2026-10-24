# RED-02 · componentes de identidad del rediseño

card: RED-02
status: proposed
cap: 5 h
sources:
  - "pedido (texto) · mensaje del usuario en la sesión, 2026-10-23: «con este dise;o actualicemos la app real»"
  - "Figma · https://www.figma.com/design/zCsUSxyy2QjwEJ7AyR6XWt (copia del usuario) · página `02 · Components` (1:3): Marca/Isotipo 2002:6955, Tile-Deporte 2006:449, Marcador 2006:450, Ficha-Socio 2007:437, Linea-Del-Dia 2007:7132, Card-Sede 2295:487, Card-Reserva 20:319, leídos con use_figma; transcritos en specs/RED-02-componentes-identidad/ref/figma-spec.md («Componentes nuevos de identidad»)"
  - "capturas del Figma · specs/RED-02-componentes-identidad/ref/*.png"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"
  - "el trazo exacto del isotipo (7 vectores): se leyó su estructura y su color, no la geometría de cada vector"

## Specs

- S1 · "Marca/Isotipo 64×64: escudo de trazo `accent/base` 2.5 con pelota/cancha estilizada y punto relleno" · acceptance: `Isotipo` se dibuja en el tamaño pedido (64 por defecto) con trazo y punto en `accentBase`, y el lector lo anuncia como «Club Nahuel Mosse» o lo omite si es decorativo
- S2 · "Marcador 345×72: fila de 3 celdas (SEDES · CANCHAS · LIBRES HOY) separadas por líneas de 1×40 `border/default`; fondo `bg/scrim` @0.66 con desenfoque de fondo, borde `accent/base` 1, radio 16" · acceptance: `Marcador` muestra cada celda con su cifra (Archivo Black 28) y su rótulo (Inter Bold 11, mayúsculas), separadores entre celdas, borde `accentBase` y radio 16; la celda destacada lleva la cifra en `accentOnMedia`; el lector lee cada celda como «<cifra> <rótulo>»
- S3 · "Tile-Deporte 124×148 radio 20: foto del deporte con degradé oscuro abajo, emoji 16 + nombre Inter SemiBold 17 `text/on-media`. Estados Default / Selected / Pressed" · acceptance: `TileDeporte` muestra la foto que recibe con el degradé, el emoji y el nombre en `textOnMedia`; elegido lleva borde `accentBase` y la etiqueta «ELEGIDO»; al tocarlo llama a `alTocar`; el lector lo anuncia como botón con el nombre y su estado de elegido
- S4 · "Ficha-Socio 345×261 (perfil): foto + degradé, borde `accent/base` 1.5, radio 24 … Dorsal gigante «10» … Encabezado: «FICHA DE SOCIO» … isotipo 32 a la derecha. Identidad: iniciales en cuadrado 76 radio 20 `accent/base` … nombre Inter Bold 20 y correo Inter Medium 13. Abajo un Marcador con estadísticas del socio" · acceptance: `FichaSocio` muestra el rótulo «FICHA DE SOCIO», el isotipo, las iniciales sobre `accentBase`, el nombre y el correo, y un `Marcador` con las celdas que recibe
- S5 · "Linea-Del-Dia … Cabecera «TU DÍA EN LA CANCHA» … leyenda (Libre, Ocupado, Elegido). Fila de 15 cuadrados 18×18 radio 4 (08 a 22 h, gap 3) y marcas 08/12/16/20/23" · acceptance: `LineaDelDia` dibuja una celda por hora desde las 8 con el color de su estado (libre, ocupada, elegida), la leyenda de los tres estados y las marcas horarias; el lector lee cada celda como «<hora> h <estado>»
- S6 · "Card-Sede … dorsal gigante con el número de canchas (Archivo Black 92 sólo trazo `text/on-media` @0.45)" y "Ficha-Socio … Dorsal gigante «10» Archivo Black 170 ls −4 sólo con trazo `accent/base` @0.28" · acceptance: `DorsalGigante` dibuja el texto sólo con trazo, del color y el tamaño que recibe, y el lector no lo lee
- S7 · "**troquel**: línea punteada `border/control` 1.5 con dos muescas circulares de 16 del color de fondo a los lados" · acceptance: `Troquel` dibuja la línea punteada en `borderControl` y dos muescas de 16 del color de fondo que recibe, una en cada borde, y el lector no lo lee
- RED-02-ASM-01 · los componentes viven en `lib/comun/` y reciben las fotos por parámetro (`ImageProvider`): `comun` sólo importa `api` y `tema` (regla congelada de la revisión de arquitectura), así que no leen `sedes/fotos.dart` · S3,S4
- RED-02-ASM-02 · la Línea del día pinta las horas libres en `accentMuted`, las ocupadas en `stateDisabled` y la elegida en `accentBase` (el violeta de la captura horarios-grilla.png), no en lima: el lima sobre `bgSurface` claro no se ve · S5
- RED-02-ASM-03 · el isotipo se dibuja con un `CustomPainter` que aproxima el escudo, la pelota y el punto del Figma; no se exporta el vector · S1

## Tasks

- T1 · S1,RED-02-ASM-03 · apps/mobile/lib/comun/isotipo.dart (presentation) · tests: apps/mobile/test/rediseno/componentes_test.dart "el isotipo se dibuja en su tamaño con el acento y se anuncia como el club @RED-02-S1"; apps/mobile/test/rediseno/componentes_test.dart "el isotipo es un CustomPainter con el trazo del acento @RED-02-ASM-03"
- T2 · S2 · apps/mobile/lib/comun/marcador.dart (presentation) · tests: apps/mobile/test/rediseno/componentes_test.dart "el marcador muestra cada celda con su cifra y su rótulo y destaca la elegida @RED-02-S2"; apps/mobile/test/rediseno/componentes_test.dart "el lector lee cada celda del marcador como cifra y rótulo @RED-02-S2"
- T3 · S3,RED-02-ASM-01 · apps/mobile/lib/comun/tile_deporte.dart (presentation) · tests: apps/mobile/test/rediseno/componentes_test.dart "el tile de deporte muestra la foto, el emoji y el nombre y llama al tocarlo @RED-02-S3"; apps/mobile/test/rediseno/componentes_test.dart "el tile elegido lleva el borde del acento y la etiqueta ELEGIDO @RED-02-S3"; apps/mobile/test/rediseno/componentes_test.dart "los componentes de comun reciben la foto por parámetro y no importan sedes @RED-02-ASM-01"
- T4 · S4 · apps/mobile/lib/comun/ficha_socio.dart (presentation) · tests: apps/mobile/test/rediseno/componentes_test.dart "la ficha de socio muestra rótulo, isotipo, iniciales, nombre, correo y su marcador @RED-02-S4"
- T5 · S5,RED-02-ASM-02 · apps/mobile/lib/comun/linea_del_dia.dart (presentation) · tests: apps/mobile/test/rediseno/componentes_test.dart "la línea del día pinta una celda por hora con el color de su estado @RED-02-S5"; apps/mobile/test/rediseno/componentes_test.dart "el lector lee cada hora de la línea del día con su estado @RED-02-S5"; apps/mobile/test/rediseno/componentes_test.dart "libre es accentMuted, ocupado stateDisabled y elegido accentBase @RED-02-ASM-02"
- T6 · S6,S7 · apps/mobile/lib/comun/dorsal.dart (presentation), apps/mobile/lib/comun/troquel.dart (presentation) · tests: apps/mobile/test/rediseno/componentes_test.dart "el dorsal se dibuja sólo con trazo y el lector no lo lee @RED-02-S6"; apps/mobile/test/rediseno/componentes_test.dart "el troquel dibuja la línea punteada y las dos muescas y el lector no lo lee @RED-02-S7"

## Changes to existing behavior

- none: la card sólo agrega componentes en `lib/comun/`; las pantallas los usan desde RED-03

## Look

- ref: specs/RED-02-componentes-identidad/ref/figma-spec.md · specs/RED-02-componentes-identidad/ref/home-llegada.png · specs/RED-02-componentes-identidad/ref/perfil.png · specs/RED-02-componentes-identidad/ref/mis-reservas-proximas.png · specs/RED-02-componentes-identidad/ref/horarios-grilla.png
- behavior: press · el tile de deporte responde al toque con el estado presionado
- tokens: los de `Paleta` (RED-01) y `Medidas`; Archivo Black para cifras y dorsales, Inter para rótulos, JetBrains Mono para marcas horarias

## Gate

```
suite: sh D:/Temp/w/herramientas/flutter-mobile.sh
lint: D:/projects/flutter/bin/dart format --output=none --set-exit-if-changed apps/mobile/lib/comun/isotipo.dart apps/mobile/lib/comun/marcador.dart apps/mobile/lib/comun/tile_deporte.dart apps/mobile/lib/comun/ficha_socio.dart apps/mobile/lib/comun/linea_del_dia.dart apps/mobile/lib/comun/dorsal.dart apps/mobile/lib/comun/troquel.dart apps/mobile/test/rediseno/componentes_test.dart && D:/projects/flutter/bin/flutter analyze --no-pub apps/mobile
```

## Log

- L1 · con este dise;o actualicemos la app real (el diseño es el rediseño «Camiseta del club» del Figma https://www.figma.com/design/zCsUSxyy2QjwEJ7AyR6XWt; esta card toma los componentes de identidad —Isotipo, Marcador, Tile-Deporte, Ficha de socio, Línea del día, dorsal gigante y troquel— como piezas de `lib/comun/`; las pantallas los usan en RED-03 y el movimiento va en RED-04)
- L2 · 2026-10-24 · declared · S2 · los textos entre comillas que risk.mjs cuenta como miembros son de otras specs; los miembros de S2 son sus celdas, y un mismo test recorre las tres (cifra, rótulo y la destacada) y otro la lectura de cada una
- L3 · 2026-10-24 · declared · S5 · los textos entre comillas que risk.mjs cuenta como miembros son de otras specs; las 15 horas de S5 las recorre un mismo test por estado y otro la lectura de cada hora
- L4 · 2026-10-24 · declared · S7 · los textos entre comillas que risk.mjs cuenta como miembros son de otras specs; las dos muescas de S7 las verifica el mismo test que la línea
- L5 · 2026-10-22 · replaces: apps/mobile/test/interfaz_accesible_test.dart "con un dato completado sólo se marca lo que falta, y escribirlo borra su error @REV-04-S1 @assumption:REV-04-ASM-01" · monta PantallaRegistro sin GoRouter y el alta exitosa llama context.go · by: apps/mobile/test/interfaz_accesible_registro_reemplazo_test.dart "con un dato completado sólo se marca lo que falta, y escribirlo borra su error @REV-04-S1 @assumption:REV-04-ASM-01" · (copiada de REV-04-interfaz-accesibilidad) · (copiada de INT-01: la compuerta sólo lee el Log de la card en curso)
- L6 · 2026-10-23 · replaces: apps/mobile/test/operacion_cliente_limite_test.dart "el límite por defecto se agota justo a los 60 s, no un segundo después @REV-02-S8 @assumption:REV-02-ASM-06" · pide rutas de prueba (/lento, /a, /b, /rapido) y REV-08 hace fallar en debug toda ruta que la app no declara · by: apps/mobile/test/operacion_cliente_sin_verificar_rutas_test.dart "el límite por defecto se agota justo a los 60 s, no un segundo después @REV-02-S8 @assumption:REV-02-ASM-06 @INT-01-ASM-01" · (copiada de INT-01: la compuerta sólo lee el Log de la card en curso)
- L7 · 2026-10-23 · replaces: apps/mobile/test/operacion_cliente_test.dart "el límite por defecto es de 60 s y se agota con ServidorSinRespuesta @REV-02-S8 @assumption:REV-02-ASM-06" · pide rutas de prueba (/lento, /a, /b, /rapido) y REV-08 hace fallar en debug toda ruta que la app no declara · by: apps/mobile/test/operacion_cliente_sin_verificar_rutas_test.dart "el límite por defecto es de 60 s y se agota con ServidorSinRespuesta @REV-02-S8 @assumption:REV-02-ASM-06 @INT-01-ASM-01" · (copiada de INT-01: la compuerta sólo lee el Log de la card en curso)
- L8 · 2026-10-23 · replaces: apps/mobile/test/operacion_cliente_test.dart "despertando se enciende pasados 5 s y se apaga al terminar el pedido @REV-02-S8 @assumption:REV-02-ASM-11" · pide rutas de prueba (/lento, /a, /b, /rapido) y REV-08 hace fallar en debug toda ruta que la app no declara · by: apps/mobile/test/operacion_cliente_sin_verificar_rutas_test.dart "despertando se enciende pasados 5 s y se apaga al terminar el pedido @REV-02-S8 @assumption:REV-02-ASM-11 @INT-01-ASM-01" · (copiada de INT-01: la compuerta sólo lee el Log de la card en curso)
- L9 · 2026-10-23 · replaces: apps/mobile/test/operacion_cliente_test.dart "despertando sigue encendido mientras quede un pedido lento @REV-02-S8 @assumption:REV-02-ASM-11" · pide rutas de prueba (/lento, /a, /b, /rapido) y REV-08 hace fallar en debug toda ruta que la app no declara · by: apps/mobile/test/operacion_cliente_sin_verificar_rutas_test.dart "despertando sigue encendido mientras quede un pedido lento @REV-02-S8 @assumption:REV-02-ASM-11 @INT-01-ASM-01" · (copiada de INT-01: la compuerta sólo lee el Log de la card en curso)
- L10 · 2026-10-23 · replaces: apps/mobile/test/operacion_cliente_test.dart "un pedido rápido no cuenta como lento para despertando @REV-02-S8 @assumption:REV-02-ASM-11" · pide rutas de prueba (/lento, /a, /b, /rapido) y REV-08 hace fallar en debug toda ruta que la app no declara · by: apps/mobile/test/operacion_cliente_sin_verificar_rutas_test.dart "un pedido rápido no cuenta como lento para despertando @REV-02-S8 @assumption:REV-02-ASM-11 @INT-01-ASM-01" · (copiada de INT-01: la compuerta sólo lee el Log de la card en curso)
- L11 · 2026-10-24 · closing: publicación sin correr — la rama, el PR y el comentario de cierre no se publican sin un pedido expreso (CLAUDE.md del repo); la card se integra a main en local
