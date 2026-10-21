# Plan — REV-04 · interfaz y accesibilidad

## Time plan

1. Size and risk: unos 16 archivos de la app (componentes comunes, dos formularios, dos confirmaciones, el alta de espacio, el reloj del club, los avisos) más las capturas · riesgo: bajo en datos; alto en regresiones visuales (85 vistas con capturas)
2. without method: 120–180–300 min · goal: 900 min · cap: 14 h
3. Critical path: tests en rojo → plan → implementer grupo 1 (comunes y reloj) → grupo 2 (formularios) → grupo 3 (confirmaciones y avisos) → grupo 4 (capturas) → verify → juicio y capturas · on the side from the start: `flutter pub get` (hecho)
4. Split: plan 60 · code 240 · verification 300 · correction 300 min
5. Cut if it does not fit: unificar la zona del club fuera de `reloj.dart` (hallazgo 28, de REV-06); nunca un chequeo de la vara

## Verification

```
suite: cd apps/mobile && flutter test
lint: cd apps/mobile && flutter analyze && dart format --output=none --set-exit-if-changed lib test/interfaz_accesible_test.dart
scenarios: cd apps/mobile && flutter test test/interfaz_accesible_test.dart
captures: cd apps/mobile && flutter test test/capturas/registro_capturas.dart test/capturas/admin_capturas.dart test/capturas/espacios_capturas.dart test/capturas/reservas_capturas.dart test/capturas/notificaciones_capturas.dart
stable: node .claude/tools/repeat.mjs 3 -- sh -c "cd apps/mobile && flutter test test/interfaz_accesible_test.dart"
```

La app es Flutter: `mutate.mjs` no trae mutador de Dart, así que las líneas `mutate` no van; la mutación queda «no se pudo correr» con ese motivo. Los e2e en el emulador Android corren con `sh /d/Temp/e2e-archivos.sh /d/Temp/w/rev04 rev04 integration_test/<archivo>.dart` si `adb devices` lo muestra; si no, «no se pudo correr».

## File map

Grupo 1 · componentes comunes y reloj
- apps/mobile/lib/comun/reloj.dart — nuevo: `ahoraEnElClub()` a partir de `clock.now()` con la diferencia fija del club; un solo lugar para «ahora» · rule · test: apps/mobile/test/interfaz_accesible_test.dart
- apps/mobile/lib/comun/calendario.dart — el calendario de nacimiento termina el día anterior al de `ahoraEnElClub()`
- apps/mobile/lib/comun/campo_texto.dart — el error y el formato (`ayuda`/placeholder) entran en la semántica del campo: un solo nodo con etiqueta, valor, formato y error
- apps/mobile/lib/comun/selector.dart — el error entra en la semántica del selector, igual que el campo
- apps/mobile/lib/comun/boton.dart — el `atenuado` mantiene el aspecto apagado con texto de contraste ≥ 4,5:1 en los dos temas
- apps/mobile/lib/comun/dialogo_error.dart — `autofocus` en la opción que no destruye de cada confirmación irreversible; el aviso de rechazo de reserva (texto del servidor + ELEGIR OTRO HORARIO), sin cierre automático
- apps/mobile/lib/comun/barra_inferior.dart — las etiquetas se achican para entrar enteras cuando el texto crece (nunca se cortan), con margen al borde · presentation

Grupo 2 · formularios
- apps/mobile/lib/usuarios/pantalla_registro.dart — CREAR CUENTA siempre tocable; al tocarlo con faltantes muestra el error de cada uno y lleva el foco al primero; antes del primer intento, salir de un campo vacío no muestra error; «hoy» sale de `ahoraEnElClub()` si no viene de afuera
- apps/mobile/lib/admin/pantalla_formulario_sede.dart — la edición se comporta como el alta: GUARDAR CAMBIOS tocable, muestra qué falta y no envía
- apps/mobile/lib/admin/pantalla_alta_espacio.dart — nada se desborda a 320 × 568 · presentation

