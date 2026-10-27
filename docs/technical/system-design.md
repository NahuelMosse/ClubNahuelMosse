# Diseño del sistema · ClubNahuelMosse

Describe el sistema como está en `main`: modelo de datos, infraestructura, observabilidad, errores, dependencias externas,
amenazas, secretos, datos personales y presupuesto de rendimiento. Cada afirmación cita su archivo, un test o un comando;
lo que no se verificó dice `not verified`. Los números de hallazgo remiten a la revisión de la rama `kit-3`
(`specs/REVISION-kit3.md`); las cards `REV-01` a `REV-08` los corrigieron y lo que sigue abierto lo dice cada fila. La
arquitectura y los flujos están en [`arquitectura.md`](arquitectura.md), dónde está cada archivo en
[`mapa-del-codigo.md`](mapa-del-codigo.md), las decisiones en `docs/adr/`, los precios en
[`infra-cost.md`](infra-cost.md) y los pasos operativos en el [runbook](runbook.md). Cada servicio externo y dónde se integra: [`integraciones.md`](integraciones.md).

## Context and containers (C4)

```mermaid
C4Context
  Person(socio, "Socio del club", "Reserva espacios deportivos desde el teléfono")
  Person(admin, "Administrador", "Gestiona sedes, espacios y reservas")
  System(app, "ClubNahuelMosse", "Reservas de espacios deportivos: app móvil y API")
  System_Ext(auth, "Firebase Authentication", "Cuentas, contraseñas y tokens de sesión")
  System_Ext(fcm, "Firebase Cloud Messaging", "Avisos push a los teléfonos")
  System_Ext(correo, "Servidor de correo saliente", "Enlaces de recuperación de contraseña")
  Rel(socio, app, "usa")
  Rel(admin, app, "usa")
  Rel(app, auth, "inicia sesión")
  Rel(app, fcm, "recibe avisos")
```

```mermaid
C4Container
  Container(movil, "App móvil", "Flutter, Dart ^3.9.2, sólo Android", "Pantallas, sesión, avisos")
  Container(api, "API", "FastAPI, Python 3.12, uvicorn", "Reglas de reservas, sedes, espacios, perfiles y avisos")
  ContainerDb(db, "Base de datos", "PostgreSQL, extensión btree_gist", "Usuarios, sedes, espacios, reservas, avisos")
  System_Ext(auth, "Firebase Authentication", "Cuentas y tokens")
  System_Ext(fcm, "Firebase Cloud Messaging", "Push")
  System_Ext(correo, "Servidor SMTP", "Correo saliente")
  Rel(movil, api, "HTTPS/JSON, token de Firebase en Authorization")
  Rel(movil, auth, "HTTPS, firebase_auth")
  Rel(api, db, "SQL, psycopg")
  Rel(api, auth, "HTTPS, firebase-admin e Identity Toolkit")
  Rel(api, fcm, "HTTPS, firebase-admin")
  Rel(api, correo, "SMTP con STARTTLS verificado, puerto 587")
```

Dentro de la API (`apps/api/app`): una carpeta por funcionalidad en `modules/` (cada una con `rutas.py`,
`casos_de_uso.py`, `reglas.py` y `repositorio.py`) y `shared/` para lo común (base, errores, Firebase, zona). La regla
de capas la hacen cumplir `tests/unit/test_arquitectura_funcionalidades.py` y
`tests/unit/test_capas_funcionalidades.py`. El barrido de recordatorios corre como tarea de
fondo dentro del proceso web (`app/main.py`, `_ciclo_de_vida`) y también como comando de una pasada
(`python -m app.modules.notificaciones.barrido --una-vez`).

## Data

El modelo de datos (tablas, columnas, relaciones, estados, índices, migraciones) vive en [modelo-de-datos.md](modelo-de-datos.md). PostgreSQL con `btree_gist`, nueve tablas y una vista. Sin política de retención: las bajas son lógicas y los avisos, enlaces y correos no vencen (una persona tiene que fijar los plazos, ver `## Personal data`). Sin backups automáticos: la base `free` de Render no trae copias, vence a los 30 días y se borra 14 días después (`render.yaml`); RPO y RTO no definidos.

## Infrastructure

- **Deployment diagram:**

```mermaid
flowchart LR
  telefono["Teléfono Android: app Flutter"] -->|HTTPS| web["Render web service clubnahuelmosse-api (plan free)"]
  web -->|SQL| pg["Render Postgres clubnahuelmosse-db (plan free)"]
  web -->|HTTPS| fb["Firebase: Authentication y Cloud Messaging"]
  web -->|SMTP 587| smtp["Servidor de correo"]
  telefono -->|HTTPS| fb
```

