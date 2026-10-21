# Red review · REV-07 · documentación de producción

Fuente: `card.snapshot.md` (hallazgos 21, 22 y S12 del 25). Tests: `apps/api/tests/escenarios/test_documentacion.py`,
11 tests, uno por escenario, los 11 en rojo por `FileNotFoundError` o `AssertionError` (log `D:/Temp/rojo-rev07.log`, líneas 349-360).
Del plan: `## Assumptions` y `## Perimeter`.

Hechos del repo que los tests usan, comprobados:
- `.claude/templates/asvs-level-1.md` 70 requisitos, `asvs-level-2.md` 183; formato de fila `| **Vx.y.z** … | estado | evidencia |`.
- Migraciones: 9 `CREATE TABLE` (correo_saliente, dispositivo, enlace_recuperacion, espacio, notificacion, notificacion_reserva, reserva, sede, usuario).
- 28 archivos `pantalla_*.dart`; 7 `.ttf` en `apps/mobile/assets/fuentes/` (Inter, Archivo, Archivo Black, JetBrains Mono) y ningún `OFL.txt`.
- `.claude/tools/checks/security-l2.mjs` sólo pide que exista `specs/asvs.md` y diga `level 2`/`L2`; el test H21-01 es más estricto que el chequeo.

## Cobertura por escenario

| Escenario | Test | ¿Prueba contenido, no sólo existencia? | ¿Pasa con un documento falso? |
|---|---|---|---|
| H21-01 ASVS L2 | `test_la_matriz_asvs_de_nivel_2_responde_cada_requisito` | sí: las 253 filas, estado válido, evidencia no vacía | sí: todo `not applicable` con evidencia `-` |
| H21-02 diseño | `test_el_diseno_del_sistema_tiene_amenazas_…` | parcial: STRIDE, un timeout por dependencia, local/Render, la palabra SLO | sí: sin reintento ni falla por dependencia, «no hay SLO» pasa |
| H21-03 ADR | `test_las_decisiones_de_stack_y_hosting_estan_registradas` | mínimo: `## Status` y tres palabras | sí: un archivo de tres líneas |
| H21-04 licencias | `test_las_licencias_de_terceros_estan_declaradas` | parcial: nombres de dependencias directas | sí: lista de nombres sin licencia |
| H21-05 costos | `test_el_costo_de_operar_la_app_esta_calculado` | mínimo | sí: `USD 0` y un título |
| H21-06 runbook | `test_el_runbook_dice_como_volver_atras_…` | parcial: cuatro secciones no vacías | sí: «TODO» en cada sección |
| H21-07 accesibilidad | `test_la_declaracion_de_accesibilidad_…` | parcial: nombres de pantalla por subcadena | sí: faltan 4 pantallas y pasa |
| H21-08 modelo de datos | `test_el_modelo_de_datos_documenta_todas_las_tablas` | sólo nombres de tabla | sí: nueve nombres entre comillas invertidas |
| H21-09 presupuesto | `test_el_presupuesto_de_rendimiento_y_capacidad_esta_escrito` | mínimo | sí: «capacidad» en cualquier lugar |
| H22-01 README | `test_quien_opera_la_app_encuentra_los_supuestos_en_los_readme` | parcial | sí: IDs inventados |
| H25-01 MPL/LGPL/OFL | `test_las_licencias_mpl_lgpl_y_ofl_…` | parcial: títulos y una cadena | sí: títulos vacíos, sin la excepción escrita |

Entradas con forma (faltante, null, tipo erróneo) y redondeo al centavo: no aplican, no hay código de producción ni cálculo de dinero que testear. La card no afirma ninguna ausencia, así que no hace falta `count()` después de una señal positiva.

## Hallazgos

ACT-?? · F1 · M · H21-02: el test sólo exige un número con `s` en la fila de cada dependencia; la card pide «dependencias con timeout y reintento» y la barra D8 pide además el comportamiento ante la falla. Un `system-design.md` con `| PostgreSQL | 5 s |` y nada más pasa; tampoco se exige STRIDE por superficie (D9): basta la palabra `STRIDE` en `## Threat model`; y `\bSLO\b` en cualquier lugar acepta «No hay SLO». Reproducir: crear el documento con esas tres líneas y correr `pytest tests/escenarios/test_documentacion.py -k diseno` · close: con un documento sin reintento o sin falla en alguna de las cuatro dependencias, o sin las seis categorías STRIDE, o sin un valor de SLO, el test falla · open

ACT-?? · F1 · M · H21-08: el test sólo verifica que cada nombre de tabla aparezca entre comillas invertidas en `## Data`. El hallazgo dice que el modelo «cubre 4 de 9 tablas»; el enunciado pide «entidades, atributos y relaciones» y REV-07-ASM-03 promete columnas, claves, índices y triggers. Un `## Data` con «`usuario` `sede` … `correo_saliente`» en una línea pasa · close: con un modelo que omite una columna o una clave foránea de las migraciones, el test falla · open

ACT-?? · F1 · M · H21-07: `p not in declaracion` compara por subcadena; `pantalla_inicio`, `pantalla_registro`, `pantalla_sede` y `pantalla_sedes` quedan cubiertas por `pantalla_inicio_sesion`, `pantalla_registro_exitoso`, `pantalla_sede_creada` y `pantalla_sedes_admin`. Una declaración sin esas 4 pantallas pasa. Además el «registro de accesibilidad por pantalla» no se verifica: no se pide un estado ni un resultado por pantalla, sólo el nombre · close: con una declaración a la que le falta `pantalla_inicio` o cualquier pantalla sin su estado, el test falla · open