Grupo 3 · confirmaciones y avisos
- apps/mobile/lib/reservas/pantalla_confirmar_reserva.dart — el rechazo (422) abre el aviso de rechazo; al cerrarlo vuelve a los horarios como hoy
- apps/mobile/lib/reservas/pantalla_confirmar_cambio.dart — lo mismo para el cambio
- apps/mobile/lib/reservas/reglas_busqueda.dart — usa `ahoraEnElClub()` de `reloj.dart`
- apps/mobile/lib/notificaciones/panel_avisos.dart, apps/mobile/lib/notificaciones/pantalla_notificaciones.dart — el `ahora` por defecto es `ahoraEnElClub()`
- apps/mobile/pubspec.yaml — `clock` como dependencia directa (ya estaba en el lock, de dart.dev)

Grupo 4 · capturas
- apps/mobile/test/capturas/*_capturas.dart — corren con un reloj fijo (`withClock`, 12 de noviembre de 2026 a las 15:00 del club); el alta de espacio suma 320 × 568
- apps/mobile/test/capturas/**/*.png — se regeneran sólo las que cambian por esta card, y se miran

Tests
- apps/mobile/test/interfaz_accesible_test.dart — los escenarios REV-04 (rojo, del hilo principal)

- System design: unchanged — sólo presentación
- ADR: unchanged — no cambia la arquitectura

## Assumptions

- REV-04-ASM-01 · los faltantes se muestran al tocar el botón de enviar, cada uno debajo de su campo, y el foco va al primero; después se actualizan mientras la persona escribe; antes del primer intento, salir de un campo vacío no muestra nada · any-answer: yes
- REV-04-ASM-02 · el rechazo de una reserva o de un cambio se muestra en un aviso que no se cierra solo, con el texto del club y el botón ELEGIR OTRO HORARIO, que vuelve a los horarios · any-answer: yes
- REV-04-ASM-03 · en cada confirmación irreversible el foco empieza en la opción que no destruye; el orden de los botones no cambia · any-answer: yes
- REV-04-ASM-04 · la edición de sede deja GUARDAR CAMBIOS tocable y muestra qué falta, igual que el alta · any-answer: no — deja sin efecto «Guardar cambios se deshabilita» de CU-18 FA2
- REV-04-ASM-05 · con el texto grande, las etiquetas de la barra se achican hasta entrar enteras; los íconos y el alto no cambian · any-answer: yes
- REV-04-ASM-06 · fechas y precios siguen con el formato del club (es-AR, pesos con punto de miles) y la diferencia fija de −3 h, que es la de Argentina sin horario de verano; prepararlos para otras zonas o monedas no se hace · any-answer: no — deja sin efecto «sin zona IANA, sin `DateFormat` con locale ni ISO 4217»
- REV-04-ASM-07 · el botón atenuado sigue viéndose apagado, con su texto en un color que llega a 4,5:1 · any-answer: yes
- REV-04-ASM-08 · el calendario de nacimiento termina el día anterior al día del club · any-answer: yes
- REV-04-ASM-09 · las capturas corren con el reloj fijo en el 12 de noviembre de 2026 a las 15:00 del club, la semana que usan los datos de prueba · any-answer: yes

## Perimeter

Widget tests con la API falsa de `test/soporte/` y capturas golden; el lector de pantalla real (TalkBack) y los e2e en el emulador Android quedan «no se pudo correr» si el emulador no está. Fuera: mover la llamada HTTP de `PantallaRegistro` (REV-06), la zona repetida en diez lugares (REV-06, salvo los que pasan por `reloj.dart`), el catálogo con Básquet (REV-05).

## Bar