- **Environments:** hay dos, local y Render; no hay staging.
  - **local:** la API con `uvicorn` contra una Postgres local y el emulador de Firebase Auth (`firebase.json`, puerto 9099,
    `npm run emuladores`), `CORREO_MODO=buzon`, sin credenciales de Firebase: el canal push es el nulo
    (`modules/notificaciones/push.py`, `CanalNulo`). La app apunta a `http://10.0.2.2:8000` con `AUTH_EMULADOR`. Los tests usan
    una base `*_test` (`apps/api/README.md`, «Probar»).  - **Render:** `render.yaml` define el web service Python `clubnahuelmosse-api` y la base `clubnahuelmosse-db`, ambos
    `plan: free`, y es la única fuente de la configuración del despliegue. El despliegue no se hizo todavía: el
    escenario RNF-01-H06-01 se saltea sin `API_URL_NUBE`. El health check es `/health`, que no toca la base ni Firebase (`salud.py`).
- **Deploy and rollback:** el despliegue sale solo con cada commit de la rama enlazada; la vuelta atrás de código es redeploy
  del commit anterior. Pasos en el runbook.
- **Expected scaling:** una instancia web sin escalado automático ni más de un proceso. Lo primero que se agota es el pool
  de conexiones de SQLAlchemy (5 más 5 de desborde, los valores por defecto). Antes pueden agotarse la CPU y la memoria
  del plan free (`not verified`: los límites de la instancia free no se consultaron). El barrido de recordatorios vive en el mismo proceso y se detiene cuando Render
  duerme el servicio; el comando `--una-vez` está listo para un cron, pero `render.yaml` no define ninguno (el plan free
  no tiene cron jobs).
- **Secrets:** inventario en `## Secrets inventory`; en Render viven como variables de entorno de `render.yaml` marcadas
  `sync: false`.
- **Cost:** [`infra-cost.md`](infra-cost.md).

## Observability

- **SLOs.** Son objetivos propuestos, sin medir: no hay medición en producción que los respalde. El de latencia es
  coherente con el p95 local de unos 55 ms con 4 filas (hallazgo 26). El de disponibilidad no se cumple con el plan free:
  el servicio se duerme a los 15 minutos sin tráfico y tarda alrededor de un minuto en despertar.

| Service | SLI | Objective | Window | Error-budget policy (actions on exhaustion, approver) |
|---|---|---|---|---|
| API | SLO de disponibilidad: pedidos que no terminan en 5xx sobre el total | 99,0 % | 30 días | pendiente de una persona: quién aprueba y qué se detiene al agotarlo |
| API | SLO de latencia: pedidos de lectura que responden en 300 ms o menos, medidos en el servidor, sin el arranque en frío | 95 % | 30 días | pendiente de una persona |

- **Signals per service:** `/health` y el log de uvicorn. No hay métricas ni un servicio que las consulte.
- **Log schema.** El log de uvicorn y del módulo `logging` a la salida estándar. SQLAlchemy oculta los parámetros
  (`hide_parameters=True`), así que no llevan correo, DNI, tokens ni contraseñas.
- **App:** `lib/comun/errores_no_manejados.dart` engancha `FlutterError.onError` y `PlatformDispatcher.onError` y los
  registra con `debugPrint`. No hay un servicio de reporte de fallos (Crashlytics u otro).
- **Alerts as code:** ninguna. **Dashboards:** ninguno.

## Errors

Taxonomía de la API. Las excepciones del negocio están en `app/shared/errores.py`; las rutas las traducen a HTTP con
`shared/respuestas.py`.

| Error | Class (domain, operational, bug) | Comes from | Translated to | What the user sees | Reference id |
|---|---|---|---|---|---|
| `DatosInvalidos`, `NoDisponible` | domain | casos de uso | 422 con `{"errores": {campo: mensaje}}` | el mensaje junto al campo | no |
| `Duplicado`, `HorarioOcupado`, `Cambiado`, `NumeroOcupado`, `ConReservasFuturas`, `ReservasAfuera` | domain | casos de uso | 409 con `{"errores": ...}` | el mensaje del conflicto | no |
| `Prohibido` | domain | casos de uso (`perfil.rol`) | 403 sin cuerpo | acceso denegado | no |
| `NoEncontrada` | domain | casos de uso | 404 sin cuerpo | no encontrado | no |
| `NoAutenticado` | domain | `perfil_autenticado` | 401 con `WWW-Authenticate: Bearer` | vuelve al inicio de sesión | no |
| `Demorado` | operational | Firebase (`TOO_MANY_ATTEMPTS`) | 429 | pedir que reintente más tarde | no |
| JSON mal formado, dato fuera de rango o faltante | domain | validación de FastAPI (`shared/entradas.py`) | 422 con `{"errores": {campo: mensaje}}`, sin repetir lo recibido | el mensaje junto al campo | no |
| Base caída, cualquier otra excepción | bug | cualquier capa | 500 | «Ocurrió un error.» | no |

