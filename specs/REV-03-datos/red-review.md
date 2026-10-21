# Red review · REV-03 · datos

Fuente: `card.snapshot.md` (8 escenarios) y, del plan, `## Assumptions` y `## Perimeter`. Tests leídos:
`apps/api/tests/escenarios/test_datos.py`, `apps/mobile/test/historial_por_tandas_test.dart`. Corridas: `D:/Temp/rojo-rev03-api.log`
(13 fallan, 6 pasan: ida y vuelta 0002–0007) y `D:/Temp/rojo-rev03-app.log` (falla).

## Cobertura por escenario

| Escenario | Test(s) | ¿Lo prueba de verdad? |
|---|---|---|
| H10-01 historial propio por índice, sin recorrer la tabla | `test_el_historial_propio_tiene_un_indice_por_socio` | A medias: afirma que existe un índice que empieza en `usuario_id`; no que la consulta del historial lo use (P9/P11), ni que el índice sea válido |
| H10-02 historial propio por páginas | `test_el_historial_propio_llega_por_tandas`, `test_un_marcador_..._invalido`, Flutter | Sí en API (20+5, ids únicos, `siguiente` null). Falta orden, empates de `inicio` en el corte, borde exacto de 20 y vacío. El de Flutter no rompe donde debería (ver F-03) |
| H10-03 página avanzada del global sin recorrer ni contar | `test_el_historial_global_avanza_por_marcador`, `test_el_historial_global_tiene_un_indice_por_fecha` | A medias: no detecta un duplicado en el corte; el índice se exige con un texto exacto; nada mide el plan de la consulta; «sin contar» queda contradicho por `total == 25` (ASM-10, registrado) |
| H10-04 FKs con índice | `test_quien_cancelo_y_que_aviso_reemplazo_tienen_indice` | Sí (existencia, columna líder). No mira `indisvalid` |
| H11-01 aviso varado en `enviando` se reenvía | 3 tests (`_varar`) | A medias: el estado varado se fabrica por SQL con `tomada_en` e `intentos` puestos a mano; ningún test pasa por el camino real (tomar → caída → reintento) |
| H11-02 recordatorio registrado y no enviado se reintenta | 2 tests | Sí para el caso feliz; faltan los casos en que el reintento NO debe salir (reserva cancelada/movida/ya empezada, CU-24.1 FA4) y el doble envío con un barrido en curso |
| H13-01 migración nueva no bloquea | `test_la_migracion_nueva_no_se_queda_esperando_un_bloqueo` | A medias: prueba `lock_timeout` sobre `reserva`; no prueba `CONCURRENTLY` ni `NOT VALID`, ni `notificacion`, ni que la versión anterior siga funcionando (P5) |
| H13-02 ida y vuelta en la suite | `test_cada_migracion_va_y_vuelve_con_datos[0002..0008]` | A medias: sólo cuenta filas de `reserva`; no compara el esquema tras el downgrade, así que un downgrade vacío más un upgrade idempotente pasa |

Las razones del rojo son correctas en la API: índices ausentes (`assert False`), `KeyError: 'siguiente'`, `200 == 422`, y en H11
la columna `tomada_en` que todavía no existe. Leí `tomar_siguiente` (`tipo <> 'recordatorio'`) y `vencidos` (`NOT EXISTS` sobre
`notificacion`): con la columna creada y el código de hoy, H11-02 seguiría en rojo por comportamiento y no sólo por el esquema.

## Hallazgos

