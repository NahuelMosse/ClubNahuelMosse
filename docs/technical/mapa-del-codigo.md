# Mapa del código · ClubNahuelMosse

Dónde está cada cosa en el repo. La arquitectura (las piezas, cómo se hablan y por qué) está en
[`arquitectura.md`](arquitectura.md); acá van las carpetas, los archivos y qué tiene cada uno. Los símbolos se citan por
nombre, no por línea: buscalos con el buscador del editor.

## ¿Dónde está…?

| Busco | Está en |
|---|---|
| Las reglas de una reserva (1 a 4 horas, 7 días a la vista, horario de la sede) | `apps/api/app/dominio/horarios.py` (`validar_reserva`, `error_de_duracion`, `MIN_HORAS`, `MAX_HORAS`, `DIAS_A_LA_VISTA`) |
| Que dos reservas no se pisen | la restricción `EXCLUDE USING gist` de `apps/api/migraciones/versions/0001_modelo_inicial.py`, y `ReservasSql.insertar` en `apps/api/app/infraestructura/reservas.py`, que traduce el error `23P01` a `HorarioOcupado` |
| El caso de uso «reservar» | `apps/api/app/aplicacion/reservas.py` (`reservar`, `_con_la_agenda_vigente`) |
| Una ruta HTTP | `apps/api/app/interfaz/<recurso>.py`; la tabla completa está en [Rutas de la API](#rutas-de-la-api) |
| Quién es admin y dónde se controla | el rol viene de la tabla `usuario`; cada caso de uso de admin lanza `Prohibido` (por ejemplo `_solo_admin` en `aplicacion/espacios.py`); en la app, el `redirect` de `apps/mobile/lib/app.dart` sólo oculta pantallas |
| Cómo se valida el token de Firebase | `apps/api/app/interfaz/sesion.py` (`usuario_actual`) → `aplicacion/sesion.py` (`perfil_autenticado`) → `infraestructura/identidad.py` (`ProveedorFirebase.uid_del_token`) |
| La hora y la zona del club | API: `apps/api/app/dominio/zona.py` (`ZONA_CLUB`); app: `apps/mobile/lib/comun/zona_club.dart` (`ahoraEnElClub`, `enElClub`) |
| Los recordatorios de una hora antes | `apps/api/app/interfaz/barrido.py` (el reloj) → `aplicacion/notificaciones.py` (`enviar_recordatorios`, `entregar`) → `infraestructura/push.py` (FCM) |
| Los avisos de cancelación | se encolan en la misma transacción que cancela (`ReservasSql.cancelar` y `ReservasSql.anular`) y salen con `despachar_pendientes` |
| El correo de recuperación de contraseña | `aplicacion/recuperacion.py` (código, vigencia, tope por hora) e `infraestructura/correo.py` (SMTP o buzón) |
| Las variables de entorno de la API | `apps/api/app/config.py`; la tabla está en [Configuración de la API](#configuración-de-la-api) |
| El motor de la base y la conexión por pedido | `apps/api/app/infraestructura/db.py` |
| El esquema de la base | `apps/api/migraciones/versions/0001` a `0009`; el modelo explicado está en [`system-design.md`](system-design.md#data) |
| Una pantalla de la app | `apps/mobile/lib/<dominio>/pantalla_*.dart`; la tabla completa está en [Rutas de la app](#rutas-de-la-app) |
| Los colores, las fuentes y el tema | `apps/mobile/lib/tema/tokens.dart` (`Paleta.oscura`, `Paleta.clara`) y `tema/tema.dart` |
| Las animaciones y transiciones | `apps/mobile/lib/comun/movimiento.dart` y `comun/transiciones.dart` |
| Los componentes de la marca (dorsal, troquel, marcador…) | `apps/mobile/lib/comun/`; ver [Componentes de la app](#componentes-de-la-app) |
| Cómo la app llama a la API | `apps/mobile/lib/api/cliente_api.dart` (`ClienteApi`) y `api/rutas.dart` (las rutas permitidas) |
| Los diálogos de error | `apps/mobile/lib/comun/dialogo_error.dart` (`atenderErrorDeRed`, `MarcoDeDialogo`) |
| Las `--dart-define` de la app | `apps/mobile/lib/comun/configuracion.dart` |
| El push en el teléfono | `apps/mobile/lib/notificaciones/centro.dart` (`CentroDeNotificaciones`) y `sistema_fcm.dart` |
| El requisito de cada funcionalidad | `specs/<CU-NN-nombre>/card.snapshot.md` (las cards nuevas, `card.md`); los casos de uso originales están fuera del repo, en `../CU/` |
| Qué test prueba un escenario | buscá su tag (`@CU-09-H02-02`, `@REV-01-S12`) en `apps/api/tests` y `apps/mobile` |
| Cómo correr todo | `sh scripts/test.sh` (chequeos y tests) y `sh scripts/e2e.sh` (pantallas en el emulador) |

## El repo

```
app-tp/
├── apps/
│   ├── api/                 API REST: FastAPI + SQL a mano sobre PostgreSQL
│   │   ├── app/             código (dominio, aplicacion, infraestructura, interfaz)
│   │   ├── migraciones/     Alembic, 0001 a 0009
│   │   ├── tests/           unit, integracion, escenarios
│   │   ├── openapi.json     el contrato publicado, versionado (un test lo compara con la API)
│   │   ├── pyproject.toml   dependencias (uv), ruff y mypy
│   │   └── README.md        configurar, correr, probar y desplegar la API
│   └── mobile/              app Flutter, sólo Android
│       ├── lib/             código, una carpeta por dominio
│       ├── test/            tests de widgets, accesibilidad y capturas
│       ├── integration_test/ escenarios en el emulador contra la API real
│       ├── assets/          fuentes, fotos de sedes, ícono
│       ├── android/         proyecto Android (firma, deep link, ícono)
│       └── README.md        --dart-define, correr y construir el APK
├── docs/
│   ├── technical/           arquitectura, este mapa, diseño del sistema, runbook, costos
│   ├── adr/                 decisiones: stack (0001) y hosting en Render (0002)
│   └── business/            declaración de accesibilidad
├── specs/                   una carpeta por card: requisito, supuestos, tests y cierre
├── scripts/                 test.sh, e2e.sh
├── render.yaml              blueprint de Render: la API y su base
├── firebase.json            emulador de Firebase Auth (puerto 9099)
├── package.json             sólo para `npm run emuladores` (firebase-tools)
└── .claude/                 el kit de método (SDD): reglas, agentes, hooks y herramientas
```

## La API (`apps/api`)

### Capas

```
interfaz  ──►  aplicacion  ──►  dominio
    │                              ▲
    └──► dependencias.py ──► infraestructura
```

- **`dominio/`**: reglas puras. Sólo importa la biblioteca estándar y `app.dominio`.
- **`aplicacion/`**: casos de uso. Cada módulo declara los `Protocol` de repositorio que necesita; no importa
  infraestructura ni interfaz.
- **`infraestructura/`**: SQL con `text()` sobre una `Connection` de SQLAlchemy (no hay ORM ni modelos), Firebase y
  correo. Cada repositorio escribe sólo sus tablas.
- **`interfaz/`**: rutas FastAPI, middleware y comandos. Las rutas reciben cada repositorio y servicio con `Depends`
  desde los proveedores de `app/dependencias.py` (`repositorio_reservas`, `repositorio_sedes`, …, `identidad`) y no
  construyen nada de infraestructura; un test los reemplaza con `app.dependency_overrides`. Los comandos de consola
  (`barrido.py`, `sembrar_admin.py`) no tienen pedido HTTP y arman sus piezas ellos mismos.

Los tests de `tests/unit/test_arquitectura.py`, `test_capas.py`, `test_capas_integracion.py` y
`test_repositorios_inyectados.py` hacen cumplir estas reglas: qué importa cada capa, qué tablas escribe cada repositorio
(`TABLAS_PROPIAS`), que ninguna ruta construya infraestructura, que no haya `type: ignore`, que la zona del club se defina
una sola vez y que `ANTICIPACION` salga del dominio.

### Por funcionalidad

El código se agrupa por capa y no por funcionalidad: las reglas de dependencia se comprueban por carpeta, y cada
funcionalidad tiene un archivo con el mismo nombre en cada capa. Para trabajar sobre una funcionalidad, estos son sus
archivos (todos bajo `apps/api/app/`, y la carpeta de la app bajo `apps/mobile/lib/`):

| Funcionalidad | `interfaz/` | `aplicacion/` | `dominio/` | `infraestructura/` | App |
|---|---|---|---|---|---|
| Reservas | `reservas.py` | `reservas.py`, `almacen_de_reservas.py` | `reservas.py` | `reservas.py` | `reservas/` |
| Horarios y canchas libres | `horarios.py` | `horarios.py`, `disponibilidad.py` | `horarios.py` | `horarios.py` | `reservas/` |
| Sedes | `sedes.py` | `sedes.py` | `sedes.py` | `sedes.py` | `sedes/`, `admin/` |
| Espacios (canchas) | `espacios.py` | `espacios.py` | `espacios.py` | `espacios.py` | `espacios/`, `admin/` |
| Cuentas y perfil | `registro.py`, `sesion.py`, `sembrar_admin.py` | `registro.py`, `sesion.py`, `perfil.py`, `baja.py`, `contrasena.py`, `administradores.py` | `usuarios.py` | `usuarios.py`, `identidad.py`, `credencial_firebase.py` | `sesion/`, `usuarios/` |
| Recuperar la contraseña | `recuperacion.py` | `recuperacion.py` | `recuperacion.py` | `enlaces.py`, `correo.py` | `sesion/` |
| Avisos y notificaciones | `notificaciones.py`, `barrido.py` | `notificaciones.py`, `almacen_de_avisos.py` | `notificaciones.py` | `notificaciones.py`, `push.py` | `notificaciones/` |
| Transversal | `entradas.py`, `errores_http.py`, `respuestas.py`, `salud.py`, `cuerpo.py` | `errores.py` | `errores.py`, `zona.py` | `db.py` | `api/`, `comun/`, `tema/` |

### Archivo por archivo

**Raíz de `app/`**

| Archivo | Qué tiene |
|---|---|
| `main.py` | `crear_app()`: arma la app, los handlers de error y los routers; `_ciclo_de_vida` (el barrido en segundo plano) |
| `config.py` | `Config` (pydantic-settings), lee el entorno y `apps/api/.env` |
| `dependencias.py` | el único paso de `interfaz` a `infraestructura`: reexporta repositorios, `conexion`, `motor`, `canal_push` y `enviar_correo` |

**`dominio/`**

| Archivo | Qué tiene |
|---|---|
| `errores.py` | las excepciones del negocio: `DatosInvalidos`, `Duplicado`, `NoAutenticado`, `Demorado`, `CuentaExistente`, `Prohibido`, `NoDisponible`, `NumeroOcupado`, `HorarioOcupado`, `NoEncontrada`, `Cambiado`, `ReservasAfuera`, `AgendaCambiada`, `ConReservasFuturas` |
| `zona.py` | `ZONA_CLUB`, la única definición de `America/Argentina/Buenos_Aires` |
| `horarios.py` | `Agenda`, `Franja`, `Grilla`, `grilla`, `rango`, `validar_rango`, `error_de_duracion`, `validar_reserva`; `MIN_HORAS`, `MAX_HORAS`, `DIAS_A_LA_VISTA` |
| `reservas.py` | `Reserva`, `ReservaHistorial`, `TandaDeReservas`, `FiltrosHistorial`, `Contadores`, `HistorialDeReservas`, `POR_PAGINA` |
| `sedes.py` | `DatosSede`, `SedeNueva`, `Sede`, `validar_sede` |
| `espacios.py` | el catálogo fijo de deportes y tipos (`Deporte`, `Tipo`), `nombre_compuesto`, `validar_espacio`, `validar_cambio`, `PRECIO_MAXIMO` |
| `usuarios.py` | `DatosRegistro`, `Registro`, `Perfil`, `validar_registro`, `validar_edicion`, `normalizar_correo`, `normalizar_dni`, `problemas_contrasena` |
| `notificaciones.py` | `ANTICIPACION` (1 h), `Aviso`, `Pendiente`, `Recordatorio`, el protocolo `CanalPush` y los textos de cada aviso |
| `recuperacion.py` | `Mensaje`, `Destinatario`, `EnlaceReclamado` |

**`aplicacion/`** (un módulo por caso de uso o grupo)

| Archivo | Casos de uso |
|---|---|
| `sesion.py` | `perfil_autenticado`: del token al `Perfil` |
| `registro.py` | `registrar` |
| `perfil.py` | `editar_perfil` |
| `contrasena.py` | `cambiar_contrasena` |
| `baja.py` | `dar_de_baja` (la cuenta) |
| `recuperacion.py` | `pedir_enlace`, `enlace_vigente`, `usar_enlace`, `hash_de` |
| `sedes.py` | `sedes_activas`, `dar_de_alta_sede`, `editar_sede`, `dar_de_baja_sede` |
| `espacios.py` | `catalogo`, `nombre_sugerido`, `espacios_activos`, `dar_de_alta_espacio`, `editar_espacio`, `dar_de_baja_espacio` |
| `horarios.py` | `horarios_disponibles` (la grilla de un espacio) |
| `disponibilidad.py` | `canchas_disponibles` (buscar cancha por deporte, día y hora) |
| `reservas.py` | `reservar`, `mis_reservas`, `cancelar_reserva`, `modificar_reserva`, `historial_global`, `detalle_admin`, `anular_reserva` |
| `notificaciones.py` | `enviar_recordatorios`, `despachar_pendientes`, `entregar`, `registrar_dispositivo`, `dar_de_baja_dispositivo`, `mis_notificaciones`, `marcar_leida`, `marcar_todas` |
| `administradores.py` | `sembrar_admin` |
| `errores.py` | reexporta los errores del dominio |

**`infraestructura/`**

| Archivo | Qué tiene | Tablas que escribe |
|---|---|---|
| `db.py` | el motor, `conexion()` (una conexión por pedido), `en_transaccion`, `restriccion_violada` | — |
| `usuarios.py` | `UsuariosSql` | `usuario` |
| `sedes.py` | `SedesSql` | `sede` |
| `espacios.py` | `EspaciosSql`, `espacio_de_fila` | `espacio` |
| `horarios.py` | `HorariosSql` (lecturas para la grilla y la búsqueda) | — |
| `reservas.py` | `ReservasSql`: insertar, cancelar, modificar, anular, historial paginado por cursor | `reserva` |
| `notificaciones.py` | `NotificacionesSql` (cola de avisos, dispositivos, centro de avisos) y `encolar_cancelacion_forzosa` | `notificacion`, `notificacion_reserva`, `dispositivo` |
| `enlaces.py` | `EnlacesSql` | `enlace_recuperacion` |
| `correo.py` | `enviar`: SMTP con STARTTLS verificado, o el buzón de desarrollo | `correo_saliente` (sólo en modo buzón) |
| `identidad.py` | `ProveedorFirebase`: verificar tokens, comprobar contraseñas, crear y borrar cuentas | — |
| `push.py` | `canal_push`, `CanalFcm`, `CanalNulo`, `armar_mensaje` | — |
| `credencial_firebase.py` | `credencial_de_servicio`: la cuenta de servicio desde el JSON o el archivo | — |

**`interfaz/`**

| Archivo | Qué tiene |
|---|---|
| `salud.py` | `/health` (el proceso vive) |
| `registro.py`, `sesion.py`, `recuperacion.py` | cuentas, perfil y contraseña; `sesion.py` define `usuario_actual`, la dependencia de autenticación |
| `sedes.py`, `espacios.py`, `horarios.py`, `reservas.py`, `notificaciones.py` | las rutas de cada recurso |
| `pruebas.py` | `/_pruebas/*`: atajos para los e2e; sólo se monta con `PRUEBAS=true` y el emulador |
| `entradas.py` | tipos acotados para los cuerpos (`Texto40`, `Clave`, `Identificador`…), `leer_hora` y el handler de 422 y 400 |
| `errores_http.py` | handlers de `DatosInvalidos` (422 con `errores`), `Prohibido` (403) y `NoEncontrada` (404), los tres iguales en toda la API |
| `respuestas.py` | `conflicto`: el 409 con `errores` que cada ruta elige |
| `barrido.py` | el barrido de recordatorios y avisos: en proceso (`barrer_cada`) o una pasada (`--una-vez`) |
| `sembrar_admin.py` | comando para crear o promover el primer administrador |

### Rutas de la API

«Sesión» quiere decir cualquier cuenta con token válido. Las rutas de admin piden sesión y el caso de uso responde 403
si el rol no es `admin`.

| Método y ruta | Archivo | Caso de uso | Quién |
|---|---|---|---|
| GET `/health` | `salud.py` | — | cualquiera |
| GET `/openapi.json` | FastAPI | — | cualquiera (también `/docs` y `/redoc`) |
| POST `/registro` | `registro.py` | `registrar` | cualquiera |
| POST `/recuperacion` | `recuperacion.py` | `pedir_enlace` | cualquiera |
| POST `/recuperacion/consulta` | `recuperacion.py` | `enlace_vigente` | cualquiera |
| PUT `/recuperacion` | `recuperacion.py` | `usar_enlace` | cualquiera |
| GET `/enlace/recuperar` | `recuperacion.py` | página que abre la app desde el correo | cualquiera |
| GET `/yo` | `sesion.py` | — | sesión |
| PUT `/yo` | `sesion.py` | `editar_perfil` | sesión |
| PUT `/yo/contrasena` | `sesion.py` | `cambiar_contrasena` | sesión |
| DELETE `/yo` | `sesion.py` | `dar_de_baja` | sesión |
| GET `/sedes` | `sedes.py` | `sedes_activas` | sesión |
| POST `/sedes` | `sedes.py` | `dar_de_alta_sede` | admin |
| PUT `/sedes/{sede_id}` | `sedes.py` | `editar_sede` | admin |
| DELETE `/sedes/{sede_id}` | `sedes.py` | `dar_de_baja_sede` | admin |
| GET `/espacios/catalogo` | `espacios.py` | `catalogo` | sesión |
| GET `/espacios` | `espacios.py` | `espacios_activos` | sesión |
| GET `/espacios/nombre` | `espacios.py` | `nombre_sugerido` | admin |
| POST `/espacios` | `espacios.py` | `dar_de_alta_espacio` | admin |
| PUT `/espacios/{espacio_id}` | `espacios.py` | `editar_espacio` | admin |
| DELETE `/espacios/{espacio_id}` | `espacios.py` | `dar_de_baja_espacio` | admin |
| GET `/espacios/{espacio_id}/horarios` | `horarios.py` | `horarios_disponibles` | sesión |
| GET `/espacios/disponibles` | `horarios.py` | `canchas_disponibles` | sesión |
| GET `/reservas` | `reservas.py` | `mis_reservas` | sesión |
| POST `/reservas` | `reservas.py` | `reservar` | usuario (admin: 403) |
| POST `/reservas/{id}/cancelar` | `reservas.py` | `cancelar_reserva`, después despacha el aviso | usuario, sólo sus reservas (una ajena da 404) |
| POST `/reservas/{id}/modificar` | `reservas.py` | `modificar_reserva` | usuario |
| GET `/reservas/todas` | `reservas.py` | `historial_global` | admin |
| GET `/reservas/todas/{id}` | `reservas.py` | `detalle_admin` | admin |
| POST `/reservas/{id}/anular` | `reservas.py` | `anular_reserva`, después despacha el aviso | admin |
| PUT `/dispositivos` | `notificaciones.py` | `registrar_dispositivo` | usuario |
| POST `/dispositivos/baja` | `notificaciones.py` | `dar_de_baja_dispositivo` | sesión |
| GET `/notificaciones` | `notificaciones.py` | `mis_notificaciones` | sesión |
| POST `/notificaciones/leer-todas` | `notificaciones.py` | `marcar_todas` | sesión |
| POST `/notificaciones/{id}/leer` | `notificaciones.py` | `marcar_leida` | sesión |

### Configuración de la API

`config.py` lee estas variables del entorno o de `apps/api/.env` (que no se versiona; `.env.example` las lista sin valores).

| Variable | Por defecto | Para qué |
|---|---|---|
| `DATABASE_URL` | `postgresql+psycopg://club:club@localhost:5432/club` | la base; la usan la API y las migraciones |
| `FIREBASE_PROJECT_ID` | `demo-clubnahuelmosse` | el proyecto que emite los tokens |
| `FIREBASE_API_KEY` | vacío | comprobar contraseñas por REST (el emulador no la necesita) |
| `FIREBASE_CREDENCIALES_JSON` | vacío | la cuenta de servicio; sin ella el push queda en el canal nulo |
| `URL_PUBLICA` | `http://localhost:8000` | el host de los enlaces del correo |
| `CORREO_MODO` | `smtp` | `buzon` guarda los correos en la tabla `correo_saliente` (sólo desarrollo) |
| `SMTP_HOST`, `SMTP_PUERTO` (587), `SMTP_USUARIO`, `SMTP_CONTRASENA`, `CORREO_REMITENTE` | vacíos | el correo saliente |
| `RECORDATORIOS_CADA` | 30 | segundos entre barridos; 0 apaga el barrido en proceso |
| `PRUEBAS` | false | montar `/_pruebas` (sólo junto al emulador) |
| `VERSION` | la del `pyproject.toml` | lo que informan `/health` y el log |

Fuera de `Config`: `FIREBASE_AUTH_EMULATOR_HOST` (emulador de Auth), `GOOGLE_APPLICATION_CREDENTIALS` (cuenta de servicio
por archivo), `ADMIN_CONTRASENA` (sólo `sembrar_admin`) y `TEST_DATABASE_URL` (sólo tests).

### Migraciones

| N.º | Qué hace |
|---|---|
| 0001 | `usuario`, `sede`, `espacio`, `reserva`, la vista `reserva_con_estado`, la exclusión de superposición y los triggers de baja lógica e inmutabilidad |
| 0002 | `usuario.contrasena_cambiada_en` |
| 0003 | `enlace_recuperacion` y `correo_saliente` |
| 0004 | nombre de sede único entre las activas |
| 0005 | `dispositivo`, `notificacion` y el índice de reservas activas por inicio |
| 0006 | estados de envío y un aviso de cancelación por reserva |
| 0007 | `notificacion_reserva` (avisos agrupados), `cantidad` y `reemplazada_por` |
| 0008 | índices de historial creados con `CONCURRENTLY`, e `intentos` y `tomada_en` para retomar avisos varados |
| 0009 | quita `intentos` y `tomada_en` (los avisos no se reintentan), agrega `enviando_desde` y los que estaban `enviando` pasan a `fallida` |

Se corren con `uv run alembic upgrade head` desde `apps/api`. Una migración que ya está en `main` no se edita: se agrega
otra.

### Tests de la API

| Carpeta | Qué cubre | Necesita |
|---|---|---|
| `tests/unit/` | reglas del dominio, casos de uso con dobles, las reglas de capas y la configuración | nada |
| `tests/integracion/` | cada área por HTTP (`test_<área>_api.py`), restricciones de la base y rutas protegidas | base `*_test` y emulador de Auth |
| `tests/escenarios/` | los escenarios de cada card, con su tag en el nombre (`@CU-09-H02-02`, `@REV-01-S12`), el contrato publicado, las migraciones y el `render.yaml` | base `*_test` y emulador de Auth |

`tests/conftest.py` exige que la base termine en `_test`, la recrea desde cero con Alembic una vez por corrida y envuelve
cada test en una transacción que se descarta. Para correr sólo una card: `uv run pytest tests/escenarios --card <ID>`.

## La app (`apps/mobile`)

### Cómo está armada

- **Una carpeta por dominio** (`sesion`, `usuarios`, `inicio`, `sedes`, `espacios`, `reservas`, `notificaciones`,
  `admin`), más `api` (el cliente HTTP), `tema` (colores y tipografía) y `comun` (componentes y utilidades compartidas).
- **Sin gestor de estado de terceros.** Cada dominio tiene un repositorio (`Sedes`, `Espacios`, `Horarios`, `Reservas`,
  `HistorialDeReservas`, `Recuperacion`) sobre un único `ClienteApi`. `_AppState` los crea en `app.dart` y los pasa por
  constructor a cada pantalla, que es un `StatefulWidget` con `setState`. Los que cambian solos (`Sesion`,
  `CentroDeNotificaciones`, `Apariencia`) son `ChangeNotifier`.
- **Navegación con `go_router`**, todas las rutas en `app.dart`, con un `redirect` global por rol.
- `test/arquitectura_test.dart` vigila la estructura.

### Archivo por archivo

**Raíz de `lib/`**

| Archivo | Qué tiene |
|---|---|
| `main.dart` | `main()` y `arrancar()`: captura de errores, Firebase, cliente, sesión, push, apariencia; retoma la sesión con reintento y lanza `App` |
| `app.dart` | `App`: crea los repositorios, define todas las rutas y el `redirect` por rol, escucha los toques en avisos push y arma `MaterialApp.router` |

**`api/`**

| Archivo | Qué tiene |
|---|---|
| `cliente_api.dart` | `ClienteApi` (get, post, put, delete), `Respuesta` y los errores `SinConexion`, `ErrorDelServidor`, `ServidorSinRespuesta`; el corte por pedido |
| `rutas.dart` | la lista de rutas de la API que la app puede pedir; en debug, un pedido a una ruta no declarada falla |

**`sesion/`**

| Archivo | Qué tiene |
|---|---|
| `sesion.dart` | `Sesion` (iniciar, retomar, refrescar, editar perfil, cambiar contraseña, baja, cerrar, `token()`), `Perfil`, `Rol`, `CredencialesFirebase` y sus errores |
| `firebase.dart` | `iniciarFirebase`, con el emulador si hay `AUTH_EMULADOR` |
| `pantalla_inicio_sesion.dart` | el login |
| `pantalla_recuperar_contrasena.dart` | pedir el correo de recuperación |
| `pantalla_nueva_contrasena.dart` | la contraseña nueva desde el enlace del correo |
| `recuperacion.dart` | `Recuperacion`, el repositorio de los tres pasos |
| `pantalla_acceso_denegado.dart` | lo que ve un usuario que llega a una ruta de admin |
| `tarjeta_cuenta.dart` | el botón y la tarjeta de la cuenta, `cerrarSesion` |
| `fallo_de_carga.dart` | `avisarFalloDeCarga`, `avisarFalloDeEnvio` |

**`usuarios/`**: `pantalla_registro.dart`, `pantalla_registro_exitoso.dart`, `registro.dart` (`RegistroServicio`),
`pantalla_mi_perfil.dart` (datos, edición, modo oscuro, baja de la cuenta) y `pantalla_cambiar_contrasena.dart`.

**`inicio/`**: `pantalla_inicio.dart`, el Home: marcador, próxima reserva, deportes y accesos.

**`sedes/`**

| Archivo | Qué tiene |
|---|---|
| `sede.dart` | `Sede`, `DiasQueAbre` |
| `sedes.dart` | `Sedes` (repositorio) y sus errores |
| `pantalla_sedes.dart` | el listado, con `TarjetaSede` |
| `pantalla_sede.dart` | una sede con sus canchas, filtros y `TarjetaCancha` |
| `fotos.dart` | `portadaDeSede`, `fotoDeDeporte`, `FotoConVelo` |

**`espacios/`**: `espacio.dart` (`Espacio`, `Deporte`, `TipoDeCancha`, `Catalogo`), `espacios.dart` (repositorio y
errores) e `iconos.dart`.

**`reservas/`**

| Archivo | Qué tiene |
|---|---|
| `reservas.dart` | `Reserva`, `EstadoDeReserva`, `Reservas` (repositorio) y sus errores |
| `horarios.dart` | `Horarios` (repositorio), `Grilla`, `Franja` |
| `eleccion.dart` | `Eleccion`: lo elegido antes de confirmar; viaja en el `extra` de la ruta |
| `pantalla_horarios.dart` | la grilla de una cancha (también para modificar una reserva) |
| `pantalla_confirmar_reserva.dart` | el resumen antes de reservar |
| `pantalla_confirmar_cambio.dart` | el resumen antes de modificar |
| `pantalla_reserva_confirmada.dart` | el festejo con el comprobante |
| `pantalla_mis_reservas.dart` | próximas e historial, con `TarjetaReserva` |
| `pantalla_buscar_cancha.dart` | buscar por deporte, día y hora |
| `reglas_busqueda.dart`, `fechas.dart` | reglas y formato de fechas |
| `cancelacion.dart` | `cancelarConAvisos`, `abrirModificar` |

**`notificaciones/`**

| Archivo | Qué tiene |
|---|---|
| `centro.dart` | `CentroDeNotificaciones`: registra el dispositivo, consulta periódicamente con la app abierta y lleva los no leídos |
| `notificaciones.dart` | `Notificaciones` (repositorio) |
| `notificacion.dart` | `Notificacion`, `rutaDelAviso` (adónde lleva tocar un aviso) |
| `sistema.dart` | `SistemaDeNotificaciones` (interfaz) y `SistemaSimulado` |
| `sistema_fcm.dart` | `SistemaFcm`: permiso, token, avisos tocados con la app cerrada o en segundo plano |
| `campana.dart`, `panel_avisos.dart`, `tarjeta_aviso.dart`, `pantalla_notificaciones.dart` | la campana, el panel superpuesto, la tarjeta y la pantalla de avisos |

**`admin/`**

| Archivo | Qué tiene |
|---|---|
| `pantalla_panel_admin.dart` | reservas de todos, por pestañas |
| `pantalla_detalle_reserva.dart` | el detalle con la trazabilidad |
| `pantalla_filtros_reservas.dart` | el panel de filtros |
| `historial_reservas.dart` | `HistorialDeReservas` (repositorio paginado), filtros y contadores |
| `anular_reserva.dart`, `dialogo_anular_reserva.dart` | anular con motivo |
| `pantalla_sedes_admin.dart`, `pantalla_formulario_sede.dart`, `pantalla_sede_creada.dart`, `baja_sede.dart` | sedes |
| `pantalla_espacios_admin.dart`, `pantalla_alta_espacio.dart`, `pantalla_editar_espacio.dart`, `pantalla_espacio_creado.dart`, `baja_espacio.dart` | espacios |
| `baja.dart` | lo común a las dos bajas |
| `listado_admin.dart`, `estado_reserva_chip.dart` | piezas de los listados |

**`tema/`**: `tokens.dart` (`Paleta`, una `ThemeExtension` con roles `bg*`, `text*`, `border*`, `accent*`, `state*`;
`Paleta.oscura` y `Paleta.clara`; se lee con `context.paleta`) y `tema.dart` (`temaOscuro`, `temaClaro`).

**`comun/`**

| Grupo | Archivos |
|---|---|
| Arranque y errores | `configuracion.dart` (`--dart-define`), `errores_no_manejados.dart`, `dialogo_error.dart`, `snackbar.dart`, `apariencia.dart` |
| Navegación y movimiento | `barra_inferior.dart`, `barra_superior.dart`, `transiciones.dart`, `movimiento.dart` |
| Formularios | `boton.dart`, `campo_texto.dart`, `selector.dart`, `calendario.dart`, `faltantes.dart`, `formulario_contrasena.dart`, `reglas_contrasena.dart`, `reglas_registro.dart`, `formato_fecha.dart`, `formato_precio.dart` |
| Marca | `isotipo.dart`, `marcador.dart`, `tile_deporte.dart`, `ficha_socio.dart`, `linea_del_dia.dart`, `dorsal.dart`, `troquel.dart` |
| Otros widgets | `avatar.dart`, `estado_vacio.dart`, `etiqueta.dart`, `insignia.dart`, `marco_de_tarjeta.dart`, `resultado.dart` (`PantallaResultado`), `tarjeta_reserva.dart` |
| Lógica sin pantalla | `zona_club.dart`, `reloj.dart`, `reserva_pendiente.dart` (la reserva que queda pendiente si venció la sesión) |

### Rutas de la app

Todas en `lib/app.dart`. «Avanza» entra desde la derecha; «raíz» cambia sin animación (las pestañas); «resultado» funde.

| Ruta | Pantalla | Transición | Quién |
|---|---|---|---|
| `/` | `PantallaInicioSesion` | raíz | cualquiera |
| `/registro` | `PantallaRegistro` | avanza | cualquiera |
| `/registro/exitoso` | `PantallaRegistroExitoso` | resultado | cualquiera |
| `/recuperar-contrasena` | `PantallaRecuperarContrasena` | avanza | cualquiera |
| `/recuperar?codigo=` | `PantallaNuevaContrasena` (enlace `clubnahuelmosse://app/recuperar`) | avanza | cualquiera |
| `/inicio` | `PantallaInicio` | raíz | usuario |
| `/inicio/buscar` | `PantallaBuscarCancha` | avanza | usuario |
| `/notificaciones` | `PantallaNotificaciones` | avanza | usuario |
| `/perfil` | `PantallaMiPerfil` | raíz | usuario |
| `/perfil/contrasena` | `PantallaCambiarContrasena` | avanza | usuario |
| `/sedes` | `PantallaSedes` | raíz | usuario |
| `/sedes/:sede` | `PantallaSede` | avanza | usuario |
| `/sedes/:sede/canchas/:cancha` | `PantallaHorarios` | avanza | usuario |
| `/sedes/:sede/canchas/:cancha/reservar` | `PantallaConfirmarReserva` (pide la `Eleccion` en `extra`) | avanza | usuario |
| `/reservar` | `PantallaConfirmarReserva` para la reserva pendiente tras volver a iniciar sesión | avanza | usuario |
| `/reservas` | `PantallaMisReservas` | raíz | usuario |
| `/reservas/:reserva/modificar` | `PantallaHorarios` en modo modificar | avanza | usuario |
| `/reservas/:reserva/modificar/confirmar` | `PantallaConfirmarCambio` | avanza | usuario |
| `/reservas/confirmada` | `PantallaReservaConfirmada` | resultado | usuario |
| `/admin` | `PantallaPanelAdmin` | raíz | admin |
| `/admin/reserva/:id` | `PantallaDetalleReserva` | avanza | admin |
| `/admin/acceso-denegado` | `PantallaAccesoDenegado` | avanza | cualquiera con sesión |
| `/admin/sedes` | `PantallaSedesAdmin` | raíz | admin |
| `/admin/sedes/nueva` y `/admin/sedes/:sede/editar` | `PantallaFormularioSede` | avanza | admin |
| `/admin/sedes/creada` | `PantallaSedeCreada` | resultado | admin |
| `/admin/espacios` | `PantallaEspaciosAdmin` | raíz | admin |
| `/admin/espacios/nuevo` | `PantallaAltaEspacio` | avanza | admin |
| `/admin/espacios/:espacio/editar` | `PantallaEditarEspacio` | avanza | admin |
| `/admin/espacios/creado` | `PantallaEspacioCreado` | resultado | admin |

- **El `redirect`**: sin sesión, todo lo que no es público vuelve a `/`. Un usuario en `/admin/…` va a
  `/admin/acceso-denegado`; un admin en una ruta de usuario va a su inicio.
- **Las rutas con `extra`** (confirmar, modificar, detalle, pantallas de «creada») vuelven a su listado si se abren sin
  él, por ejemplo desde un enlace o al reabrir la app.
- **Las pestañas** no son un `ShellRoute`: cada pantalla raíz pone su `BarraInferior` (usuario: Inicio, Sedes, Reservas,
  Perfil) o `BarraAdmin` (Reservas, Sedes, Espacios) y navega con `context.go`.

### Configuración de la app

`lib/comun/configuracion.dart` lee las `--dart-define`:

| Define | Para qué |
|---|---|
| `API_URL` | la dirección de la API; obligatoria (el emulador de Android ve la máquina en `http://10.0.2.2:8000`) |
| `AUTH_EMULADOR` | `host:puerto` del emulador de Firebase Auth; con él no hacen falta las claves de Firebase y el push es simulado |
| `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_SENDER_ID`, `FIREBASE_PROJECT_ID` | el proyecto real de Firebase; obligatorias sin `AUTH_EMULADOR` |
| `PUSH` | `simulado` fuerza el push de mentira |
| `AVISOS_SEGUNDOS` | cada cuánto consulta avisos con la app abierta (20 s; 2 s con el emulador) |

### Componentes de la app

| Componente | Archivo | Dónde se usa |
|---|---|---|
| `Isotipo` | `comun/isotipo.dart` | login, ficha de socio |
| `Marcador` | `comun/marcador.dart` | inicio, ficha de socio |
| `TileDeporte` | `comun/tile_deporte.dart` | inicio |
| `FichaSocio` | `comun/ficha_socio.dart` | perfil |
| `LineaDelDia` | `comun/linea_del_dia.dart` | horarios |
| `DorsalGigante` | `comun/dorsal.dart` | sedes, ficha de socio |
| `Troquel` | `comun/troquel.dart` | mis reservas, reserva confirmada |
| `PantallaResultado` | `comun/resultado.dart` | sede y espacio creados, contraseña nueva, recuperación |
| `Festejo` | `comun/movimiento.dart` | reserva confirmada |
| `Aparecer`, `EntradaEscalonada`, `Temblor`, `PulsoDeExito`, `Latido`, `Presionable` | `comun/movimiento.dart` | entradas de pantallas, errores de formulario, confirmaciones, botones |
| `MarcoDeDialogo` | `comun/dialogo_error.dart` | todos los diálogos |

Las duraciones y curvas están en `Movimiento` (`comun/movimiento.dart`). Con «quitar animaciones» del sistema
(`MediaQuery.disableAnimationsOf`), todo dura cero.

### Tests de la app

| Carpeta | Qué cubre | Cómo se corre |
|---|---|---|
| `test/` | pantallas y flujos con la API falsa: reservar, cancelar, modificar, admin, sesión, errores de red, accesibilidad | `flutter test` |
| `test/rediseno/` | paleta, componentes de la marca, transiciones y movimiento | `flutter test` |
| `test/admin/` | panel y detalle del admin | `flutter test` |
| `test/capturas/` | capturas de cada pantalla en 360 y 430 px, claro y oscuro, para compararlas con el Figma; no afirman nada | `flutter test --update-goldens test/capturas/<archivo>_capturas.dart` |
| `integration_test/` | los escenarios de los casos de uso en el emulador Android, contra la API real y el emulador de Auth | `sh scripts/e2e.sh [integration_test/<área>]` |

Ayudas en `test/soporte/`:

- `montar.dart`: `apiRutas`, una API falsa que responde por ruta y registra los pedidos, y `montar`.
- `reloj_fijo.dart`: un `testWidgets` con el reloj congelado el jueves 12/11/2026 a las 15:00 del club.
- `usuario.dart` y `admin.dart`: montan la app con sesión de usuario o de admin, con datos de ejemplo.

En `integration_test/soporte/`, `acciones.dart` tiene `abrirApp`, `entrarComoUsuario` y `entrarComoAdmin`, y `red.dart`
tiene una API intermedia para simular cortes.

## Scripts (`scripts/`)

| Script | Qué hace |
|---|---|
| `test.sh` | ruff, mypy y pytest de la API; `flutter analyze`, `dart format` y `flutter test` de la app |
| `e2e.sh` | levanta el emulador de Auth y la API sobre una base `*_test` propia, migra, siembra un admin y corre `integration_test` en el emulador Android |

Comandos de la API: `python -m app.interfaz.sembrar_admin` (crear o promover el primer administrador) y
`python -m app.interfaz.barrido --una-vez` (una pasada de recordatorios y avisos).

## `specs/` y el método de trabajo

Cada funcionalidad es una **card** con su carpeta en `specs/`:

| Prefijo | Qué son |
|---|---|
| `CU-NN` | los casos de uso del enunciado (iniciar sesión, reservar, anular…) |
| `RNF-01`, `MOD-01`, `TP-NN` | requisitos no funcionales, modelo de datos y pedidos puntuales del trabajo práctico |
| `REV-NN`, `INT-01` | las correcciones de la revisión de `specs/REVISION-kit3.md` y su integración |
| `RED-NN` | el rediseño: paleta, componentes, pantallas y movimiento |

Las carpetas tienen dos formatos, según la versión del método con que se hizo la card:

| Cards | Archivos |
|---|---|
| `CU-NN`, `RNF-01`, `MOD-01`, `TP-NN` | `card.snapshot.md` (el requisito congelado), `ambiguedades.md` (dudas y supuestos), `plan.md` y `tasks.md` (las tareas con sus tests); `MOD-01` suma `data-model.md` |
| `REV-NN`, `INT-01`, `RED-NN` | `card.md` (requisito, escenarios `S1…`, supuestos `ASM-NN`, tareas con sus tests y el registro), `ambiguities.md`, `risk.json`, `judge.md` (la revisión del plan en riesgo alto) y `closing.md` (el cierre: qué pasó y qué no se pudo correr) |

`specs/TRAZABILIDAD.md` cruza los casos de uso con sus tests y `specs/asvs.md` es la matriz de seguridad. El método está en
`.claude/METHOD.md` y el stack con sus comandos en `.claude/STACK.md`.
