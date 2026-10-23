# Inspección — REV-05 · Básquet en el catálogo

Rango: `b7d7c30~1..HEAD` (código en 15beb3f, rojo en 8f752a4). API levantada aparte por el inspector
(uvicorn en `127.0.0.1:57107`, base propia `club_rev05_inspector_test`, emulador de Auth en 9099), como cliente
plano: sin `Origin` ni `Host` especial. Script y salida: `.validation/inspector/f1.py`, `.validation/inspector/f1.log`.
La API y la base se bajaron al terminar.

## F1 — lo que pidió la card

| Escenario | Estado | Evidencia |
|---|---|---|
| REV-05-H19-01 · el catálogo ofrece Básquet con su tipo de cancha | meets | `GET /espacios/catalogo` con token de socio → 200; orden Futbol, Tenis, Padel, Voley, **Basquet**, Hockey, Golf; Básquet con `B5` «Básquet 5» y `3X3` «Básquet 3x3». Sin token → 401 «Sesión inválida o vencida» (como el resto). |
| REV-05-H19-02 · el administrador da de alta una cancha de Básquet | meets | `POST /espacios` admin: `Basquet/B5` → 201 `…_Rivadavia_19850_Basquet_B5_1`; `Basquet/3X3` → 201 `…_Basquet_3X3_1`; segundo B5 → `…_B5_2` (numeración por tipo intacta); `Basquet/F5` → 422 `{"tipo": "Elegí un tipo de la lista"}`; `Básquet` con tilde o `basquet` → 422 «Elegí un deporte de la lista». |
| REV-05-H19-03 · el socio filtra los espacios por Básquet | meets | `GET /espacios?sede_id=1&deporte=Basquet` → 200 con las 3 canchas de Básquet y sin la de Fútbol; `&tipo=3X3` → sólo la 3X3; sin `sede_id` → las 3. |
| REV-05-H19-04 · la app muestra Básquet con su ícono y su foto | not verified en la app corriendo | La app es Flutter sin destino web en este entorno: no hay pantalla que manejar con `app.mjs probe`. Leído: `iconos.dart:8` da `sports_basketball_rounded` y lo usan el chip del filtro (`pantalla_sede.dart:311`), el Home (`pantalla_inicio.dart:476`) y los listados; `fotos.dart:15` da `portada_1.jpg` a las tarjetas de cancha, horarios y reservas. **La foto `portada_1.jpg` es una cancha de fútbol vista desde arriba** (arcos, áreas, círculo central): ver K6. Lo que se ve en pantalla queda para el juez visual. |
| Pedido del coordinador: «Corregir el hallazgo 19 … dominio/espacios.py, iconos y fotos de la app» | meets | Los tres archivos cambian; el catálogo de la API ya no deja afuera Básquet (F1 H19-01). |

**Lo que no pidió la card:**
- `.claude/kit.json`: confirma i18n apagado para esta card (`confirmed`, 2026-10-21). Lo escribe `kit.mjs`; es metadato del kit, no producto. Es un extra, no un defecto.
- `apps/api/README.md`: la sección «Catálogo de deportes» la pide R4 (grado production): no es un extra.
- Nada más: cada hunk de producción está en el File map.

## Criterios

