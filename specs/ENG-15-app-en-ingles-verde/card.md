# ENG-15 · la app en inglés y en capas pasa su suite en la rama `ingles`

status: proposed
cap: 2 h
sources:
  - "pedido (texto) · mensajes del usuario en la sesión (2026-10-27): «no me gusta nada que todo el codigo este en español» · «en la app no hay capas, y es complicadisimo de entender por eso, la logica esta al lado de los componentes» · «dejala en su propia branch, sin tocar main» · «ahora si termina de implementar todo lo que faltaba»"
  - "trabajo previo · ENG-08..ENG-11 integradas en la rama `ingles` (lib/features/<x>/{data,domain,presentation} en inglés): la suite completa dio 648 pasan y 37 fallan; specs/ENG-13-api-en-ingles/handoff-app.md lista los que siguen rojos"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "no me gusta nada que todo el codigo este en español" · acceptance: en la rama `ingles`, la suite completa de la app pasa salvo los tests que también fallan en main (cada uno nombrado en el Log con su corrida en main), sin debilitar lo que verifica ningún test: lo que cambia en un test es el nombre o la ruta que el renombre obliga
- S2 · "la logica esta al lado de los componentes" · acceptance: cada funcionalidad de `lib/features` cumple la regla de capas de test/capas_test.dart
- S3 · "dejala en su propia branch, sin tocar main" · acceptance: ningún commit de la card llega a main ni se publica como PR a main
- ENG-15-ASM-01 · un test que falla por un comportamiento distinto de main (no por un nombre) se arregla en el código para que la app se comporte como main · S1

## Tasks

- T1 · S1,S2,S3,ENG-15-ASM-01 · apps/mobile/lib (presentation), apps/mobile/test/app_en_ingles_verde_test.dart · tests: apps/mobile/test/app_en_ingles_verde_test.dart "ningún archivo de lib queda en una carpeta en castellano @ENG-15-S1 @assumption:ENG-15-ASM-01"; apps/mobile/test/app_en_ingles_verde_test.dart "cada funcionalidad de lib/features tiene sus capas data, domain y presentation @ENG-15-S2"; apps/mobile/test/app_en_ingles_verde_test.dart "la rama ingles no está en main @ENG-15-S3"
  reuses: el código de ENG-08..ENG-11 en la rama `ingles`; la regla de capas de capas_test
  también: apps/mobile/lib/features/notifications/domain/notification_kind.dart (rule), apps/mobile/lib/features/notifications/presentation/bell_button.dart (presentation), apps/mobile/lib/features/notifications/presentation/notice_card.dart (presentation) · NOT-04 y NOT-05 de main portados a las rutas en inglés al integrar
- T2 · S1 · apps/api/app/modules/notificaciones/correo.py (rule), apps/api/migraciones/versions/0011_recordatorio_cinco_minutos.py (data), apps/api/pyproject.toml (data) · traído de main al integrar: NOT-05/MAIL-03 de la API, que porta la rama ENG-14; esta card no los modifica
  new: archivos de la API que la integración de main trajo sin cambios
- T3 · S1 · apps/mobile/lib/common/skeleton.dart (presentation), apps/mobile/lib/common/skeleton_list.dart (presentation), apps/mobile/lib/common/skeleton_zone.dart (presentation), apps/mobile/lib/features/home/presentation/home_greeting.dart (presentation), apps/mobile/test/saludo_por_hora_test.dart, apps/mobile/test/esqueletos_de_carga_test.dart, apps/mobile/test/esqueletos_de_carga_pantallas_test.dart, apps/mobile/test/inicio_test.dart, apps/mobile/test/admin/pantalla_panel_admin_test.dart, apps/mobile/test/rediseno/movimiento_pantallas_test.dart, apps/mobile/integration_test/inicio/home_test.dart · portado de main al integrar: SAL-01 y VIS-02 (424319d) a los nombres y rutas en inglés; mismos títulos y tags
  new: lo que la integración de main trajo, con los nombres en inglés

## Changes to existing behavior

- none: la app se ve y se comporta como main; cambian nombres y carpetas

## Gate

