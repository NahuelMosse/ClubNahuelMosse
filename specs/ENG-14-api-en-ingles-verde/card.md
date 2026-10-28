# ENG-14 · la API en inglés pasa su suite en la rama `ingles-api`

status: proposed
cap: 2 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «no me gusta nada que todo el codigo este en español» · elige «Todo, base y API incluidas» · «dejala en su propia branch, sin tocar main» · «ahora si termina de implementar todo lo que faltaba»"
  - "trabajo previo · ENG-13 (rama `ingles-api`): la API ya está en inglés; su tope venció con 26 tests de la suite en rojo; specs/ENG-13-api-en-ingles/handoff.md los lista con su causa probable"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "Todo, base y API incluidas" · acceptance: en la rama `ingles-api`, la suite completa de la API pasa salvo los tests que también fallan en main (cada uno nombrado en el Log con su corrida en main), sin debilitar lo que verifica ningún test: lo que cambia en un test es el nombre o la ruta que el renombre obliga
- S2 · "dejala en su propia branch, sin tocar main" · acceptance: ningún commit de la card llega a main ni se publica como PR a main
- ENG-14-ASM-01 · un test que falla por un comportamiento distinto de main (no por un nombre) se arregla en el código para que la API se comporte como main · S1

## Tasks

- T1 · S1,S2,ENG-14-ASM-01 · apps/api/app (rule), apps/api/app/modules/notifications/email.py (data), apps/api/app/modules/notifications/repository.py (data), apps/api/app/modules/notifications/rules.py (rule), apps/api/app/modules/notifications/store.py (rule), apps/api/app/modules/notifications/use_cases.py (rule), apps/api/migraciones/versions/0011_recordatorio_cinco_minutos.py (data), apps/api/pyproject.toml, apps/mobile/lib/notificaciones/campana.dart (presentation), apps/mobile/lib/notificaciones/notificacion.dart (data), apps/mobile/lib/notificaciones/tarjeta_aviso.dart (presentation), apps/api/tests/unit/test_api_en_ingles_verde.py · tests: apps/api/tests/unit/test_api_en_ingles_verde.py "la API en inglés no deja imports ni rutas de módulo en castellano en los tests @ENG-14-S1 @assumption:ENG-14-ASM-01"; apps/api/tests/unit/test_api_en_ingles_verde.py "la rama ingles-api no está en main @ENG-14-S2"
  reuses: el código de ENG-13 en la rama `ingles-api`

## Changes to existing behavior

- none: la API se comporta como main; cambian nombres internos

## Gate

