# Revisión general · ClubNahuelMosse · kit SDD 3.0.0 · grado production

Rama `kit-3` @ 932cf77 · 2026-10-20 · módulos activos: ui, api, data, infra, observability, security-l2 (ci, docs e
i18n apagados por decisión). Revisión de la app entera —API, app Flutter, datos, despliegue y seguridad— contra los
177 criterios activos de `node .claude/tools/bar.mjs`. No se corrigió código ni se abrieron cards.

## Costo

- **Estimado antes de lanzar:** cinco jueces Opus (uno por grupo de áreas, 34 a 45 criterios cada uno), un `scout` y
  un `runner` en Sonnet. USD 45–80 y alrededor de 1 h 30 min.
- **Medido:** los jueces usaron entre 218 k y 295 k tokens cada uno (1,31 M en total), el `scout` 45 k y el `runner`
  25 k. Pared: unas 1 h 20 min. Los cinco jueces llegaron al tope de turnos y se reanudaron una vez para cerrar.
- **Cómo se juzgó:** los jueces corrieron como `oracle` siguiendo `.claude/agents/inspector.md`, porque la sesión que
  hizo la revisión no tenía cargado el agente `inspector` del kit. Los hallazgos M salidos sólo de juicio (sin medición)
  no tienen segundo juez (A7).

## Qué corrió

| Corrida | Resultado |
|---|---|
| `scripts/test.sh` sobre 932cf77 | **pasó** · ruff, mypy (53 archivos), pytest 384 ok / 1 saltado, flutter analyze, dart format (136 archivos), flutter test 416 |
| API levantada contra Postgres local y el emulador de Auth, con sondas HTTP propias | corrió · cuatro instancias de falla: base rechazada, base en agujero negro, Firebase en agujero negro y base sin esquema |
| `attack.mjs` (11 `--write`, 5 `--read`) | corrió, pero **no prueba esta API**: no puede mandar `Authorization` y todo da 401. Las mismas pruebas se repitieron a mano con token |
| `pip-audit` (lock de producción y de dev), OSV sobre `pubspec.lock` | corrió · 1 vulnerabilidad (hallazgo 7) |
| Capturas golden, 85 vistas × 360/430 × oscuro/claro | **pasó** · 340/340, más 170 a 320 px y 170 al 200 % sin excepción de desborde |
| Tests de accesibilidad de widgets | **pasó** · 68/68 |
| Migraciones 0001→0007 ida y vuelta con datos | **pasó** (medido; no está en la suite) |
| `EXPLAIN` con 200 k reservas | corrió · hallazgo 10 |
| `mutate.mjs` sobre `aplicacion/reservas.py` | **no se pudo correr**: la suite tarda 475 s con la máquina cargada y la herramienta corta en 10 min por archivo |
| ZAP baseline sobre `/openapi.json` | **no se pudo correr**: sin salida a los 3 min con la máquina cargada |
| `probe`, `app.mjs`, `overflow.mjs` | **no se pudo correr**: la app no está configurada para web y esas herramientas necesitan un navegador |
| e2e en el emulador Android y TalkBack | **no se pudo correr**: fuera del alcance de esta revisión |
| `doctor.mjs` | 10 de 24 chequeos no ok: falta `apps/e2e` (acá es `apps/mobile/integration_test`), faltan tsc, eslint, c8, stryker, semgrep, gitleaks y squawk, y no existe `.claude/tests` |

**Cuenta por grupo de criterios** (pasó · falló · no se pudo correr · no aplica):

| Grupo | Pasó | Falló | No se pudo correr | No aplica |
|---|---|---|---|---|
| R, D, K · requisitos, diseño, código | 11 | 21 | 4 | 0 |
| S + security-l2 | 9 | 12 | 1 | 2 |
| E, O · errores y operación | 18 | 18 | 2 | 2 |
| I, A, V, W · interfaz, accesibilidad, proceso | 16 | 16 | 11 | 2 |
| T, P, C · tests, datos, contrato | 10 | 16 | 7 | 1 |