## External dependencies

Una fila por llamada externa. Los tiempos salen del código; lo que el código no fija se declara así.

| Dependency | Timeout | Retries (backoff, jitter, idempotent only) | Circuit breaker | Fallback | What happens if it fails |
|---|---|---|---|---|---|
| PostgreSQL (`app/shared/db.py`) | los valores por defecto del driver y del pool | sin reintentos; `pool_pre_ping=True` comprueba la conexión antes de usarla | no | ninguno | si falla, el pedido responde 500 |
| Firebase Authentication: SDK de administración y API REST de Identity Toolkit (`identidad.py`) | SDK: `httpTimeout` de 4 s; REST: `timeout=4` s de `urllib`; la verificación de la firma de un token, `not verified` | SDK: el cliente de `firebase-admin` reintenta una vez ante errores de conexión o de lectura y hasta 4 veces ante 500 o 503, con espera exponencial; REST: ninguno | no | ninguno | si falla, un token inválido, vencido o revocado da 401; si Firebase no responde, el pedido da 500; `TOO_MANY_ATTEMPTS` da 429; crear cuenta o cambiar contraseña falla el pedido |
| Firebase Cloud Messaging (`push.py`) | `httpTimeout` de 10 s | el cliente de `firebase-admin` (arriba); un aviso `fallida` no se reintenta | no | sin credenciales, el canal nulo deja el aviso como `sin_canal` | si falla, el aviso queda `fallida` y la persona lo ve igual en el centro de avisos de la app; el token que FCM rechaza como inválido se da de baja; la reserva no cambia |
| SMTP (`app/modules/recuperacion/correo.py`) | 10 s | sin reintentos | no | ninguno | si falla, el error va al log sin la dirección y la respuesta es la misma que para un correo sin cuenta; la persona no recibe el enlace y puede pedir otro. STARTTLS con `ssl.create_default_context()`: verifica certificado y nombre |
| Firebase Authentication desde la app (`firebase_auth`) | la app corta cada pedido a la API a los 30 s (`lib/api/cliente_api.dart`); al retomar la sesión, 3 s (`lib/sesion/sesion.dart`) | ninguno automático; cada pantalla ofrece reintentar | no | ninguno | si falla, se ve el aviso de error de red con reintento; retomar la sesión sin red no la cierra |

## Threat model

Cuatro superficies.

**Surface:** API HTTP · **Enters:** JSON de las rutas, cabecera `Authorization: Bearer <token de Firebase>` · **Trust boundary:** el borde de Render hacia el proceso `uvicorn`

| ID | STRIDE | Threat | Decision (mitigate, eliminate, transfer, accept) | Owner | Verified by (test or command) |
|---|---|---|---|---|---|
| T-01 | Spoofing | alguien se hace pasar por otra cuenta con un token falso, vencido, de otro proyecto o revocado | mitigate: `verify_id_token` con `check_revoked=True` (`identidad.py`); la API no arranca con el emulador junto a credenciales reales o un proyecto que no es de demo | autor del repo | `tests/integracion/test_sesion_api.py`, `tests/escenarios/test_seguridad_api.py` (`@REV-01-S18`) |
| T-02 | Tampering | pedido con cuerpo mal formado, campos de más, números fuera de rango o NUL en un texto | mitigate: la validación de FastAPI y Pydantic, que responde 422 sin repetir lo recibido (`shared/entradas.py`) | autor del repo | `tests/escenarios/test_seguridad_cuerpo.py` |
| T-03 | Repudiation | una persona niega haber cancelado o anulado una reserva | mitigate: `cancelada_por`, `cancelada_en` y `motivo` en `reserva`; el log por pedido con el usuario y la referencia | autor del repo | `tests/integracion/test_anular_reserva_api.py` |
| T-04 | Information disclosure | consultar si un DNI o un correo ya están registrados, o leer reservas ajenas | mitigate lo segundo (las consultas filtran por dueño: una reserva ajena da 404); accept lo primero: `POST /registro` y `PUT /yo` responden 409 con el campo repetido, porque la persona necesita saber qué corregir | autor del repo | `tests/escenarios/test_seguridad_api.py` |
| T-05 | Denial of service | ráfagas de pedidos | accept: la API no limita la frecuencia; sólo Firebase frena los intentos de contraseña (`Demorado`, 429) | autor del repo | `not verified` |
| T-06 | Elevation of privilege | un usuario común llama a una ruta de administrador | mitigate: `perfil.rol` en cada caso de uso de admin; 403 en todas las rutas de administrador | autor del repo | `tests/integracion/test_rutas_protegidas.py` |