- R1 · los escenarios montan las pantallas reales con su router; el recorrido en el teléfono, si el emulador está
- R2 · diez preguntas y AMB-01 a AMB-08
- R3 · cada ASM dice si sirve con cualquier respuesta
- R4 · no applicable · ningún ASM cambia lo que opera quien despliega; ASM-04 y ASM-06 van al cierre
- R5 · preguntas en lenguaje del club
- R6 · un test con tag por escenario
- R7 · cada hunk corresponde a los hallazgos 17, 18 o 27
- R8 · lo ajeno visto va como `REV-04-OUT-NN`
- R9 · no applicable · sin requisitos de rendimiento nuevos
- R10 · no applicable · sin seguridad
- D1 · `reloj.dart` con una sola responsabilidad
- D2 · `comun` no importa pantallas; la app no tiene test de imports (REV-06)
- D3 · sin ciclos nuevos: `reloj.dart` no importa nada de la app
- D4 · el aviso de rechazo y la semántica del campo quedan en los componentes comunes
- D5 · «ahora en el club» en un solo lugar
- D6 · nada genérico de más
- D7 · se reusan `_Modal`, `CampoTexto` y `BotonPrimario`
- D8 · no applicable · sin dependencias externas
- D9 · no applicable · sin superficie nueva
- D10 · no applicable
- D11 · no applicable · sin datos
- D12 · `ahoraEnElClub` tipado
- D13 · las pantallas usan los componentes por su constructor
- D14 · no applicable · no cambia la arquitectura
- D15 · `clock` es de dart.dev y sólo lo usa `reloj.dart`
- K1 · `flutter analyze` limpio, sin `// ignore:` nuevos
- K2 · analyze; Sonar «no se pudo correr»
- K3 · funciones cortas
- K4 · el comportamiento de los formularios se comparte, no se copia
- K5 · sin código muerto: el SnackBar de rechazo se va
- K6 · nombres del dominio
- K7 · comentarios sólo para el porqué
- K8 · no applicable · la validación del servidor no cambia
- K9 · no applicable
- K10 · no applicable
- K11 · convenciones del repo
- E1–E5 · not applicable · la card no escribe datos
- E6 · el rechazo se muestra; nada se traga
- E7–E15 · not applicable · sin errores nuevos de servidor ni colas
- E16 · el aviso de rechazo dice qué pasó (texto del club) y qué hacer (ELEGIR OTRO HORARIO); lo escrito en los formularios se conserva
- T1 · rojo antes del código
- T2 · ningún test se ablanda; las capturas que cambian se miran una por una
- T3 · no se pudo correr · `mutate.mjs` no tiene mutador de Dart
- T4 · cada test afirma lo que ve o anuncia la persona
- T5 · por comportamiento: texto, semántica, foco, contraste
- T6 · sin lógica en los tests salvo el recorrido de los seis mensajes
- T7 · cada test monta su pantalla
- T8 · los nuevos tres veces (`stable:`)
- T9 · `reloj.dart` con un test sin pantalla
- T10 · cada borde con su test
- T11 · `flutter test --coverage` si alcanza el tiempo; si no, «no se pudo correr»
- T12 · por texto y etiqueta accesible
- T13 · `reloj.dart` marcado `rule`
- T14 · no applicable
- S1–S24 · not applicable · la card no toca seguridad ni dependencias salvo `clock`, de dart.dev (S10: ya estaba en el lock)
- P1–P16 · not applicable · la card no toca datos
- O1–O29 · not applicable · la card no cambia operación
- I1 · el atenuado llega a 4,5:1; `textContrastGuideline` en las pantallas tocadas, los dos temas
- I2 · no applicable · sin imágenes nuevas
- I3 · cada campo sigue con etiqueta
- I4 · no hay botones vacíos
- I5 · no applicable · la app declara es-AR en `MaterialApp`
- I6 · foco lógico; el primer foco en las confirmaciones es la opción que no destruye
- I7 · error y formato atados al campo en la semántica
- I8 · los objetivos táctiles no cambian; `androidTapTargetGuideline` en las tocadas
- I9 · a 320 de ancho y con el texto al 200 % no se corta nada en la barra ni en el alta de espacio
- I10 · tras el rechazo, la pantalla vuelve a los horarios como estaba
- I11 · no applicable · sin pantallas nuevas
- I12 · los textos nuevos son los del club
- I13 · capturas a 320, 360 y 430
- I14 · TalkBack «no se pudo correr» sin emulador
- I15 · no applicable · sin pantallas nuevas
- I16 · los diálogos siguen el patrón de diálogo modal (foco inicial, sin cierre solo)
- I17 · no applicable · la declaración la escribe REV-07
- I18 · un botón principal por vista
- I19 · el aviso de rechazo no abre otro modal
- I20 · el rechazo deja de ser un toast: queda hasta que la persona lo cierra
- I21 · no applicable · sin interruptores
- I22 · la validación corre al intentar enviar, nunca al salir de un campo vacío
- I23 · no applicable · sin cargas nuevas
- I24 · las confirmaciones irreversibles siguen con diálogo; las reversibles no cambian
- I25 · no applicable · sin animaciones en bucle
- I26 · ASM-06: el formato es explícito y único (es-AR, −3 h); «ahora» sale de un solo lugar
- C1 · las pantallas reales en el teléfono, si el emulador está
- C2 · no applicable
- C3 · la suite de la app sigue verde; las capturas que cambian, revisadas
- C4 · no applicable · la app no cambia lo que manda a la API
- A1 · cada «pasó» con su comando
- A2 · el cierre nombra sólo lo del diff
- A3 · AMB registradas, sin canal → ASM
- A4 · hooks y `verify.mjs`
- A5 · diff proporcional a tres hallazgos de interfaz
- A6 · cableado: los componentes comunes llegan a todas sus pantallas
- A7 · el juicio visual no reemplaza las guías medidas
- A8 · no applicable
- A9 · ningún test se apaga
- V1 · snapshot en 2025557
- V2 · este plan antes del código
- V3 · commits con qué y por qué
- V4 · registro de la sesión
- V5 · evidencia de accesibilidad por criterio en el cierre (guías, foco, semántica, 200 %)
- V6 · el cierre sale de las validaciones
- V7 · una persona aprueba antes de integrar
- W5 · no applicable
- W8 · no applicable · sin API
- W9 · no applicable
- ci · off by decision · not chosen at install: no signal found in the repo
- docs · off by decision · not chosen at install: no signal found in the repo
- i18n · off by decision · not chosen at install: no signal found in the repo