| # | Test | Qué falta | Por qué | Grav. |
|---|---|---|---|---|
| F-01 | H11-01 (`_varar`) | Un test por el camino real: `tomar_siguiente` toma el aviso, el despacho muere (el canal lanza `BaseException`/`SystemExit`, que el `except Exception` no atrapa), se avanza el reloj o se envejece sólo `tomada_en`, y otro despacho lo manda. Y afirmar que tomar deja `tomada_en` no nulo e `intentos` + 1 (ASM-05, ASM-09) | `_varar` escribe a mano `tomada_en` e `intentos`, justo lo que la implementación tiene que escribir. Si `tomar_siguiente` no los graba, en producción `tomada_en` queda NULL, la condición «hace más de 5 min» nunca se cumple y el aviso sigue varado para siempre (el hallazgo 11), con los tres tests en verde | H |
| F-02 | H13-02 ida y vuelta | Comparar el esquema (columnas, índices, constraints de `pg_catalog`) en `revision-1` antes de subir y después de bajar, además del conteo | ASM-06 dice «alcanza con que el esquema vuelva», y el test no lo mira: un `downgrade` que no hace nada más un `upgrade` con `IF NOT EXISTS` pasa los 7 casos | M |
| F-03 | Flutter `historial_por_tandas_test.dart` | Que el rojo sea por la tanda que falta y no por una precondición | Rompe en `scrollUntilVisible` con `Bad state: No element` (no encuentra ningún `Scrollable`), antes de la afirmación sobre «Lluvia 25» y el pedido con `marcador-20`. `mias()` hoy sí lee `{"reservas": [...]}`, así que con el código actual se esperaría ver 20 tarjetas y fallar por la 25; no lo hace. Puede quedar en verde o en rojo por motivos ajenos a la paginación | M |
| F-04 | H10-03 `test_el_historial_global_avanza_por_marcador` | Afirmar ids únicos (25 distintos) en las dos tandas, como hace el test del propio | Un corte con `>=` en vez de `>` repite la última de la página 1 al principio de la 2: el orden no estricto (`sorted(reverse=True)`) lo acepta, y 20 + 5 sigue dando 25 si se pierde la última | M |
| F-05 | H10-02 y H10-03 | Empates de `inicio` en el corte (P10, ASM-07): varias reservas con el mismo `inicio` que caigan entre la 20 y la 21 | `_pasadas` crea una por día; nunca hay empates, que es donde un marcador sin `id` salta o repite filas | M |
| F-06 | H10-01 y H10-03 (índices) | Un `EXPLAIN` de la consulta real del historial propio y del global (con `enable_seqscan = off` o suficientes filas) que no tenga `Seq Scan on reserva` ni `Sort` en disco | Los escenarios dicen «sin recorrer toda la tabla» (P9, P11); la existencia del índice no garantiza que la consulta lo use (un `WHERE` no indexable, un orden distinto). Además el test del global exige el texto `(inicio DESC, id DESC)`: un índice `(inicio, id)` recorrido hacia atrás cumple el escenario y falla el test | M |
| F-07 | H13-01 | Probar que los índices de 0008 sobre tablas con datos se crean sin bloquear escrituras (`CONCURRENTLY`) y los CHECK con `NOT VALID`: p. ej. un `INSERT` concurrente en `reserva` que termina mientras corre la migración, o el SQL de `alembic upgrade --sql` | El escenario es «no bloquea las tablas con datos» (P12); el test sólo cubre `lock_timeout`. Un `CREATE INDEX` normal con `lock_timeout` pasa y bloquea las escrituras durante todo el build | M |
| F-08 | H13-01 | El mismo bloqueo sobre `notificacion` (0008 le agrega columnas e índice) | Sólo se bloquea `reserva`; un `lock_timeout` puesto únicamente en la parte de `reserva` pasa | L |
| F-09 | H13-01 (P5) | Que la versión anterior siga funcionando con 0008 aplicada: insertar en `notificacion` con las columnas de 0007 y correr la consulta vieja de `tomar_siguiente` | «Mientras la versión anterior atiende»: si `intentos`/`tomada_en` entran `NOT NULL` sin default, la API vieja rompe durante el deploy y ningún test lo ve | M |
| F-10 | H11-02 | Un recordatorio `pendiente` cuya reserva se canceló, se movió o ya empezó no se manda (queda descartado/`fallida`) | CU-24.1 FA4 y regla de disparo. El reintento es un camino nuevo de envío y puede saltarse los chequeos que hoy hace `registrar` | H |
| F-11 | H11-02 | Un recordatorio `pendiente` registrado hace un instante (barrido en curso) no se manda dos veces | CU-24.1 «se envía una sola vez». Sólo se prueba `pendiente` de hace 10 min; un reintento que toma cualquier `pendiente` duplica con el barrido concurrente | M |
| F-12 | H10-02 marcador (E14, ASM-01) | Formas de entrada: `despues=` vacío, `despues` repetido, un número, un base64 de JSON con tipos equivocados o campos ausentes (`inicio` no fecha, `id` texto/negativo/nulo), un marcador válido después del final (ASM-01: lista vacía y `siguiente: null`), y el 422 también en `/reservas/todas` | Sólo se prueba `"no-es"` en el propio. Un marcador decodificable con tipos equivocados es el caso que suele terminar en 500 | M |
| F-13 | H10-03 (ASM-11) | `pagina` sigue funcionando y, con `pagina` y `despues` juntos, gana `despues` | Es lo que mantiene vivas las apps instaladas; sin test, un cambio lo rompe en silencio | M |
| F-14 | H10-02 bordes | Exactamente 20 reservas (la 2.ª tanda vacía o `siguiente` null), cero reservas (CU-08 FA1: lista vacía, `siguiente` null) y orden por fecha descendente en el propio (CU-08 paso 4, ASM-03 «las 20 más recientes») | El test sólo prueba 25; no afirma orden en el propio | L |
| F-15 | H10-04 y H13-01 | `indisvalid` en los índices nuevos de la base de la suite | `pg_indexes` también lista índices inválidos que dejó un `CONCURRENTLY` interrumpido | L |
| F-16 | Flutter | Error al traer la 2.ª tanda (sin conexión/500: mensaje y reintento, sin perder la 1.ª), sin pedido extra cuando `siguiente` es null, y sin pedidos dobles con un scroll rápido | Sólo cubre el camino feliz | L |
| F-17 | H10-02 (D10) | Un marcador fabricado con el `id`/`inicio` de una reserva ajena no deja ver nada de otro socio | El marcador va sin firmar; hoy no hay test de la frontera | L |