## Hallazgos

De más a menos grave. H = alto, M = medio, L = bajo. «Medido» quiere decir reproducido contra la app corriendo o con un
test; «lectura» quiere decir que sale del código y no se reprodujo.

### H

1. **El correo SMTP no verifica el certificado del servidor** · ASVS V12.3.2 · falló · medido
   - `apps/api/app/infraestructura/correo.py:30-32`: `smtp.starttls()` sin `context`; el contexto por defecto no
     verifica (`verify_mode 0`, `check_hostname False`).
   - Evidencia: contra un SMTP falso con certificado autofirmado `CN=atacante.invalid`, el cliente aceptó el TLS y el
     servidor capturó el usuario y la contraseña SMTP y el enlace `/enlace/recuperar#codigo=…`.
   - Impacto: quien esté en el camino de red entre Render y el SMTP se lleva las credenciales y cada enlace de
     recuperación, es decir, la cuenta de cualquiera que pida recuperar la contraseña.

2. **Un corte de red con la base cuelga la API y el health check sigue en verde** · E8, O18 · falló · medido
   - `apps/api/app/infraestructura/db.py:12` crea el engine sin `connect_timeout` ni `pool_timeout`; el rol no tiene
     `statement_timeout` ni `lock_timeout`. `render.yaml:14` usa `/docs` como health check.
   - Evidencia: con la base en 10.255.255.1, `GET /reservas` tardó 131 s en dar 500 mientras `/docs` respondía 200 en
     5 ms.
   - Impacto: cada pedido retiene un hilo del pool 130 s (la app se rinde a los 15 s); con pocos usuarios la API se
     satura y Render la ve sana, así que no la reinicia.

3. **En Render los recordatorios de una hora antes no salen** · E14 · falló · lectura más la doc de Render
   - `apps/api/app/interfaz/barrido.py:38-45` y `app/main.py:26-31`: el barrido corre dentro del proceso web, y el plan
     free lo duerme a los 15 min sin tráfico (lo dice `apps/api/README.md:139-141`). La ventana de vencidos es
     (ahora, ahora + 1 h] (`infraestructura/notificaciones.py:137`), y un push fallido queda «fallida» sin reintento ni
     alerta (`aplicacion/notificaciones.py:110-130`).
   - Impacto: CU-24.1 se cumple en la nube sólo si alguien usa la API en la hora previa a cada turno, y nadie se entera
     cuando no.

4. **La base de producción no tiene backups, vence, y no hay vuelta atrás de datos** · O29, P7, P15 · falló · lectura más
   la doc de Render
   - `render.yaml:45-49` usa `plan: free`: sin backups, vence a los 30 días y se borra 14 días después
     (`apps/api/README.md:142`). Las migraciones corren en el build contra esa base (`render.yaml:11`).
   - Tampoco hay RPO ni RTO, restore probado, ni inventario, retención o clasificación de los datos personales (DNI,
     nacimiento, correo, token de dispositivo); la Ley 25.326 no figura en el repo.
   - Impacto: entre los días 30 y 44 se pierden todas las cuentas y reservas, y una migración mala no tiene vuelta.

### M

5. **Entradas sin cota dan 500** · K8, ASVS V1.4.2, V2.2.1 · falló · medido
   - `POST /reservas` con `horas = 10**12` → 500 (OverflowError en `aplicacion/reservas.py:162`, antes de validar). Con
     `fecha 9999-12-31, desde 23:00, horas 4` → 500 (date out of range, misma línea).
   - `GET /reservas/todas?pagina=2**70` → 500 (`infraestructura/reservas.py:506`; `Query` sin `le` en
     `interfaz/reservas.py:380`).
   - Un NUL en nombre, sede, motivo, token o correo → 500 (psycopg DataError) en 7 rutas, dos de ellas sin sesión
     (`/registro`, `/recuperacion`).
   - Impacto: cualquiera fuerza 500 y cada uno deja un ERROR con traceback; sin sesión se puede inundar el log.