```
suite [timeout 1 h]: sh D:/Temp/w/herramientas/flutter-mobile.sh
fmt: D:/projects/flutter/bin/dart format --output=none --set-exit-if-changed apps/mobile/lib apps/mobile/test/app_en_ingles_verde_test.dart
lint: D:/projects/flutter/bin/flutter analyze --no-pub apps/mobile
suite-api [timeout 2 h]: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider
lint-api: sh D:/Temp/w/herramientas/eng14-ruff-mypy-flutter-analyze.sh apps/api/app apps/api/tests/escenarios/test_basquet_3x3.py apps/api/tests/escenarios/test_cancelacion_forzosa_agrupado.py apps/api/tests/escenarios/test_recordatorio.py apps/api/tests/escenarios/test_repositorios_propios_actual.py apps/api/tests/escenarios/test_requisitos_no_funcionales.py apps/api/tests/escenarios/test_suite_confiable.py apps/api/tests/escenarios/test_suite_confiable_reemplazos_actual.py apps/api/tests/escenarios/test_suite_confiable_reemplazos_cobertura.py apps/api/tests/integracion/test_api_limpia_reservas.py apps/api/tests/integracion/test_aviso_en_envio_perdido.py apps/api/tests/integracion/test_destinatario_del_aviso.py apps/api/tests/integracion/test_notificaciones_api.py apps/api/tests/integracion/test_recordatorio_cinco_base.py apps/api/tests/unit/test_api_en_ingles_contrato_actual.py apps/api/tests/unit/test_api_en_ingles_verde.py apps/api/tests/unit/test_arquitectura_funcionalidades_actual.py apps/api/tests/unit/test_aviso_por_correo.py apps/api/tests/unit/test_aviso_por_correo_por_tipo.py apps/api/tests/unit/test_aviso_sin_correo.py apps/api/tests/unit/test_base_en_ingles_actual.py apps/api/tests/unit/test_brevo_email.py apps/api/tests/unit/test_capas_funcionalidades_actual.py apps/api/tests/unit/test_integraciones_documentadas.py apps/api/tests/unit/test_modulos_cuenta_en_ingles.py apps/api/tests/unit/test_modulos_cuenta_en_ingles_actual.py apps/api/tests/unit/test_notificaciones_casos_de_uso_bordes.py apps/api/tests/unit/test_notificaciones_reglas_bordes.py apps/api/tests/unit/test_readme_conciso.py apps/api/tests/unit/test_recordatorio_cinco.py
mutate apps/api/app/modules/notifications/rules.py: sh D:/Temp/w/herramientas/eng14-notif-tests.sh
mutate apps/api/app/modules/notifications/store.py: sh D:/Temp/w/herramientas/eng14-notif-tests.sh
mutate apps/api/app/modules/notifications/use_cases.py: sh D:/Temp/w/herramientas/eng14-notif-tests.sh
refactor-tests: los tests de la app siguen a las carpetas y nombres en inglés: cambian sólo imports, símbolos y rutas de archivo
app: sh D:/Temp/w/herramientas/arq01-app.sh eng15_app
attacks: sh D:/Temp/w/herramientas/arq01-attacks.sh eng15_app --json --body-limit 1048576 --no-ambient --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --unique 'POST /sedes {"nombre": "Sede Unica Ataque", "direccion": "Calle 2", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5]}'
no-docs: nombres internos de la app
no-visual: las pantallas se ven igual
```

## Log