| ID | Estado | Evidencia |
|---|---|---|
| R2 | meets | `ambiguities.md`: las diez preguntas con tres huecos (tipos, orden, foto) → AMB-01..03, cada una con su pregunta en lenguaje del club. |
| R3 | meets | `plan.md` `## Assumptions`: ASM-01..03 con `any-answer: yes`; las tres son reversibles (dos tipos de más no molestan si el club tiene uno; el orden y la portada se cambian en una línea). |
| R4 | meets | `apps/api/README.md:921-929`: una línea `- REV-05-ASM-NN: …` por suposición. El texto de ASM-02 («la portada 1 … que no es de ningún otro deporte») es cierto en el mapeo pero no dice que la foto es de fútbol: ver K6. |
| R7 | meets | Hunks de producción: `espacios.py` (+1), `iconos.dart` (+1), `fotos.dart` (+1), README (+10), todos en el File map; tests nuevos y `montar.dart` (+1) también. `kit.json` es metadato del kit (ver F1). |
| R8 | fails L | El plan (`## Bar` D5) ve que las claves de deporte se repiten en la API, `iconos.dart` y `fotos.dart` y dice «unificarlo es de REV-06», pero no hay ningún `REV-05-OUT-NN` ni `REV-06` registrado en el repo (`grep -rn REV-06 specs/` sólo da el plan). Se propone acá como REV-05-OUT-02. `## Changes to existing behavior` sí declara lo que cambia. |
| D1 | meets | El deporte nuevo vive en `CATALOGO` del dominio (`espacios.py:104`), el ícono en `espacios/iconos.dart`, la foto en `sedes/fotos.dart`: cada uno donde ya estaba su responsabilidad. |
| D4 | meets | Sin funciones nuevas; se extienden una tupla y dos `switch`. |
| D5 | see R8 | La card suma una clave más a una repetición que ya existía (API `CATALOGO`, `iconoDeDeporte`, `fotoDeDeporte`); no crea una repetición nueva. Lo preexistente va como REV-05-OUT-02. |
| K6 | fails M | El test `apps/mobile/test/basquet_test.dart:13` se llama «la foto de Básquet no es la de una cancha de fútbol», y afirma `fotoDeDeporte('Basquet') == portada_1.jpg`; `apps/mobile/assets/imagenes/sedes/portada_1.jpg` es una cancha de fútbol vista desde arriba (arcos, áreas, círculo central, como `portada_4.jpg`, la de Fútbol). El nombre afirma lo contrario de lo que se ve; quien revisa el PR lee que Básquet no muestra una cancha de fútbol, y la muestra en la tarjeta de la cancha, horarios, confirmar reserva y mis reservas. ACT-?? abajo. |
| K7 | meets | Sin comentarios nuevos en producción; los docstrings de los tests dicen el escenario. |
| K9 | not applicable | El diff no abre archivos, conexiones ni timers (un elemento de tupla, dos ramas de `switch`). |
| K10 | not applicable | Sin bucles ni consultas nuevas; el filtro usa la consulta existente de `GET /espacios`. |
| K11 | meets | Mismo formato de `Deporte(clave, nombre, (Tipo…))`, clave sin tilde como las demás (`Voley`, `Padel`); ramas `switch` como las existentes; tests en `tests/escenarios/` con tags `@REV-05-H19-NN`. |
| T5 | meets | Los tests de la API afirman por HTTP lo que ve el socio o el admin (catálogo, 201/422, nombre generado, filtro); los de la app afirman el ícono y la foto que devuelven las funciones públicas, no su forma interna. |
| T9 | meets | Las reglas (tipo de Básquet válido, tipo ajeno rechazado, filtro) se prueban con pytest contra la API, sin navegador (`tests/escenarios/test_basquet.py`). |
| I12 | meets | Textos nuevos: «Básquet», «Básquet 5», «Básquet 3x3»; `Catalogo.tipoLegible`/`tipoCorto` (`espacio.dart:25-41`) los muestran como «Básquet 5» porque el tipo empieza con el deporte. Etiqueta accesible del chip: «Deporte Básquet» (`pantalla_sede.dart:461`). |
| I17 | fails L (preexistente) | No hay declaración de accesibilidad en el repo (`grep -rli "declaración de accesibilidad"` fuera de `.claude/` sólo da `specs/REVISION-kit3.md:214`, que la lista como faltante, hallazgo 21). La card no la tocó: REV-05-OUT-01, sin ACT. |
| A3 | meets | Las tres dudas quedaron como AMB-01..03 → ASM-01..03 (sin canal: no hay Jira), etiquetadas en los tests (`@assumption:REV-05-ASM-01..03`). |
| A8 | not applicable | El código no llama a ningún modelo. |
| V5 | meets | `accessibility.md` de esta card, criterio por criterio para lo que el diff toca de pantalla (chip con ícono, foto bajo velo). |
| V6 | not verified | El comentario de cierre no existe todavía (el cierre no corrió; no hay Jira y publicar queda «no se pudo correr»). |
| V7 | meets | `card.snapshot.md` en `status: proposed`; la rama `card/REV-05` no se mergeó ni se pusheó (`git log --oneline b7d7c30~1..HEAD` sólo en la rama). |

**Cuenta:** meets 15 · fails H 0 · fails M 1 (K6) · fails L 2 (R8; I17 preexistente, OUT) · not applicable 3 (K9, K10, A8) · not verified 1 (V6) · see 1 (D5).

## Acciones

ACT-?? · K6 · M · `apps/mobile/test/basquet_test.dart:13` se llama «la foto de Básquet no es la de una cancha de fútbol» y fija `portada_1.jpg`, que es una cancha de fútbol vista desde arriba (abrir `apps/mobile/assets/imagenes/sedes/portada_1.jpg` y compararla con `portada_4.jpg`, la de Fútbol); el README (REV-05-ASM-02) tampoco dice que la foto provisoria es de fútbol · close: el nombre del test y la línea REV-05-ASM-02 del README dicen lo que la foto de Básquet muestra de verdad, o la foto de Básquet deja de ser una cancha de fútbol, y `flutter test test/basquet_test.dart` pasa · suspect
ACT-?? · R8 · L · el plan (`## Bar`, D5) deja «unificar las claves de deporte de la app es de REV-06» sin registrarlo: `grep -rn "REV-06\|REV-05-OUT" specs/` no da ningún registro fuera del plan · close: `grep -n "REV-05-OUT-02" specs/REV-05-basquet-en-el-catalogo/*.md` encuentra la propuesta registrada · open

## Fuera de la card (OUT)

- REV-05-OUT-01 · L · No hay declaración de accesibilidad en el repo (I17); ya figura en `specs/REVISION-kit3.md` hallazgo 21.
- REV-05-OUT-02 · L · Las claves de deporte se repiten a mano en `apps/api/app/dominio/espacios.py` (`CATALOGO`), `apps/mobile/lib/espacios/iconos.dart` y `apps/mobile/lib/sedes/fotos.dart` (D5). Un deporte que se sume sólo a la API sale con el ícono genérico y con `portada_4.jpg`, la foto de Fútbol (`fotos.dart:18`, rama `_`), sin que ningún test lo note.
- REV-05-OUT-03 · L · `fotoDeDeporte` da la misma foto de fútbol a Fútbol y a Hockey y a todo deporte desconocido (`fotos.dart:18`); y `portada_1.jpg` también es portada de las sedes con `id % 4 == 0` (`fotos.dart:12`), de modo que la tarjeta de una sede y la de una cancha de Básquet pueden mostrar la misma foto.