6. **La API no tiene límite de frecuencia y deja consultar DNI y correos** · S24, ASVS V2.4.1 · falló · medido
   - `apps/api/app/main.py:41-62`: 30 `POST /recuperacion` en 0,9 s → 30 × 202; 20 `POST /registro` en 0,4 s → 20 × 422
     sin 429.
   - Oráculo: `PUT /yo` con DNI ajenos 31000001…31000007 → `[409, 200, 200, …]`, con el 409 «Este DNI ya está registrado»
     (`interfaz/sesion.py:163-167`); `/registro` con un correo ajeno → 409 «Este correo ya está registrado»
     (`interfaz/registro.py:70-78`).
   - Impacto: cualquiera con sesión consulta sin freno si un DNI es socio; `/registro` crea cuentas de Firebase sin
     verificar el correo y sin límite.

7. **Dependencia con vulnerabilidad conocida** · S11 · falló · medido
   - `apps/api/uv.lock:133-134`: certifi 2026.7.22 tiene PYSEC-2026-4320 / GHSA-6q48-6c7w-9gw2 (intermedias emSign
     comprometidas); corregido en ≥ 2026.10.18. `pubspec.lock`: 0 avisos en OSV.
   - Impacto: firebase-admin confía en esas intermedias al bajar las claves que validan los ID tokens; explotarlo
     requiere estar en el camino de red.

8. **Un solo usuario de base migra y atiende la app** · S20 · falló · lectura
   - `render.yaml:11,45-49`: el usuario `club` corre `alembic upgrade head` en el build y es el de la app; en local es
     superusuario.
   - Impacto: una inyección o un RCE tendría DDL completo sobre la base.

9. **Datos personales en los logs, y log falsificable** · P2, O5, S14, ASVS V16.4.1 · falló · medido
   - Un `SMTPRecipientsRefused` escribe el correo de la persona en el log (`infraestructura/correo.py:42`).
   - El access log de uvicorn guarda el query string: `GET /reservas/todas?q=…%40ejemplo.com` y `?q=39222333`, es decir,
     correo y DNI que busca el admin.
   - `interfaz/registro_errores.py:62-63` registra `scope["path"]` sin escapar: un `POST` sin token a
     `/reservas/1%0a2026-10-20 00:00:00,000 ERROR clubnahuelmosse.errores FALSO/cancelar` dejó una línea ERROR
     falsificada.
   - Ningún test manda un secreto (contraseña, token, código de recuperación) para verificar que no llegue al log.

10. **Consultas que crecen con la tabla** · P9, P11, K10 · falló · medido
    - `reserva.usuario_id` no tiene índice (`migraciones/versions/0001_modelo_inicial.py:151`): con 200 k reservas,
      `GET /reservas?cuando=historial` da Parallel Seq Scan.
    - El historial global pagina con `OFFSET`, hace dos `count(*)` por página y ordena en disco: 1,2 s en la página 500
      (`infraestructura/reservas.py:492-509`). El historial propio no tiene paginación (`:121-137`).
    - Tampoco tienen índice las FK `reserva.cancelada_por` y `notificacion.reemplazada_por`.

11. **La cola de avisos no se recupera** · P13 · falló · lectura
    - `infraestructura/notificaciones.py:228-239`: si el proceso cae entre `tomar_siguiente` y `marcar_envio`, el aviso
      queda en `enviando` para siempre; un recordatorio registrado y no enviado tampoco se reintenta (`:141-142`,
      `:232`).
    - Impacto: la trazabilidad del admin muestra «todavía no salió» indefinidamente.

12. **Se editaron migraciones que ya estaban en main** · P16 · falló · medido sobre git
    - `0007_aviso_de_cancelacion_forzosa.py` entró con 50a4b5a (en main desde 8e64a37) y 9d97cbb la editó después;
      `0001_modelo_inicial.py` entró con 68f6956 y b10fdfa la editó.
    - Impacto: una base que ya aplicó la versión vieja queda con otro esquema. El hook del kit 3.0.0 lo bloquea de acá
      en adelante.