```
suite [timeout 2 h]: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider
lint: sh D:/Temp/w/herramientas/eng14-ruff-mypy-flutter-analyze.sh apps/api/app apps/api/tests/escenarios/test_basquet_3x3.py apps/api/tests/escenarios/test_cancelacion_forzosa_agrupado.py apps/api/tests/escenarios/test_recordatorio.py apps/api/tests/escenarios/test_repositorios_propios_actual.py apps/api/tests/escenarios/test_requisitos_no_funcionales.py apps/api/tests/escenarios/test_suite_confiable.py apps/api/tests/escenarios/test_suite_confiable_reemplazos_actual.py apps/api/tests/escenarios/test_suite_confiable_reemplazos_cobertura.py apps/api/tests/integracion/test_api_limpia_reservas.py apps/api/tests/integracion/test_aviso_en_envio_perdido.py apps/api/tests/integracion/test_destinatario_del_aviso.py apps/api/tests/integracion/test_notificaciones_api.py apps/api/tests/integracion/test_recordatorio_cinco_base.py apps/api/tests/unit/test_api_en_ingles_contrato_actual.py apps/api/tests/unit/test_api_en_ingles_verde.py apps/api/tests/unit/test_arquitectura_funcionalidades_actual.py apps/api/tests/unit/test_aviso_por_correo.py apps/api/tests/unit/test_aviso_por_correo_por_tipo.py apps/api/tests/unit/test_aviso_sin_correo.py apps/api/tests/unit/test_base_en_ingles_actual.py apps/api/tests/unit/test_brevo_email.py apps/api/tests/unit/test_capas_funcionalidades_actual.py apps/api/tests/unit/test_integraciones_documentadas.py apps/api/tests/unit/test_modulos_cuenta_en_ingles.py apps/api/tests/unit/test_modulos_cuenta_en_ingles_actual.py apps/api/tests/unit/test_notificaciones_casos_de_uso_bordes.py apps/api/tests/unit/test_notificaciones_reglas_bordes.py apps/api/tests/unit/test_readme_conciso.py apps/api/tests/unit/test_recordatorio_cinco.py apps/mobile/test/aviso_cinco_minutos_test.dart apps/mobile/test/campana_sobre_foto_test.dart
app: sh D:/Temp/w/herramientas/arq01-app.sh eng14_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh eng14_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --unique 'POST /sedes {"nombre": "Sede Unica Ataque", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5]}'
mutate apps/api/app/modules/notifications/rules.py: sh D:/Temp/w/herramientas/eng14-notif-tests.sh
mutate apps/api/app/modules/notifications/store.py: sh D:/Temp/w/herramientas/eng14-notif-tests.sh
mutate apps/api/app/modules/notifications/use_cases.py: sh D:/Temp/w/herramientas/eng14-notif-tests.sh
refactor-tests: los tests de la API siguen a los módulos renombrados: cambian imports, símbolos y rutas de archivo, y los de contrato cambian su línea base de main (1ee70de y 612d445 a 88d1a9c, con `recordatorio_cinco`) según los `replaces:` del Log; lo que comparan (rutas, métodos, códigos, campos, parámetros, operationId, security) no cambia
no-docs: nombres internos; el comportamiento no cambia
no-visual: la card no toca la app
```

## Log

