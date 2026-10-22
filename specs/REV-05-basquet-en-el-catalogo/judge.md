# Judge · REV-05 · plan

- ACT-01 · M · REV-05-ASM-01 nombra dos tipos (`B5`, `3X3`) pero los tests de S2 y S3 cubren «una cancha de Básquet» sin nombrar el tipo, y `attacks:` sólo usa `B5`: no hay alta con `3X3` (clave que empieza con dígito, entra en el nombre compuesto) ni filtro por variante, que CU-20 paso 3 pide («muestra solo las canchas de ese tipo») · card.md:17, card.md:23, card.md:472-479 · lenses.md interpretation «Does a quantifier name its members, and does each member have a test?» · plan · closed · T1 (alta y filtro de Básquet 3x3, REV-05-ASM-01)
- ACT-02 · L · REV-05-ASM-03 «después de Vóley» no dice si va inmediatamente después (antes de Hockey) o al final; L1 trae dos órdenes distintos: `GET /espacios/catalogo` «Futbol, Tenis, Padel, Voley, Hockey y Golf» y CU-21 «Fútbol, Tenis, Paddle, Hockey, Vóley, Golf» · card.md:19, card.md:64-65, card.md:682 · lenses.md contract «What is the order of the fields and of the list when the card does not say?» · plan · closed · declared L7
- ACT-03 · L · el test «un tipo que no es de Básquet se rechaza» no fija status ni forma del error (`Basquet` + `F5`: 400, 422 o 409; cuerpo `{error, message}`) · card.md:23 · lenses.md contract «What happens in a partial case, one valid field and one invalid?» y «What does the client see on an error: a stable shape?» · plan · closed · declared L8
- ACT-04 · L · el catálogo «vive en el código de la API y la app lo pide»: una app ya instalada recibe `Basquet` sin ícono ni foto propios; ningún test ni ASM dice qué muestra con un deporte que no conoce · card.md:73, card.md:31 · lenses.md contract «Does an existing client keep working: which route, field or status of main changes?» · plan · closed · REV-05-ASM-04, T2

## Verified

- interpretation · fails (ACT-01, ACT-02)
- contract · fails (ACT-03, ACT-04)
- security · meets · rol y credenciales de `POST /espacios` y lecturas de catálogo y filtro cubiertos por la línea `attacks:` del Gate (card.md:44); el deporte sale de un catálogo fijo, no es texto libre que llegue a header, path o HTML
