# Mapa del código · ClubNahuelMosse

Dónde está cada cosa en el repo. La arquitectura (las piezas, cómo se hablan y por qué) está en
[`arquitectura.md`](arquitectura.md); acá van las carpetas, los archivos y qué tiene cada uno. Los símbolos se citan por
nombre, no por línea: buscalos con el buscador del editor.

## ¿Dónde está…?

| Busco | Está en |
|---|---|
| Las reglas de una reserva (1 a 4 horas, 7 días a la vista, horario de la sede) | `apps/api/app/modules/horarios/reglas.py` (`validar_reserva`, `error_de_duracion`, `MIN_HORAS`, `MAX_HORAS`, `DIAS_A_LA_VISTA`) |
| Que dos reservas no se pisen | la restricción `EXCLUDE USING gist` de `apps/api/migraciones/versions/0001_modelo_inicial.py`, y `ReservasSql.insertar` en `apps/api/app/modules/reservas/repositorio.py`, que traduce el error `23P01` a `HorarioOcupado` |
| El caso de uso «reservar» | `apps/api/app/modules/reservas/casos_de_uso.py` (`reservar`) |
| Una ruta HTTP | `apps/api/app/modules/<funcionalidad>/rutas.py`; la tabla completa está en [Rutas de la API](#rutas-de-la-api) |
| Quién es admin y dónde se controla | el rol viene de la tabla `usuario`; cada caso de uso de admin lanza `Prohibido`; en la app, el `redirect` de `apps/mobile/lib/redireccion.dart` sólo oculta pantallas |
| Cómo se valida el token de Firebase | `apps/api/app/modules/sesion/usuario_actual.py` (`usuario_actual`) → `sesion/casos_de_uso.py` (`perfil_autenticado`) → `shared/identidad.py` (`ProveedorFirebase.uid_del_token`) |
| La hora y la zona del club | API: `apps/api/app/shared/club_timezone.py` (`CLUB_TIMEZONE`); app: `apps/mobile/lib/comun/zona_club.dart` (`ahoraEnElClub`, `enElClub`) |
| Los recordatorios de una hora antes | `apps/api/app/modules/notificaciones/barrido.py` (el reloj) → `casos_de_uso.py` (`enviar_recordatorios`, `entregar`) → `push.py` (FCM) |
| Los avisos de cancelación | se encolan en la misma transacción que cancela (`ReservasSql.cancelar` y `ReservasSql.anular`) y salen con `despachar_pendientes` |
| El correo de recuperación de contraseña | `apps/api/app/modules/recuperacion/casos_de_uso.py` (código, vigencia, tope por hora) y `correo.py` (SMTP o buzón) |
| Las variables de entorno de la API | `apps/api/app/shared/config.py`; la tabla está en [Configuración de la API](#configuración-de-la-api) |
| El motor de la base y la conexión por pedido | `apps/api/app/shared/db.py` |
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
│   │   ├── app/             código: main.py, shared/ y modules/ (una carpeta por funcionalidad)
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

### Estructura

El código se agrupa por funcionalidad: una carpeta por funcionalidad bajo `app/modules/`, plana, con los archivos que
necesita entre `rutas.py` (HTTP), `casos_de_uso.py` (orquestación), `reglas.py` (reglas puras) y `repositorio.py`
(SQL con `text()` sobre una `Connection` de SQLAlchemy, sin ORM). Lo compartido está en `app/shared/` y arriba quedan
`main.py`, `health.py` y `e2e_support.py`.

- Una funcionalidad importa a otra sólo por su `__init__.py`, y no hay ciclos.
- `shared/` no importa funcionalidades; `reglas.py` no importa base de datos ni web; los casos de uso no importan
  `repositorio` ni `rutas`.
- Las rutas reciben el repositorio con `Depends` desde el proveedor de su propio `repositorio.py`
  (`repositorio_reservas`, …); un test lo reemplaza con `app.dependency_overrides`. Los comandos (`barrido.py`,
  `sembrar_admin.py`) arman sus piezas ellos mismos.
- Cada repositorio escribe sólo sus tablas.

Los tests de `tests/unit/test_arquitectura_funcionalidades.py`, `test_capas_funcionalidades.py`,
`test_api_limpia_funcionalidades.py` y `test_mapa_por_funcionalidad.py` hacen cumplir estas reglas.

### Por funcionalidad

Archivos de cada funcionalidad (bajo `apps/api/app/modules/<funcionalidad>/`) y la carpeta de la app bajo
`apps/mobile/lib/`:

| Funcionalidad | Archivos | App |
|---|---|---|
| `reservas` | `rutas.py`, `casos_de_uso.py`, `almacen.py`, `reglas.py`, `repositorio.py` | `reservas/` |
| `horarios` | `rutas.py`, `casos_de_uso.py`, `disponibilidad.py`, `reglas.py`, `repositorio.py` | `reservas/` |
| `sedes` | `rutas.py`, `casos_de_uso.py`, `reglas.py`, `repositorio.py` | `sedes/`, `admin/` |
| `espacios` | `rutas.py`, `casos_de_uso.py`, `reglas.py`, `repositorio.py` | `espacios/`, `admin/` |
| `usuarios` | `rutas_registro.py`, `rutas_cuenta.py`, `registro.py`, `perfil.py`, `contrasena.py`, `baja.py`, `administradores.py`, `sembrar_admin.py`, `reglas.py`, `repositorio.py` | `usuarios/` |
| `sesion` | `casos_de_uso.py`, `perfil.py`, `usuario_actual.py`, `repositorio.py` | `sesion/` |
| `recuperacion` | `rutas.py`, `casos_de_uso.py`, `reglas.py`, `repositorio.py`, `correo.py` | `sesion/` |
| `notificaciones` | `rutas.py`, `casos_de_uso.py`, `almacen.py`, `reglas.py`, `repositorio.py`, `barrido.py`, `push.py` | `notificaciones/` |

Compartido en `app/shared/`: `config.py`, `db.py` (`engine`, `connection()`, `in_transaction`), `errors.py` (todos los
errores del negocio), `http_errors.py`, `responses.py`, `input_validation.py`, `body_limit.py`, `club_timezone.py` (`CLUB_TIMEZONE`),
`identity.py` (`FirebaseProvider`) y `firebase_credential.py`.

### Archivo por archivo

**Raíz de `app/`**

| Archivo | Qué tiene |
|---|---|
| `main.py` | `create_app()`: arma la app, los handlers de error y los routers; `_lifespan` (el barrido en segundo plano) |
| `health.py` | `/health` (el proceso vive) |
| `e2e_support.py` | `/_pruebas/*`: atajos para los e2e; sólo se monta con `PRUEBAS=true` y el emulador |

**`shared/`**

| Archivo | Qué tiene |
|---|---|
| `config.py` | `Settings` (pydantic-settings), lee el entorno y `apps/api/.env` |
| `db.py` | `engine`, `connection()` (una conexión por pedido), `DbConnection`, `in_transaction`, `violated_constraint` |
| `errors.py` | las excepciones del negocio: `InvalidData`, `Duplicate`, `NotAuthenticated`, `RateLimited`, `AccountExists`, `Forbidden`, `Unavailable`, `NumberTaken`, `SlotTaken`, `NotFound`, `ConcurrentChange`, `BookingsOutsideHours`, `OpeningHoursChanged`, `HasFutureBookings` |
| `http_errors.py` | handlers de `InvalidData` (422 con `errores`), `Forbidden` (403) y `NotFound` (404), los tres iguales en toda la API |
| `responses.py` | `conflict`: el 409 con `errores` que cada ruta elige |
| `input_validation.py` | tipos acotados para los cuerpos (`Texto40`, `Clave`, `Identifier`…), `parse_time` y el handler de 422 y 400 |
| `body_limit.py` | `BodyLimit`: tope de tamaño y de tiempo del cuerpo |
| `club_timezone.py` | `CLUB_TIMEZONE`, la única definición de `America/Argentina/Buenos_Aires` |
| `identity.py` | `FirebaseProvider`: verificar tokens, comprobar contraseñas, crear y borrar cuentas |
| `firebase_credential.py` | `service_credential`: la cuenta de servicio desde el JSON o el archivo |

**`modules/`** (cada archivo `rutas*.py` lleva las rutas HTTP; `repositorio.py` el SQL y su proveedor `repositorio_*`)

| Funcionalidad | Qué tiene | Tablas que escribe |
|---|---|---|
| `sesion` | `Perfil`, `perfil_autenticado` (del token al `Perfil`), `usuario_actual` (la dependencia de autenticación), `PerfilesSql` | — (lee `usuario`) |
| `usuarios` | `registrar`, `editar_perfil`, `cambiar_contrasena`, `dar_de_baja` (la cuenta), `sembrar_admin` (y su comando), reglas de registro y perfil, `UsuariosSql` | `usuario` |
| `sedes` | `sedes_activas`, `dar_de_alta_sede`, `editar_sede`, `dar_de_baja_sede`, `validar_sede`, `SedesSql` | `sede` |
| `espacios` | el catálogo fijo (`Deporte`, `Tipo`), `nombre_sugerido`, alta, edición y baja de espacios, `EspaciosSql` | `espacio` |
| `horarios` | `Agenda`, `grilla`, `validar_reserva`, `horarios_disponibles`, `canchas_disponibles` (`disponibilidad.py`), `HorariosSql` (lecturas) | — |
| `reservas` | `reservar`, `mis_reservas`, `cancelar_reserva`, `modificar_reserva`, `historial_global`, `detalle_admin`, `anular_reserva`, `ReservasSql` (historial paginado por cursor) | `reserva` |
| `notificaciones` | `ANTICIPACION` (1 h), `enviar_recordatorios`, `despachar_pendientes`, dispositivos y centro de avisos, `NotificacionesSql`, `canal_push` (`push.py`: `CanalFcm`, `CanalNulo`), `barrido.py` (en proceso con `barrer_cada` o una pasada con `--una-vez`) | `notificacion`, `notificacion_reserva`, `dispositivo` |
| `recuperacion` | `pedir_enlace`, `enlace_vigente`, `usar_enlace`, `hash_de`, `EnlacesSql`, `correo.py` (`enviar`: SMTP con STARTTLS verificado, o el buzón de desarrollo) | `enlace_recuperacion`, `correo_saliente` (sólo en modo buzón) |

### Rutas de la API

«Sesión» quiere decir cualquier cuenta con token válido. Las rutas de admin piden sesión y el caso de uso responde 403
si el rol no es `admin`.

| Método y ruta | Archivo | Caso de uso | Quién |
|---|---|---|---|
| GET `/health` | `health.py` | — | cualquiera |
| GET `/openapi.json` | FastAPI | — | cualquiera (también `/docs` y `/redoc`) |
| POST `/registro` | `usuarios/rutas_registro.py` | `registrar` | cualquiera |
| POST `/recuperacion` | `recuperacion/rutas.py` | `pedir_enlace` | cualquiera |
| POST `/recuperacion/consulta` | `recuperacion/rutas.py` | `enlace_vigente` | cualquiera |
| PUT `/recuperacion` | `recuperacion/rutas.py` | `usar_enlace` | cualquiera |
| GET `/enlace/recuperar` | `recuperacion/rutas.py` | página que abre la app desde el correo | cualquiera |
| GET `/yo` | `usuarios/rutas_cuenta.py` | — | sesión |
| PUT `/yo` | `usuarios/rutas_cuenta.py` | `editar_perfil` | sesión |
| PUT `/yo/contrasena` | `usuarios/rutas_cuenta.py` | `cambiar_contrasena` | sesión |
| DELETE `/yo` | `usuarios/rutas_cuenta.py` | `dar_de_baja` | sesión |
| GET `/sedes` | `sedes/rutas.py` | `sedes_activas` | sesión |
| POST `/sedes` | `sedes/rutas.py` | `dar_de_alta_sede` | admin |
| PUT `/sedes/{sede_id}` | `sedes/rutas.py` | `editar_sede` | admin |
| DELETE `/sedes/{sede_id}` | `sedes/rutas.py` | `dar_de_baja_sede` | admin |
| GET `/espacios/catalogo` | `espacios/rutas.py` | `catalogo` | sesión |
| GET `/espacios` | `espacios/rutas.py` | `espacios_activos` | sesión |
| GET `/espacios/nombre` | `espacios/rutas.py` | `nombre_sugerido` | admin |
| POST `/espacios` | `espacios/rutas.py` | `dar_de_alta_espacio` | admin |
| PUT `/espacios/{espacio_id}` | `espacios/rutas.py` | `editar_espacio` | admin |
| DELETE `/espacios/{espacio_id}` | `espacios/rutas.py` | `dar_de_baja_espacio` | admin |
| GET `/espacios/{espacio_id}/horarios` | `horarios/rutas.py` | `horarios_disponibles` | sesión |
| GET `/espacios/disponibles` | `horarios/rutas.py` | `canchas_disponibles` | sesión |
| GET `/reservas` | `reservas/rutas.py` | `mis_reservas` | sesión |
| POST `/reservas` | `reservas/rutas.py` | `reservar` | usuario (admin: 403) |
| POST `/reservas/{id}/cancelar` | `reservas/rutas.py` | `cancelar_reserva`, después despacha el aviso | usuario, sólo sus reservas (una ajena da 404) |
| POST `/reservas/{id}/modificar` | `reservas/rutas.py` | `modificar_reserva` | usuario |
| GET `/reservas/todas` | `reservas/rutas.py` | `historial_global` | admin |
| GET `/reservas/todas/{id}` | `reservas/rutas.py` | `detalle_admin` | admin |
| POST `/reservas/{id}/anular` | `reservas/rutas.py` | `anular_reserva`, después despacha el aviso | admin |
| PUT `/dispositivos` | `notificaciones/rutas.py` | `registrar_dispositivo` | usuario |
| POST `/dispositivos/baja` | `notificaciones/rutas.py` | `dar_de_baja_dispositivo` | sesión |
| GET `/notificaciones` | `notificaciones/rutas.py` | `mis_notificaciones` | sesión |
| POST `/notificaciones/leer-todas` | `notificaciones/rutas.py` | `marcar_todas` | sesión |
| POST `/notificaciones/{id}/leer` | `notificaciones/rutas.py` | `marcar_leida` | sesión |

### Configuración de la API

`shared/config.py` lee estas variables del entorno o de `apps/api/.env` (que no se versiona; `.env.example` las lista sin valores).

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

Fuera de `Settings`: `FIREBASE_AUTH_EMULATOR_HOST` (emulador de Auth), `GOOGLE_APPLICATION_CREDENTIALS` (cuenta de servicio
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
- **Navegación con `go_router`**, todas las rutas en `rutas.dart`, con un `redirect` global por rol en `redireccion.dart`.
- `test/arquitectura_test.dart` vigila la estructura.

### Archivo por archivo

**Raíz de `lib/`**

| Archivo | Qué tiene |
|---|---|
| `main.dart` | `main()` y `arrancar()`: captura de errores, Firebase, cliente, sesión, push, apariencia; retoma la sesión con reintento y lanza `App` |
| `app.dart` | `App`: crea los repositorios, escucha los toques en avisos push y arma `MaterialApp.router` con el router de `rutas.dart` |
| `rutas.dart` | `Rutas`: todas las rutas de GoRouter, un método por sección (sesión, inicio, sedes, reservas, admin) |
| `redireccion.dart` | `redirigirSegunRol`: a dónde va cada ruta según haya sesión y el rol |

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

Todas en `lib/rutas.dart`. «Avanza» entra desde la derecha; «raíz» cambia sin animación (las pestañas); «resultado» funde.

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

Comandos de la API: `python -m app.modules.usuarios.sembrar_admin` (crear o promover el primer administrador) y
`python -m app.modules.notificaciones.barrido --una-vez` (una pasada de recordatorios y avisos).

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