**Surface:** app móvil · **Enters:** lo que escribe la persona, los enlaces de recuperación, los avisos push · **Trust boundary:** el teléfono

| ID | STRIDE | Threat | Decision (mitigate, eliminate, transfer, accept) | Owner | Verified by (test or command) |
|---|---|---|---|---|---|
| T-07 | Spoofing | otra app abre el enlace de recuperación del correo | mitigate: el código va después del «#» y no llega al servidor; vigencia de 30 minutos y un solo uso (`modules/recuperacion/casos_de_uso.py`) | autor del repo | `tests/integracion/test_recuperacion_api.py` |
| T-08 | Tampering | modificar el APK o las claves que lleva | accept: las `--dart-define` de Firebase son identificadores públicos del proyecto, no secretos; el APK `release` se firma con la clave de depuración mientras no se configure otra (`apps/mobile/README.md`) | autor del repo | `not verified` |
| T-09 | Repudiation | la app no deja rastro de sus fallos | mitigate en parte: `errores_no_manejados.dart` captura los errores no manejados, pero sólo los imprime en el teléfono | autor del repo | `not verified` |
| T-10 | Information disclosure | datos de la sesión en el teléfono | mitigate: `shared_preferences` guarda sólo la apariencia, el permiso de avisos y el token de FCM; el perfil no se guarda; la sesión la guarda `firebase_auth` | autor del repo | `not verified` (no se inspeccionó el almacenamiento del teléfono) |
| T-11 | Denial of service | el servicio dormido hace fallar el primer uso del día | accept: la app espera hasta 30 s y ofrece reintentar | autor del repo | `not verified` |
| T-12 | Elevation of privilege | la app muestra pantallas de administrador a quien no lo es | mitigate: el rol se decide en la API; la app sólo oculta | autor del repo | `lib/sesion/pantalla_acceso_denegado.dart`; `not verified` en un dispositivo |

**Surface:** base de datos · **Enters:** SQL parametrizado de los repositorios · **Trust boundary:** el proceso de la API hacia Postgres de Render

| ID | STRIDE | Threat | Decision (mitigate, eliminate, transfer, accept) | Owner | Verified by (test or command) |
|---|---|---|---|---|---|
| T-13 | Spoofing | alguien usa las credenciales de la base | mitigate: la URL llega por variables de Render, no está en el repo | autor del repo | revisión de la rama `kit-3` («Sin hallazgo»: sin secretos en los commits) |
| T-14 | Tampering | inyección SQL; edición o borrado directo de filas | mitigate: todo el SQL está parametrizado; triggers `prohibir_borrado` y de inmutabilidad; restricciones CHECK | autor del repo | `tests/integracion/test_restricciones.py` |
| T-15 | Repudiation | no queda quién creó o cambió una sede o un espacio | mitigate: columnas `creado_por`, `modificado_por`, `dado_de_baja_por` | autor del repo | `migraciones/versions/0001_modelo_inicial.py` |
| T-16 | Information disclosure | la base y sus datos personales se pierden o se filtran; el TLS hacia la base de Render no se probó | accept en parte: el DNI y el nacimiento se guardan en claro (sin cifrado de columnas); el cifrado en reposo es el de Render (`not verified`) | autor del repo | `not verified` |
| T-17 | Denial of service | un corte de red con la base cuelga los pedidos | accept: sin tiempos propios; vale lo del driver y el pool | autor del repo | `not verified` |
| T-18 | Elevation of privilege | el usuario de la app tiene DDL completo | accept: la API usa el usuario dueño de la base | autor del repo | `not verified` |

**Surface:** correo de recuperación y avisos push (integraciones salientes) · **Enters:** el correo de la persona y el contenido del aviso · **Trust boundary:** el borde de la API hacia el servidor de correo y Firebase