13. **Migraciones no seguras en caliente** · P12, P5 · falló · lectura (ida y vuelta medida)
    - Ninguna tiene `lock_timeout`; los índices sobre tablas con datos se crean sin `CONCURRENTLY` (0004:16, 0005:71,
      0006:27, 0007:41-48), el CHECK de 0006:20-24 va sin `NOT VALID`, y todo corre en una transacción
      (`migraciones/env.py:14-16`) durante el build, con la versión anterior sirviendo.
    - La ida y vuelta 0001↔0007 con datos funciona (medido), pero ningún test la vigila. Los downgrade de 0003, 0005 y
      0007 borran tablas con datos.

14. **El error que ve la persona no tiene referencia y, con Render dormido, dice algo falso** · O21, E16 · falló · lectura
    - El 500 es «Internal Server Error» sin id, y el overlay (`apps/mobile/lib/comun/dialogo_error.dart:36-43`) no
      muestra ninguno.
    - Render tarda ~1 min en despertar y el cliente corta a los 15 s (`lib/api/cliente_api.dart:28`): se ve «Revisá tu
      conexión a internet». Retomar la sesión corta a los 3 s (`lib/sesion/sesion.dart:128`) y manda al login aunque la
      sesión siga viva.
    - Impacto: soporte no puede ubicar el caso, y el primer uso del día falla con un diagnóstico equivocado.

15. **No hay observabilidad de producción** · O6, O17, O19, O20, E13, E6, E12, E7 · falló · medido
    - Los pedidos no llevan id de correlación: `X-Request-ID` y `traceparent` se ignoran (`interfaz/registro_errores.py:47-59`).
    - Los errores no llevan la versión. No hay métricas, OpenTelemetry, SLOs ni alertas.
    - La app no instala `FlutterError.onError`, `PlatformDispatcher.onError` ni `runZonedGuarded`
      (`apps/mobile/lib/main.dart:15-46`), y traga errores sin rastro: `.ignore()` en
      `admin/pantalla_detalle_reserva.dart:55-60`, y `on Exception {}` en `notificaciones/centro.dart:189,210`,
      `admin/pantalla_editar_espacio.dart:78` e `inicio/pantalla_inicio.dart:141`.
    - Cada error no manejado se registra dos veces con el traceback completo (E12).
    - La API arranca «sana» sin base o sin esquema, y falla recién en el primer pedido (E7, `app/main.py:25-38`).

16. **Swagger abierto en producción y sin CSP** · W8, S7 · falló · lectura
    - `apps/api/app/main.py:43-47` no apaga `docs_url`, y `render.yaml:14` usa `/docs` como health check: una API interna
      con datos personales expone su mapa y un «Try it out».
    - No hay contrato OpenAPI versionado ni linteado. Ninguna respuesta trae `Content-Security-Policy` ni
      `frame-ancestors` (`interfaz/protecciones.py:5`); `/docs` carga JS de un CDN.

17. **El registro no muestra qué falta al enviar** · I22 · falló · medido
    - `apps/mobile/lib/usuarios/pantalla_registro.dart:67-68,117-119,331`: al salir de un campo vacío aparece el error,
      CREAR CUENTA está deshabilitado, y tocarlo con el formulario vacío muestra 0 errores.
    - Contradice CU-03 FA1 («presiona crear cuenta → se muestran los campos faltantes»). La edición de sede repite el
      patrón (`admin/pantalla_formulario_sede.dart:90-91,491`) y el alta no: dos formularios iguales se comportan
      distinto.