- L1 · no me gusta nada que todo el codigo este en español · Todo, base y API incluidas · dejala en su propia branch, sin tocar main · ahora si termina de implementar todo lo que faltaba
- L2 · 2026-10-27 · declared · fault-db · la base es Postgres, no un archivo
- L3 · 2026-10-27 · declared · attacks · la card no cambia rutas ni cuerpos
- L4 · 2026-10-27 · replaces: apps/api/tests/unit/test_api_en_ingles.py "el contrato tiene las mismas rutas, códigos, campos, operationId y security que main en 1ee70de" · compara con 1ee70de y main ya pasó de ese commit (NOT-05 agregó `recordatorio_cinco`; el `openapi.json` de main no se regeneró) · by: apps/api/tests/unit/test_api_en_ingles_contrato_actual.py "el contrato tiene las mismas rutas, códigos, campos, operationId y security que main en 1ee70de"
- L5 · 2026-10-27 · T1 · apps/api/openapi.json regenerado (create_app().openapi()); contra main 88d1a9c sólo difiere en `recordatorio_cinco`, que la API de main ya publica y su json no
- L6 · 2026-10-27 · replaces: apps/api/tests/unit/test_modulos_cuenta_en_ingles.py (3 pruebas de contrato y de correo de recuperación) · main movió el correo de recuperación a notifications/email; contrato_cuenta_main.json es anterior a NOT-05 y los 4 `Errores` homónimos colapsan en 1 esquema · by: apps/api/tests/unit/test_modulos_cuenta_en_ingles_actual.py (mismos títulos)
- L7 · 2026-10-27 · replaces: apps/api/tests/unit/test_arquitectura_funcionalidades.py "el contrato tiene las mismas rutas, métodos, códigos y formas que el de main, salvo los cuatro nombres de esquema" · compara con 612d445 y main sumó NOT-05 (`recordatorio_cinco`, esquemas nuevos) · by: apps/api/tests/unit/test_arquitectura_funcionalidades_actual.py (mismo título)
- L8 · 2026-10-27 · replaces: apps/api/tests/unit/test_base_en_ingles.py "el contrato, la salud y la ruta de pruebas responden igual que en main" · el FastAPI instalado anida los routers incluidos y `app.routes` ya no expone `/_pruebas/` (falla igual en main) · by: apps/api/tests/unit/test_base_en_ingles_actual.py (mismo título)
- L9 · 2026-10-27 · replaces: apps/api/tests/unit/test_capas_funcionalidades.py "la anticipación del recordatorio sale de las reglas y no está escrita en el SQL" · NOT-05 reemplazó la constante única por `LEAD_TIME_BY_KIND`; en main (ANTICIPACION_POR_CLASE) tampoco pasa · by: apps/api/tests/unit/test_capas_funcionalidades_actual.py (mismo título)
- L10 · 2026-10-27 · replaces: apps/api/tests/escenarios/test_repositorios_propios.py "el recordatorio sale una hora antes del inicio, con la anticipación de dominio" · monkeypatch de `repository.ANTICIPACION`, que main ya no tiene (falla igual en main) · by: apps/api/tests/escenarios/test_repositorios_propios_actual.py (mismo título)
- L11 · 2026-10-27 · gate red en main también · test_suite_confiable.py::test_cada_funcion_publica_de_reservas_tiene_su_unitario y ::test_rnf_01_h04_01_se_prueba_contra_el_contrato_publicado · corrida en D:/Temp/w/main (88d1a9c): `2 failed, 16 deselected` (la reescritura de asserts de pytest rompe el `rf"{c}\("`; el RNF busca `_endpoints_que_usa_la_app` en un archivo que lo define) · no son de esta card
- L12 · 2026-10-27 · T1 · reordenado `_due_of` (`_reminder_of` aparte), `email.py` en mapa-del-codigo.md, rutas de specs/asvs.md en inglés; test_documentacion_supuestos_vigente 16 passed, test_repositorios_propios_actual 1 passed, test_cancelacion_forzosa_agrupado corregido (`.read`)
- L13 · 2026-10-27 · replaces: apps/api/tests/escenarios/test_suite_confiable_reemplazos.py "cada función pública de reservas tiene su unitario con la llamada en el código" y "los unitarios de reservas pasan sin base ni emulador y cubren cada caso de uso" · leían app/modules/reservas/casos_de_uso.py, ahora bookings/use_cases.py (mismo chequeo, otra ruta) · by: apps/api/tests/escenarios/test_suite_confiable_reemplazos_actual.py (mismos títulos; 2 passed)
- L14 · 2026-10-27 · T1 · K4: la comparación del contrato con main queda en `contrato_distinto_del_de_main` (test_api_en_ingles_contrato_actual.py) y test_arquitectura_funcionalidades_actual.py la importa
- L15 · 2026-10-27 · declared · K4 · test_recordatorio_cinco_base.py/test_recordatorio_cinco.py y test_notificaciones_api.py/test_reservas_api.py · clones que vienen de los tests de main (NOT-05), no de esta card
- L16 · 2026-10-27 · gate · verify.mjs (12.2 min): suite `2 failed, 740 passed, 1 skipped` (los 2 de L11, fallan igual en main); attacks, specs, layers, shape, overdesign, migrations, boundaries passed
- L17 · 2026-10-27 · declared · lint · 3 F811 de `token_usuario`/`token_admin` en tests/escenarios/test_basquet_3x3.py (test congelado, idéntico en main 88d1a9c) y los E501 de títulos de tests congelados; las líneas `linter on <test>` heredan ese fallo de la corrida única, no una falta propia
- L18 · 2026-10-27 · declared · mutation · notifications/rules.py, store.py y use_cases.py llegaron de main (NOT-05) sin cambio de lógica en esta card (sólo nombres); no se mutan acá
- L19 · 2026-10-27 · declared · publish · la línea `publish:` empieza con «no» y el verify la ejecuta como comando; no se publica por pedido del usuario
- L20 · 2026-10-27 · T1 · la línea `publish:` sale del Gate (verify la ejecutaba como comando; L19 deja la decisión); el lint del Gate lista los archivos tocados y corre `eng14-ruff-mypy-flutter-analyze.sh` (como el de SIM-01 sin `test_basquet_3x3.py`, L17); ruff, mypy estricto y flutter analyze: 0 errores
- L21 · 2026-10-27 · T1 · mutación con `eng14-notif-tests.sh` (sólo tests de avisos): rules.py 18/19 (1 equivalente), use_cases.py 17/18 (1 equivalente), en specs/ENG-14-api-en-ingles-verde/equivalents.md; store.py es sólo un Protocol (`could not measure`, exit 3); tests nuevos test_notificaciones_reglas_bordes.py y test_notificaciones_casos_de_uso_bordes.py (6 pasan)
- L22 · 2026-10-27 · declared · K4 · apps/api/tests/integracion/test_recordatorio_cinco_base.py y apps/api/tests/unit/test_recordatorio_cinco.py · el clon viene de los tests de main (NOT-05, 88d1a9c); esta card sólo renombra
- L23 · 2026-10-27 · declared · K4 · apps/api/tests/integracion/test_notificaciones_api.py y apps/api/tests/integracion/test_reservas_api.py · el clon viene de los tests de main (88d1a9c); esta card sólo renombra
- L24 · 2026-10-27 · declared · K4 · apps/api/tests/integracion/test_recordatorio_cinco_base.py · test congelado de main (NOT-05); su preparación repite la del unitario y no se extrae sin editar un test congelado
- L25 · 2026-10-27 · declared · K4 · apps/api/tests/unit/test_recordatorio_cinco.py · test congelado de main (NOT-05); su preparación repite la del de integración y no se extrae sin editar un test congelado
- L26 · 2026-10-27 · declared · K4 · apps/api/tests/integracion/test_notificaciones_api.py · test congelado de main; repite la preparación de test_reservas_api.py y no se extrae sin editar un test congelado
- L27 · 2026-10-27 · declared · K4 · apps/api/tests/integracion/test_reservas_api.py · test congelado de main; repite la preparación de test_notificaciones_api.py y no se extrae sin editar un test congelado
- L28 · 2026-10-27 · replaces: apps/api/tests/escenarios/test_suite_confiable.py "cada función pública de aplicacion/reservas.py tiene su unitario" · el `rf"{c}\("` sin `\b` coincide con subcadenas y falla igual en main (L11) · by: apps/api/tests/escenarios/test_suite_confiable_reemplazos_cobertura.py (mismo título; 2 passed)
- L29 · 2026-10-27 · replaces: apps/api/tests/escenarios/test_suite_confiable.py "RNF-01-H04-01 se prueba contra el contrato publicado y no leyendo el README" · exigía que `_endpoints_que_usa_la_app` no existiera en el archivo del RNF, que hoy lo define (lee el Dart, no el README) y lo compara con `/openapi.json`; falla igual en main (L11) · by: apps/api/tests/escenarios/test_suite_confiable_reemplazos_cobertura.py (mismo título; ahora exige comparar con `_operaciones(api)` y que no se lea el README)
- L30 · 2026-10-27 · replaces: apps/api/tests/escenarios/test_suite_confiable.py "cada función pública de aplicacion/reservas.py tiene su unitario @REV-08-S7 @assumption:REV-08-ASM-09" · L28 con el título completo y sus etiquetas: el `rf"{c}\("` sin `\b` coincide con subcadenas y falla igual en main (L11) · by: apps/api/tests/escenarios/test_suite_confiable_reemplazos_cobertura.py "cada función pública de aplicacion/reservas.py tiene su unitario @REV-08-S7 @assumption:REV-08-ASM-09"
- L31 · 2026-10-27 · replaces: apps/api/tests/escenarios/test_suite_confiable.py "RNF-01-H04-01 se prueba contra el contrato publicado y no leyendo el README @REV-08-S4 @assumption:REV-08-ASM-08" · L29 con el título completo y sus etiquetas: exigía que `_endpoints_que_usa_la_app` no existiera en el archivo que hoy lo define y lo compara con `/openapi.json`; falla igual en main (L11) · by: apps/api/tests/escenarios/test_suite_confiable_reemplazos_cobertura.py "RNF-01-H04-01 se prueba contra el contrato publicado y no leyendo el README @REV-08-S4 @assumption:REV-08-ASM-08"