| ID | STRIDE | Threat | Decision (mitigate, eliminate, transfer, accept) | Owner | Verified by (test or command) |
|---|---|---|---|---|---|
| T-19 | Spoofing | un servidor de correo falso recibe el usuario, la contraseña y los enlaces | mitigate: STARTTLS con verificación de certificado y nombre; con un certificado inválido no se entregan las credenciales | autor del repo | `tests/escenarios/test_seguridad_api.py` (`@REV-01-S1`) |
| T-20 | Tampering | alguien reutiliza o falsifica un enlace de recuperación | mitigate: sólo se guarda el hash SHA-256 del código; un solo uso; el código es `secrets.token_urlsafe(32)` | autor del repo | `tests/integracion/test_recuperacion_api.py` |
| T-21 | Repudiation | no queda registro de qué aviso salió | mitigate: `notificacion.envio`, `enviada_en`, `leida_en` | autor del repo | `migraciones/versions/0005_notificaciones.py` |
| T-22 | Information disclosure | el correo de una cuenta aparece en el log, o se averigua si existe | mitigate: la respuesta es la misma tenga cuenta o no; el log del correo lleva el asunto y el tipo de error, no la dirección | autor del repo | `tests/integracion/test_recuperacion_api.py`, `tests/escenarios/test_seguridad_api.py` (`@REV-01-S11`) |
| T-23 | Denial of service | pedir recuperación de la contraseña sin freno | mitigate: tope de 3 enlaces por hora y cuenta | autor del repo | `tests/integracion/test_recuperacion_api.py` |
| T-24 | Elevation of privilege | reasignar el dispositivo de otra persona con su token de FCM | mitigate: un token activo de otra cuenta no cambia de dueño; la baja de un token ajeno no hace nada | autor del repo | `tests/escenarios/test_seguridad_api.py` (`@REV-01-S19`) |

Cada `mitigate` nombra su test o su evidencia; cada `accept` tiene dueño y motivo. «Autor del repo» es el único dueño que el
repo tiene hoy; asignar a otra persona queda pendiente de una persona.

## Secrets inventory

Nombres y lugares, nunca valores. Quién es dueño de cada secreto, y las fechas de creación y de la última rotación, lo
decide una persona: quedan pendientes de una persona y no se inventan. Los pasos de rotación están en el runbook.

| Name | Purpose | Consumer | Owner | Where it lives per environment | Privileges | Created | Rotation | Last rotation |
|---|---|---|---|---|---|---|---|---|
| `DATABASE_URL` | conexión a la base como dueño; la usan la API y las migraciones | API y build | pendiente de una persona | local: `.env` (no se versiona) o el entorno; Render: la entrega la base por `fromDatabase` | dueño del esquema, con DDL | `not verified` | pendiente de una persona | `not verified` |
| `FIREBASE_CREDENCIALES_JSON` | cuenta de servicio de Firebase: crear y borrar usuarios, verificar tokens, enviar push | API | pendiente de una persona | local: ausente, se usa el emulador; Render: variable `sync: false` | administración del proyecto de Firebase | `not verified` | pendiente de una persona | `not verified` |
| `GOOGLE_APPLICATION_CREDENTIALS` | ruta a la misma cuenta de servicio | API y comando de siembra | pendiente de una persona | sólo del entorno del proceso, nunca del `.env` | las mismas | `not verified` | pendiente de una persona | `not verified` |
| `FIREBASE_API_KEY` | clave web del proyecto para comprobar contraseñas | API | pendiente de una persona | Render: `sync: false` | identificador público del proyecto | `not verified` | pendiente de una persona | `not verified` |
| `SMTP_CONTRASENA` | contraseña de la cuenta de correo saliente | API | pendiente de una persona | Render: `sync: false` | enviar correo con la cuenta | `not verified` | pendiente de una persona | `not verified` |
| `SMTP_USUARIO`, `SMTP_HOST`, `CORREO_REMITENTE` | cuenta, servidor y remitente del correo | API | pendiente de una persona | Render: `sync: false` | no son secretos por sí solos | `not verified` | no aplica | `not verified` |
| `ADMIN_CONTRASENA` | contraseña de la cuenta de administrador, sólo para sembrarla | comando `sembrar_admin` | pendiente de una persona | el entorno de quien corre el comando; no vive en Render | cuenta de administrador | `not verified` | pendiente de una persona | `not verified` |
| `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_SENDER_ID`, `FIREBASE_PROJECT_ID` de la app | datos de la app Android registrada en Firebase | app móvil | pendiente de una persona | `--dart-define` al construir; quedan dentro del APK | públicos por diseño de Firebase | `not verified` | no aplica | `not verified` |
| `URL_PUBLICA` | dirección pública de la API | API | pendiente de una persona | Render: `sync: false` | no es un secreto | `not verified` | no aplica | `not verified` |