18. **Accesibilidad de formularios, avisos y diálogos** · I7, I20, I24, I9 · falló · medido
    - **I7:** el error de cada campo es un nodo aparte, y el formato esperado («DD / MM / AAAA») queda oculto para el
      lector (`lib/comun/campo_texto.dart:66-70,83-93,117-143`; igual en `selector.dart:104-129`). Afecta a todos los
      formularios.
    - **I20:** el rechazo de una reserva sale en un SnackBar de 4 s y la pantalla vuelve atrás al mismo tiempo
      (`lib/reservas/pantalla_confirmar_reserva.dart:93-96`, `pantalla_confirmar_cambio.dart:88-90`).
    - **I24:** en las confirmaciones irreversibles ningún botón tiene `autofocus` y el primer Tab cae en el destructivo
      (`lib/comun/dialogo_error.dart:316-345`).
    - **I9:** con el texto al 200 %, la barra inferior corta «RESERVAS» en «RESERV», y en el panel de admin «ESPACIOS»
      toca el borde (`lib/comun/barra_inferior.dart:137-141`).
    - I7, I20 e I24 salen de sondas de semántica y foco en widget tests; falta el recorrido real con TalkBack.

19. **El catálogo de deportes deja afuera Básquet** · R3 · falló · medido
    - `apps/api/app/dominio/espacios.py:90` y `specs/CU-21-alta-de-espacio/ambiguedades.md:43` (CU-21-SUP-04).
    - El enunciado lo da como ejemplo de tipo filtrable («Fútbol, Paddle, Básquet, etc.») y CU-13-AMB-09 lo preguntó;
      incluirlo servía con cualquier respuesta. `GET /espacios/catalogo` devuelve Futbol, Tenis, Padel, Voley, Hockey y
      Golf.

20. **La dirección de dependencias no está vigilada, y la app tiene ciclos** · D2, D3, K4, D11, D12 · falló · medido
    - `apps/api/tests/unit/test_arquitectura.py:38` sólo cubre dominio y aplicación; 10 módulos de `interfaz/` importan
      `infraestructura/` (por ejemplo `interfaz/reservas.py:32-34`) y nada lo detecta.
    - La app no tiene test de imports, y `PantallaRegistro` arma el pedido HTTP dentro del widget
      (`lib/usuarios/pantalla_registro.dart:132`).
    - En la app hay ciclos sesion↔reservas↔usuarios↔comun↔raíz (`lib/reservas/reservas.dart:4`,
      `sesion/pantalla_inicio_sesion.dart:4`, `comun/pantalla_acceso_denegado.dart:4`). La API no tiene ciclos.
    - Duplicación: la app tiene 5,86 % (79 clones) y la API 3,12 %, ambas sobre el 3 %. El mayor clon son 43 líneas
      entre `admin/pantalla_panel_admin.dart:646` y `reservas/pantalla_mis_reservas.dart:566`.
    - Hay repositorios que escriben tablas ajenas: `infraestructura/usuarios.py:112`, `reservas.py:300`, `sedes.py:180`.

21. **Falta la documentación que el grado production pide** · R10, D8, D9, D14, S15, S19, S21, S22, O13, O14, P14, W5,
    I15, I17, V5, R9 · falló · lectura
    - No existen: `specs/asvs.md` (matriz L2, que `.claude/tools/checks/security-l2.mjs` exige), `docs/technical/system-design.md`
      (STRIDE, dependencias con timeout y reintento, entornos, SLOs), ADRs, `THIRD_PARTY_NOTICES.md`, el modelo de
      costos, el runbook (rollback, rotación de secretos, incidentes), la declaración de accesibilidad y el registro de
      accesibilidad por pantalla.
    - El modelo de datos documentado (`specs/MOD-01-modelo-de-datos/data-model.md`) cubre 4 de 9 tablas.
    - No hay presupuesto de rendimiento ni de capacidad, ni la declaración de que no lo hay.

22. **Los supuestos no llegan a quien opera la app** · R4 · falló · lectura
    - Ninguno de los 545 supuestos está en `apps/api/README.md` ni en `apps/mobile/README.md`, y no hay README en la
      raíz. Por ejemplo: de 1 a 4 h y hasta 7 días de anticipación, el admin no reserva, catálogo fijo, sin pagos.
    - Están registrados como `SUP-NN`, no `ASM-NN`, y los snapshots usan `fuentes:` y `no_leido:` en vez de `sources:` y
      `not_read:`: las herramientas del kit 3.0.0 no los encuentran (`required.mjs`).