## Acciones

```
ACT-?? · F1 · H · H11-01: los tests fabrican el estado varado con `tomada_en`/`intentos` por SQL; no hay test que tome el aviso con `despachar_pendientes`, haga caer el despacho (canal que lanza SystemExit) y lo recupere en otro despacho · close: un test @REV-03-H11-01 que recorre tomar → caída → reenvío sin escribir `tomada_en` ni `intentos` a mano está en rojo y afirma `intentos` y `tomada_en` tras la toma · open
ACT-?? · F1 · H · H11-02: falta el caso en que el recordatorio `pendiente` NO debe salir (reserva cancelada, movida o ya empezada; CU-24.1 FA4) · close: un test @REV-03-H11-02 con la reserva cancelada antes del barrido afirma `canal.enviados == []` · open
ACT-?? · F1 · M · H13-02: el test de ida y vuelta sólo cuenta filas de `reserva`; un downgrade vacío pasa · close: el test compara el esquema de `pg_catalog` en `revision-1` antes y después de bajar · open
ACT-?? · F1 · M · Flutter H10-02: el rojo es `Bad state: No element` en `scrollUntilVisible` (falta el Scrollable), no la tanda que falta · close: `flutter test test/historial_por_tandas_test.dart` sobre el código actual falla en la afirmación de «Lluvia 25» o del pedido con `marcador-20` · open
ACT-?? · F1 · M · H10-03: el test del global no detecta un duplicado en el corte entre tandas · close: el test afirma 25 ids distintos · open
ACT-?? · F1 · M · H10-02/H10-03: ningún test pone empates de `inicio` en el corte de 20 · close: un test con varias reservas del mismo `inicio` entre la 20 y la 21 afirma 25 ids distintos y orden (inicio, id) desc · open
ACT-?? · F1 · M · H10-01/H10-03: los tests miran que el índice exista, no que la consulta lo use; el del global exige el texto `(inicio DESC, id DESC)` · close: un test hace `EXPLAIN` de la consulta del historial propio y del global y afirma que no hay `Seq Scan on reserva` · open
ACT-?? · F1 · M · H13-01: no se prueba que la migración no bloquee las escrituras (CONCURRENTLY / NOT VALID), sólo `lock_timeout` · close: un test afirma que un INSERT concurrente en `reserva` termina mientras corre 0008, o que el SQL de 0008 usa CONCURRENTLY y NOT VALID · open
ACT-?? · F1 · M · H13-01 (P5): nada prueba que la versión anterior siga funcionando con 0008 aplicada · close: un test inserta en `notificacion` con las columnas de 0007 tras subir a 0008 sin error · open
ACT-?? · F1 · M · H11-02: no se prueba que un recordatorio `pendiente` recién registrado no se mande dos veces · close: un test con `pendiente` de hace segundos afirma un solo envío · open
ACT-?? · F1 · M · H10-02 marcador: faltan las formas vacío, repetido, tipos equivocados dentro del marcador, válido después del final y el 422 del global · close: tests parametrizados que dan 422 con `errores.despues` (o lista vacía y `siguiente: null` para el válido después del final) · open
ACT-?? · F1 · M · ASM-11: no se prueba `pagina` ni `pagina` + `despues` · close: un test afirma que `pagina=2` sigue respondiendo y que con los dos manda `despues` · open
```

Menores (L, sin acción obligatoria): F-08, F-14, F-15, F-16, F-17.

## Observaciones

- La contradicción «sin contar toda la tabla» frente al contador de CU-14 se resuelve con ASM-10 (`any-answer: no`); el test fija
  `total == 25`. Está registrado; va al PR.
- ASM-02 (`any-answer: no`): el aviso de cancelación puede llegar dos veces y el recordatorio no. Tiene tests de los dos lados.
- No hay dinero en juego en esta card: el redondeo al centavo no aplica.
- No se corrió nada: es revisión de los tests y de los logs de rojo.