`scripts/e2e.sh` trae una contraseña de administrador de prueba que sólo existe en el emulador de la corrida de
pantallas. `apps/api/.env.example` lista estas variables sin valores.

## Personal data

Contexto: Ley 25.326 de Protección de los Datos Personales (Argentina). La base legal y los plazos de retención los decide
una persona; lo que sigue es lo que el sistema hace hoy.

| Field | Of whom | Category (identifying, sensitive) | Purpose | Legal basis or consent | Where it lives (tables, logs, backups, third parties) | Retention | How it is deleted |
|---|---|---|---|---|---|---|---|
| nombre, apellido (`usuario.nombre`, `usuario.apellido`) | socios y administradores | identifying | identificar a la persona en el club | pendiente de una persona (consentimiento al registrarse: `not verified`) | `usuario`; Firebase no los guarda | sin plazo | no se borra: baja lógica |
| DNI (`usuario.dni`) | socios y administradores | identifying | impedir cuentas duplicadas y buscar socios | pendiente de una persona | `usuario`; el log no lo guarda (sin query string) | sin plazo; la baja libera el DNI para otra cuenta | no se borra: baja lógica |
| fecha de nacimiento (`usuario.fecha_nacimiento`) | socios y administradores | identifying | requisito del perfil del enunciado | pendiente de una persona | `usuario` | sin plazo | no se borra |
| correo (`usuario.correo`) | socios y administradores | identifying | iniciar sesión y recuperar la contraseña | pendiente de una persona | `usuario`, Firebase Authentication, el servidor de correo y `correo_saliente` en modo buzón; no va al log | sin plazo | la baja borra la cuenta de Firebase (`modules/usuarios/baja.py`); en la base queda |
| contraseña | socios y administradores | sensitive | autenticar | pendiente de una persona | sólo en Firebase Authentication; la base guarda `contrasena_cambiada_en` | la gestiona Firebase | la baja borra la cuenta de Firebase |
| token de dispositivo (`dispositivo.token`) | socios | identifying | enviar avisos | permiso del sistema operativo guardado en `dispositivo.permiso` | `dispositivo`; Firebase Cloud Messaging | sin plazo; se da de baja al cerrar sesión | baja lógica |
| reservas y avisos (`reserva`, `notificacion`) | socios | identifying | historial y recordatorios | pendiente de una persona | `reserva`, `notificacion`, `notificacion_reserva` | sin plazo; el historial se conserva a propósito | no se borra |
| código de recuperación | quien lo pide | sensitive | recuperar la cuenta | no aplica | `enlace_recuperacion.codigo_hash` (sólo el hash) | vence a los 30 minutos | no se borra la fila |

Hoy ningún dato personal se borra de la base: el trigger `prohibir_borrado` lo impide y el derecho de supresión de la
Ley 25.326 no tiene camino. Cómo resolverlo lo decide una persona.

Cifrado en reposo: lo da la plataforma de Render para la base (`not verified`: no se consultó su documentación). El DNI y el
nacimiento no tienen cifrado de columna.

## Performance and capacity budget

Presupuesto de rendimiento y de capacidad. Son objetivos propuestos, sin medir: no hay prueba de carga del camino caliente
(hallazgo 26).

- **Presupuesto de latencia (p95):** 300 ms en el servidor para las lecturas (`GET /sedes`, `/espacios`, `/horarios`,
  `/reservas`) y 500 ms para las escrituras (`POST /reservas`, cancelaciones), sin contar el arranque en frío de Render. Lo
  único medido es un p95 local de unos 55 ms con 4 filas.
- **Capacidad objetivo:** 20 personas con sesión activa a la vez y 10 pedidos simultáneos, el tope del pool (5 más 5 de
  desborde). Con los índices de 0008, el historial propio y el global no recorren la tabla entera: el cuello es el pool.
- **Operaciones costosas:** el historial global del administrador (dos `count(*)` por los contadores), el barrido de
  recordatorios cada 30 s y el envío de avisos por FCM, que corren en el mismo proceso web.
- **Qué falta:** una prueba de carga del camino caliente; mientras no exista, estos números no están respaldados por una
  medición.