23. **La mutación no se pudo medir y algunos tests prometen más de lo que prueban** · T3, T2, T10, T5, T6, C3, P10 ·
    falló / no se pudo correr
    - **T3:** la suite de la API tarda de 178 a 475 s y `mutate.mjs` corta en 10 min. Los casos de uso de
      `aplicacion/reservas.py` no tienen unitarios. Además, sobre Python la herramienta no muta `==`, `!=`, `and`/`or`,
      `not` ni `is None`, y 7 de sus 23 mutantes caen en comentarios: no hay score de mutación en ningún archivo.
    - **T2:** a81ce1c bajó la cota de RNF-01-H06-02 de `>= 30` a `>= 25` con 28 medidas
      (`tests/escenarios/test_requisitos_no_funcionales.py:186`).
    - **T10:** `test_la_reserva_dura_entre_una_y_cuatro_horas` sólo prueba 5 h, y `test_la_baja_libera_el_correo_y_el_dni`
      nunca muestra el DNI bloqueado (`tests/integracion/test_restricciones.py:78,152`).
    - **T5, T6:** RNF-01-H04-01 lee el código Dart y el README con regex (`:56-68`, `:303-326`); 40 de 305 tests tienen
      lógica.
    - **C3:** sin el emulador de Auth los tests de API se saltan y la corrida sale verde (`tests/conftest.py:72-76`).
    - **P10:** ningún test cuenta consultas por pedido.

24. **El historial del método no cumple lo que el kit 3.0.0 pide** · V2, A1 · falló · medido sobre git
    - Planes commiteados después del código o junto con él: CU-09, TP-07, CU-15 y CU-03 (`git log --diff-filter=A`).
      Ningún plan tiene `## Bar`.
    - Los `tasks.md` marcan `[x]` sin la salida que lo respalde (`specs/CU-15-anular-reserva/tasks.md:3-16`).
    - Es historia anterior a la adopción del kit; cuenta para lo que se construya de acá en adelante.

### L

25. **Seguridad menor** · falló · medido
    - **S2:** se acepta un `Host` ajeno; con token, `Host: attacker.example` → 200/201 (`app/main.py:41-62`).
    - **Emulador de Auth:** con `FIREBASE_AUTH_EMULATOR_HOST` definido, firebase-admin acepta tokens sin firma (un JWT
      `alg none` con el uid del admin dio rol admin). Lo único que lo frena es que `render.yaml` no defina la variable;
      la API no se niega a arrancar si aparece junto a credenciales reales (`infraestructura/identidad.py:19-25`).
    - **Dispositivos:** `PUT /dispositivos` con el token FCM de otro reasigna el dispositivo
      (`infraestructura/notificaciones.py:294-297`). Hace falta conocer el token ajeno.
    - **S12:** MPL-2.0 (certifi) y LGPL-3.0 (psycopg) sin excepción escrita, y las fuentes OFL sin su licencia.
    - **S18:** sin bot de actualizaciones; go_router va 4 majors atrás (`apps/mobile/pubspec.yaml:15`).

26. **Operación menor** · O3, O16, O22, O24 · falló
    - `env_file=".env"` se resuelve contra el cwd (`app/config.py:8`, medido con dos cwd).
    - La versión está repetida a mano (`app/main.py:45`, `pyproject.toml:3`) y no hay tags.
    - No hay prueba de carga del camino caliente (p95 local de ~55 ms, con 4 filas).
    - No hay staging ni un artefacto único promovido (`lib/configuracion.dart:21-34`).

27. **Interfaz menor** · I1, I26 · falló
    - El botón `atenuado` en modo oscuro da 4,06:1 con 15 px en negrita, debajo de AA (`lib/comun/boton.dart:44-47`;
      GUARDAR SEDE y GUARDAR ESPACIO).
    - Las fechas y la plata se arman a mano: −3 h fijo, sin zona IANA, sin `DateFormat` con locale ni ISO 4217
      (`lib/reservas/fechas.dart`, `reservas.dart:110`). `lib/comun/calendario.dart:11` toma el día del dispositivo, no el
      del club.
    - 24 capturas commiteadas cambian al regenerarlas porque dependen de la fecha del día, y 6 de alta de espacio fallan
      a 320×568, sin analizar.