ACT-?? · F1 · M · H21-04: el test pide que cada dependencia directa aparezca nombrada, no que tenga su licencia. Un `THIRD_PARTY_NOTICES.md` con «generado con `x`» y la lista de nombres pasa. `\bhttp\b` también se satisface con cualquier URL `http://`. Las transitivas, que REV-07-ASM-07 dice cubrir y entre las que está certifi, sólo se verifican para certifi en H25-01, y el test no comprueba que el archivo coincida con lo que genera el script que cita · close: con un aviso en el que una dependencia de producción (directa o transitiva) no tiene licencia, o que difiere de la salida del script, el test falla · open

ACT-?? · F1 · M · H25-01: el hallazgo dice «sin excepción escrita»; el test acepta los títulos `## MPL-2.0` y `## LGPL-3.0` vacíos, sin texto ni justificación. `next(...)` toma la primera línea que contiene `certifi`, que puede ser cualquier mención. Un `OFL.txt` de una línea «SIL Open Font License» pasa, sin el aviso de copyright de cada familia (Inter, Archivo, Archivo Black, JetBrains Mono). `assert fuentes` siempre es verdadero hoy · close: con secciones MPL/LGPL vacías o un OFL.txt sin el copyright de alguna de las familias de `assets/fuentes`, el test falla · open

ACT-?? · F1 · M · H22-01: la regex de supuestos acepta cualquier ID con la forma correcta: `- CU-99-SUP-1 x` cinco veces pasa sin que el ID exista en ningún `ambiguities.md`/snapshot. Del ejemplo del hallazgo faltan «el admin no reserva» y «catálogo fijo»; `pagos` se satisface con cualquier mención · close: con un README que cita un ID que no está registrado en el repo, o que omite el admin que no reserva o el catálogo fijo, el test falla · open

ACT-?? · F1 · L · H21-01: estado y evidencia se validan sólo como no vacíos. Las 253 filas `not applicable` con evidencia `-` pasan; la plantilla pide que `not applicable` lleve la razón, y REV-07-ASM-06 que las filas `fails` citen el hallazgo y la card · close: con una fila `not applicable` sin razón o una `fails` sin hallazgo, el test falla · open

ACT-?? · F1 · L · H21-09: `capacidad` puede estar en cualquier lugar de `system-design.md` y `p95 … 300 ms` en una sola línea alcanza. No se exige una sección ni la cifra de capacidad (usuarios o reservas concurrentes) · close: con un documento sin cifra de capacidad, el test falla · open

ACT-?? · F1 · L · H21-05: `## Volume assumptions`, `Render` y `USD 0` alcanzan. No se exigen la línea de cada servicio (Render web, Postgres, Firebase) ni el total · close: con un documento sin el costo de alguno de esos servicios, el test falla · open

ACT-?? · F1 · L · H21-06: cada sección se valida como no vacía; «TODO» pasa. No se exige que se nombren los secretos que se rotan (credencial de Firebase, URL de la base, SMTP) ni el paso de rollback en Render · close: con un runbook que no nombra cada secreto de `render.yaml`, el test falla · open

ACT-?? · F1 · L · H21-03: un único `0001-x.md` con `## Status FastAPI Flutter Render` pasa; no se exigen contexto, decisión ni consecuencias · close: con un ADR sin `## Decision` o `## Consequences`, el test falla · open

## Lo del hallazgo que queda sin test

- **Hallazgo 22, segunda viñeta** (`SUP-NN` en vez de `ASM-NN`, claves `fuentes:`/`no_leido:`, `required.mjs` no los encuentra): ningún escenario ni test la cubre. El snapshot la anota como contradicción «Sin resolver» y REV-07-AMB-02 cita la frase, pero pregunta otra cosa (cuántos supuestos van al README). Frase sin efecto y sin evento que la nombre: hace falta un AMB/ASM o un `REV-07-OUT-NN` que la deje registrada. M.
- **Hallazgo 21, «presupuesto … ni la declaración de que no lo hay»**: el test exige un p95 en ms; no acepta la otra rama que la card admite (declarar que no hay). Con REV-07-ASM-01 (metas sin medir) la decisión está registrada; es una observación, no un fallo.
- **Hallazgo 21, «entornos»**: sólo se buscan las palabras `local` y `Render`; no se verifican el emulador de Firebase ni las variables por entorno. L.
- **`specs/MOD-01-modelo-de-datos/data-model.md`** sigue cubriendo 4 de 9 tablas: el test lee el modelo desde `system-design.md` y no verifica que el documento viejo se actualice ni que remita al nuevo. Quedan dos modelos que se contradicen. L.

## Observaciones (no son fallos)

- `_seccion` compara por prefijo: `## Data flow` antes de `## Data model` hace que H21-08 lea la sección equivocada. Da un falso rojo, no un falso verde.
- La contradicción «módulo docs apagado» frente a «Archivos: docs/» la cierra REV-07-ASM-04 (sirve con cualquier respuesta).
- REV-07-ASM-01 se declara `any-answer: no`: si la respuesta es «sólo lo que existe», las metas de SLO y presupuesto salen y los tests H21-02 (`SLO`) y H21-09 (`p95 … ms`) quedan exigiendo lo contrario. Es el supuesto que no sirve con cualquier respuesta: lo que serviría con las dos es un test que acepte la meta o la declaración de que no la hay.