- L1 · no me gusta nada que todo el codigo este en español · en la app no hay capas, y es complicadisimo de entender por eso, la logica esta al lado de los componentes · dejala en su propia branch, sin tocar main · ahora si termina de implementar todo lo que faltaba
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base
- L3 · 2026-10-27 · declared · attacks · la card no toca la API
- L4 · 2026-10-27 · T1 · fmt, lint (flutter analyze) y suite en verde; `node .claude/tools/verify.mjs`: fmt, lint, suite, shape, overdesign, migrations, boundaries passed; tests rojos que también fallan en D:/Temp/w/main (mismos nombres, misma corrida): interfaz_accesible_test "con un dato completado sólo se marca lo que falta ... @REV-04-S1"; limpieza_test "sólo fallo_de_carga.dart avisa la sesión vencida ... @ARQ-03-ASM-02" y "mi perfil valida el nacimiento con el reloj del club ... @ARQ-03-ASM-04"; limpieza_plan_test "sólo el token simulado de notificaciones usa DateTime.now @ARQ-03-ASM-04"; sin_sobreingenieria_test "a los 30 s sin respuesta ... @SIM-01-S4"; test/rediseno: las mismas 17 fallas en ambos árboles (`flutter test --reporter failures-only test/rediseno`: +97 -17 en ambos)
- L5 · 2026-10-27 · T2 · archivos de la API traídos de main al integrar (correo.py, migración 0011, pyproject.toml): los porta la rama ENG-14; esta card no los modifica
- L6 · 2026-10-27 · declared · layers · apps/api/migraciones/versions/0011_recordatorio_cinco_minutos.py · una migración es SQL por definición
- L7 · 2026-10-27 · declared · mutate · apps/mobile/lib/features/notifications/domain/notification_kind.dart · `mutate.mjs` responde "no operator applies to this file" (exit 3): es una enumeración sin lógica
- L8 · 2026-10-27 · declared · lint · apps/api/tests/integracion/test_destinatario_del_aviso.py, test_recordatorio_cinco_base.py, apps/api/tests/unit/test_aviso_por_correo.py, test_aviso_por_correo_por_tipo.py, test_aviso_sin_correo.py, test_integraciones_documentadas.py, test_readme_conciso.py, test_recordatorio_cinco.py · tests de la API traídos de main, fuera del Flutter lint; `ruff check` da 6 errores (imports sin ordenar, rutas aún en castellano) que corrige ENG-14 al portarlos; los dueños son ENG-14
- L9 · 2026-10-27 · declared · K4 · apps/mobile/test/rediseno/pantallas_test.dart · el armado de pantalla repetido viene del renombre de los tests portados; cada test monta su propio árbol
- L10 · 2026-10-27 · declared · K4 · apps/mobile/test/soporte/montar.dart · mismo bloque que pantallas_test por el renombre; los tests congelados no se pueden refactorizar
- L11 · 2026-10-27 · declared · K4 · apps/mobile/test/rediseno/marcador_proximas_reemplazo_test.dart · bloque repetido por el renombre de los tests portados
- L12 · 2026-10-27 · declared · K4 · apps/mobile/test/rediseno/marcador_de_proximas_test.dart · bloque repetido por el renombre de los tests portados
- L13 · 2026-10-27 · declared · K4 · apps/api/tests/integracion/test_recordatorio_cinco_base.py · tests de la API traídos de main; los porta ENG-14
- L14 · 2026-10-27 · declared · K4 · apps/api/tests/unit/test_recordatorio_cinco.py · tests de la API traídos de main; los porta ENG-14
- L15 · 2026-10-27 · declared · K4 · apps/mobile/test/sin_sobreingenieria_a11y_test.dart · bloque repetido por el renombre de los tests portados
- L16 · 2026-10-27 · declared · K4 · apps/mobile/test/admin/pantalla_panel_admin_test.dart · bloque repetido por el renombre de los tests portados
- L17 · 2026-10-27 · declared · K4 · apps/mobile/test/reintento_tras_corte_test.dart · bloque repetido por el renombre de los tests portados
- L18 · 2026-10-27 · declared · K4 · apps/mobile/test/piezas_de_pantalla_test.dart · bloque repetido por el renombre de los tests portados
- L19 · 2026-10-27 · declared · K4 · apps/mobile/test/reloj_del_token_test.dart · bloque repetido por el renombre de los tests portados
- L20 · 2026-10-27 · declared · K4 · apps/mobile/test/pantalla_inicio_sesion_test.dart · bloque repetido por el renombre de los tests portados
- L21 · 2026-10-27 · declared · K4 · apps/mobile/test/interfaz_accesible_registro_test.dart · bloque repetido por el renombre de los tests portados
- L22 · 2026-10-27 · declared · K4 · apps/mobile/test/interfaz_accesible_test.dart · bloque repetido por el renombre de los tests portados
- L23 · 2026-10-27 · declared · K4 · apps/mobile/test/inicio_test.dart · bloque repetido por el renombre de los tests portados
- L24 · 2026-10-27 · declared · K4 · apps/mobile/test/confirmacion_cancelacion_test.dart · bloque repetido por el renombre de los tests portados
- L25 · 2026-10-27 · declared · K4 · apps/mobile/test/rediseno/movimiento_reducido_reemplazo_test.dart · bloque repetido por el renombre de los tests portados
- L26 · 2026-10-27 · declared · K4 · apps/mobile/test/cancelacion_forzosa_test.dart · bloque repetido por el renombre de los tests portados
- L27 · 2026-10-27 · declared · K4 · apps/mobile/test/admin/detalle_y_filtros_reservas_test.dart · bloque repetido por el renombre de los tests portados
- L28 · 2026-10-27 · declared · K4 · apps/mobile/test/anular_reserva_test.dart · bloque repetido por el renombre de los tests portados
- L29 · 2026-10-27 · declared · K4 · apps/mobile/test/anular_desde_el_detalle_test.dart · bloque repetido por el renombre de los tests portados
- L30 · 2026-10-27 · declared · K4 · apps/mobile/test/accesibilidad_sesion_test.dart · bloque repetido por el renombre de los tests portados
- L31 · 2026-10-27 · declared · mutate · apps/api/app/modules/notificaciones/correo.py · código de la API traído de main sin cambios, con tests de la API que corre ENG-14 (la suite de esta card es la de Flutter, no lo ejerce); lo muta y lo porta ENG-14
- L32 · 2026-10-27 · T3 · portados SAL-01 y VIS-02 de origin/main 424319d: tests saludo_por_hora, esqueletos_de_carga, esqueletos_de_carga_pantallas, inicio, admin/pantalla_panel_admin, rediseno/movimiento_pantallas e integration_test/inicio/home; `dart format` y `flutter analyze`: sin avisos; esos 6 archivos de test en verde salvo los rojos de L33
- L33 · 2026-10-27 · T3 · rojos que también fallan en main 424319d (misma corrida en el árbol principal): esqueletos_de_carga_test "... @VIS-02-S1 ... /sedes|/reservas|/inicio|/admin/sedes" (`!timersPending`: el test de main no desmonta; lo cubre esqueletos_de_carga_pantallas_test); movimiento_pantallas_test "... @RED-04-S14" está entre las 17 fallas ya conocidas (L4)
- L34 · 2026-10-27 · declared · K4 · apps/mobile/test/esqueletos_de_carga_test.dart · bloque repetido con esqueletos_de_carga_pantallas_test, que viene así de main; los tests congelados no se pueden refactorizar
- L35 · 2026-10-27 · declared · K4 · apps/mobile/test/esqueletos_de_carga_pantallas_test.dart · bloque repetido con esqueletos_de_carga_test, que viene así de main