## Edges

- Defense against legitimate data · los nombres largos de espacio (`Moron_Rivadavia_19850_Futbol_F5_1`) entran a 320
- State after the action · lo escrito en el formulario queda al mostrar los faltantes; tras el rechazo, la grilla vuelta a leer
- Honest notices · el rechazo dice el motivo del club
- What does not exist · no applicable
- Writes · no applicable
- Origin of the request · no applicable
- What travels to another program · el lector de pantalla recibe un solo nodo por campo
- Restart · no applicable
- What no test notices · el recorrido real con TalkBack: «no se pudo correr» sin emulador

## Changes to existing behavior

- README: unchanged — la card no cambia cómo se instala ni se opera
- ASVS: unchanged — sin seguridad
- CREAR CUENTA y GUARDAR CAMBIOS (sede) dejan de estar deshabilitados: muestran qué falta
- Salir de un campo vacío deja de mostrar un error antes del primer intento
- El rechazo de una reserva o de un cambio pasa de SnackBar a un aviso que se cierra con ELEGIR OTRO HORARIO
- Las confirmaciones irreversibles abren con el foco en la opción que no destruye
- El calendario de nacimiento y «ahora» toman el día del club
- Las capturas corren con reloj fijo y suman 320 × 568 en el alta de espacio
- Lo demás queda igual

## Visual brief

- Componentes: `CampoTexto`, `Selector`, `BotonPrimario`, `_Modal` de `dialogo_error.dart`, `BarraInferior`/`BarraAdmin`; nada nuevo fuera del aviso de rechazo, que es un `_Modal` más.
- Estados que cambian: formulario con faltantes tras tocar enviar (error rojo bajo cada campo, foco en el primero); aviso de rechazo abierto (ícono de alerta, texto del club, ELEGIR OTRO HORARIO); confirmación con foco visible en la opción que no destruye.
- El botón atenuado conserva el fondo apagado; cambia sólo el color del texto.
- La barra a texto grande: etiquetas achicadas, mismo alto, íconos iguales.
- Sin animaciones nuevas.