28. **Código menor** · K1, K5, D4, D5, R5, R8, T13 · falló
    - Hay 4 `# type: ignore[arg-type]` y `!` sin motivo (`tests/unit/test_espacios.py:31,78`, `test_sedes.py:21,94`,
      `lib/admin/historial_reservas.dart:33,66-72`), y mypy no llega a `tests/`.
    - `ANTICIPACION` está muerta (`dominio/notificaciones.py:16`): la regla de 1 h vive en SQL. La zona del club está
      repetida en 10 lugares.
    - Hay casos de uso que sólo reenvían al repositorio (`aplicacion/reservas.py:137,178`).
    - Hay preguntas con jerga técnica e IDs del método en los `ambiguedades.md`, y ningún plan tiene la sección de cambios
      a lo existente.

## Sin hallazgo

- Ninguna reserva, notificación, dispositivo ni endpoint de admin cedió a IDOR ni a escalada de rol. Un no-admin recibe
  403 en los 10 endpoints de admin.
- Los tokens vencidos, de otro proyecto o revocados dan 401. Al cambiar la contraseña o darse de baja, la sesión se
  revoca.
- Todo el SQL está parametrizado. `/_pruebas` está apagado sin el emulador. No hay secretos en los 327 commits.
- Atomicidad: un pedido cortado no deja nada a medias (E1, E2). Concurrencia: 6 reservas simultáneas sobre el mismo
  turno dejan una sola (E3). Reintentar es idempotente (E4).
- El apagado es ordenado (O4). Las respuestas no vuelcan filas enteras (P3). Hay FK en toda columna `_id` (P6).
- El contrato entre la API y la app no muestra diferencias en claves ni en enums (C4).

## Qué no se pudo correr

- La app en un dispositivo, los e2e en el emulador y TalkBack: R1, I6, I14, A6 y C1.
- La mutación (T3, E15), ZAP (S17), Sonar y la complejidad de Dart (K2, K3), las diez corridas para detectar
  intermitencias (T7, T8) y la cobertura (T11).
- La verificación real de firmas sin emulador, el límite TOO_MANY_ATTEMPTS de Firebase y el TLS hacia la base de Render.
- Los criterios que se miden sobre una card (R7, T1, T14, A2, A5, V6, V7, O11): esta revisión no tiene diff de card.

## CU sin cubrir por los tests

Se cruzaron los escenarios de los 32 snapshots con los tags de los tests versionados
(`apps/mobile/integration_test`, `apps/mobile/test`, `apps/api/tests`). Que un escenario figure como cubierto quiere
decir que su tag está en algún test. No se corrieron los e2e.

- **269 escenarios: 267 con test y 2 sin test.** No hay tags que apunten a un escenario inexistente. 31 de las 32 cards
  están completas.
- **CU-14 · Historial global de reservas:** 16 de 18.
  - `CU-14-H01-07`: anular desde el historial con confirmación y ver quién y cuándo la anuló.
  - `CU-14-H08-01`: cancelar la anulación y que la reserva quede igual (FA7 del CU).
  - Los dos se difirieron a CU-15 a propósito (CU-14-SUP-04, `specs/CU-14-historial-global-de-reservas/plan.md:42`), y
    los escenarios de CU-15 cubren la anulación desde el panel. Sin embargo, ningún test ejercita la anulación desde el
    detalle de CU-14 con su tag.
- **Flujo de un CU sin escenario:** CU-24.1 FA5, el reintento del envío. Su snapshot lo declara: el reintento lo hace el
  servicio de notificaciones del sistema operativo, no la app.
- **Cobertura sólo nominal:** `RNF-01-H06-01` (API y base en la nube) tiene test, pero se saltea sin `API_URL_NUBE`: el
  despliegue en Render no se hizo.
