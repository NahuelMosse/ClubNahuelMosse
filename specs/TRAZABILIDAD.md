# Trazabilidad: enunciado, casos de uso y diseño contra escenarios

Cada fila apunta a escenarios que existen en los `card.snapshot.md` vigentes. Si un snapshot se
reemplaza, esta tabla se actualiza en el mismo commit.

## Requisitos del enunciado

Fuente: `../Trabajo Práctico_2026.docx.pdf`.

| Requisito | Escenarios |
|---|---|
| RF 1 · Registro con correo y contraseña | CU-03-H01-01 |
| RF 1 · Home después de iniciar sesión | CU-01-H01-01, TP-01-H01-01 |
| RF 1 · Recuperar o establecer una contraseña nueva | CU-04b-H01-01, CU-04-H01-01 |
| RF 2 · Mostrar todos los datos del perfil | CU-05-H01-01 |
| RF 2 · Editar el perfil salvo el correo | CU-06-H01-01, CU-06-H01-02 |
| RF 2 · Perfil con nombre, apellido y fecha de nacimiento | MOD-01-H01-01, CU-03-H01-01 |
| RF 2 · Cerrar sesión | CU-02-H01-01, CU-02-H02-01 |
| RF 3 · Horarios dentro del funcionamiento de la sede | CU-12-H01-01, CU-13-H03-03, CU-09-H01-05 |
| RF 3 · Reserva de un espacio, con fecha, inicio y fin | MOD-01-H01-04, CU-09-H01-01 |
| RF 3 · Duración mínima de una hora | CU-09-H01-08, CU-13-H03-02 |
| RF 3 · Inicio y fin en horas completas | CU-09-H01-06 |
| RF 3 · El fin no supera el cierre de la sede | CU-09-H01-05, CU-12-H04-01 |
| RF 3 · Sólo horarios futuros | CU-09-H01-04, CU-12-H01-01, CU-13-H03-01 |
| RF 3 · Sin superposición, validada en el backend | CU-09-H02-01, CU-09-H02-02, MOD-01-H01-05 |
| RF 3 · Consultar disponibilidad según la sede | CU-12-H01-01, CU-13-H01-01 |
| RF 3 · Reservar un espacio para una fecha y horario | CU-09-H01-01 |
| RF 3 · Listar las reservas del usuario con sede, espacio, fecha y horario | CU-08-H01-01 |
| RF 3 · Cancelar y que el horario vuelva a estar disponible | CU-10-H01-01, CU-10-H01-02 |
| RF 3 · Notificaciones push de reservas próximas | CU-24.1-H01-01 |
| RF 4 · Sede con nombre, dirección y horarios | CU-17-H01-01, MOD-01-H01-02 |
| RF 4 · Listado de sedes con sus horarios | CU-16-H01-01 |
| RF 4 · Elegir una sede y ver sus espacios y horarios disponibles | CU-16-H01-02, CU-16-H01-04 |
| RF 5 · Listado de espacios indicando la sede de cada uno | TP-05-H01-01 |
| RF 5 · Espacio asociado a una sede, con tipo y nombre compuesto | CU-21-H01-02, TP-05-H01-02, MOD-01-H01-03 |
| RF 5 · Filtrar espacios por tipo | TP-05-H02-01, CU-20-H01-01 |
| RF 6 · Historial con las reservas ya finalizadas | CU-08-H01-03, MOD-01-H01-06 |
| RF 7 · Sin conexión a internet | TP-07-H01-01 |
| RF 7 · Servidor caído | TP-07-H02-01 |
| RF 7 · Login incorrecto | TP-07-H03-01, CU-01-H03-01 |
| RF 7 · Usuario ya registrado | TP-07-H04-01, CU-03-H03-01 |
| RF 8 · Nombre de la aplicación ClubNahuelMosse | RNF-01-H01-01 |
| RF 9 · Repositorio de GitHub con el mismo nombre | RNF-01-H01-01 |
| RNF 1 · Diseño en Figma | Entrega 1: `VUiZR6V4USuiyxRgtshhEn` (sin escenario: ya entregado) |
| RNF 1 · App en Flutter | RNF-01-H02-01 |
| RNF 2 · GitHub con cuenta propia y commits durante el desarrollo | RNF-01-H03-01 |
| RNF 3 · API REST documentada con Swagger/OpenAPI | RNF-01-H04-01 |
| RNF 4 · Base de datos relacional (PostgreSQL) | RNF-01-H05-01 |
| RNF 5 · API y base en la nube | RNF-01-H06-01 |
| RNF 5 · Firebase para autenticación y push | CU-01-H01-01, CU-24.1-H01-01 |
| RNF 5 · La API identifica al usuario autenticado | RNF-01-H06-02, RNF-01-H06-03, CU-08-H01-05, CU-14-H05-02, CU-15-H01-04 |
| RNF 6 · README de la app y del backend | RNF-01-H07-01, RNF-01-H07-02 |
| Entrega 2 · Backend desplegado y app conectada a la API | RNF-01-H06-01 |
| Entrega 2 · Ícono | RNF-01-H08-01 |
| Entrega 2 · Inicio de sesión, registración y recuperación | CU-01-H01-01, CU-03-H01-01, CU-04b-H01-01 |
| Entrega 2 · Gestión de reservas | CU-09-H01-01, CU-10-H01-01, CU-11-H01-01, CU-08-H01-01 |
| Entrega 2 · Modelo de datos con entidades, atributos y relaciones | MOD-01-H01-01, MOD-01-H01-02, MOD-01-H01-03, MOD-01-H01-04 |
| Entrega 2 · Manejo de errores | TP-07-H01-01, TP-07-H02-01 |
| Entrega 2 · App funcionando en emulador | RNF-01-H02-01 |
| Entrega 2 · ZIP del backend y de la app en Blackboard, defensa individual | sin escenario: acciones del alumno fuera del sistema |

## Casos de uso

| CU | Card |
|---|---|
| CU-01 Iniciar sesión | `specs/CU-01-iniciar-sesion/` |
| CU-02 Cerrar sesión | `specs/CU-02-cerrar-sesion/` |
| CU-03 Registrar usuario | `specs/CU-03-registrar-usuario/` |
| CU-04 Cambiar contraseña | `specs/CU-04-cambiar-contrasena/` |
| CU-04b Recuperar contraseña | `specs/CU-04b-recuperar-contrasena/` |
| CU-05 Consultar perfil | `specs/CU-05-consultar-perfil/` |
| CU-06 Editar perfil | `specs/CU-06-editar-perfil/` |
| CU-07 Dar cuenta de baja | `specs/CU-07-dar-cuenta-de-baja/` |
| CU-08 Historial de reservas | `specs/CU-08-historial-de-reservas/` |
| CU-09 Reservar cancha | `specs/CU-09-reservar-cancha/` |
| CU-10 Cancelar reserva | `specs/CU-10-cancelar-reserva/` |
| CU-11 Modificar reserva | `specs/CU-11-modificar-reserva/` |
| CU-12 Consultar horarios disponibles | `specs/CU-12-consultar-horarios-disponibles/` |
| CU-13 Consultar canchas | `specs/CU-13-consultar-canchas/` |
| CU-14 Historial global de reservas | `specs/CU-14-historial-global-de-reservas/` |
| CU-15 Anular reserva | `specs/CU-15-anular-reserva/` |
| CU-16 Consultar sedes | `specs/CU-16-consultar-sedes/` |
| CU-17 Alta de sede | `specs/CU-17-alta-de-sede/` |
| CU-18 Editar sede | `specs/CU-18-editar-sede/` |
| CU-19 Baja de sede | `specs/CU-19-baja-de-sede/` |
| CU-20 Filtrar espacios deportivos | `specs/CU-20-filtrar-espacios-deportivos/` |
| CU-21 Alta de espacio | `specs/CU-21-alta-de-espacio/` |
| CU-22 Editar espacio | `specs/CU-22-editar-espacio/` |
| CU-23 Baja de espacio | `specs/CU-23-baja-de-espacio/` |
| CU-24.1 Notificación recordatoria | `specs/CU-24.1-notificacion-recordatoria/` |
| CU-24.2 Notificación de cancelación forzosa | `specs/CU-24.2-notificacion-cancelacion-forzosa/` |
| CU-24.3 Confirmación de cancelación | `specs/CU-24.3-confirmacion-de-cancelacion/` |

## Pantallas del prototipo

Fuente: página `03 · App · Prototipo` de `VUiZR6V4USuiyxRgtshhEn`, 112 pantallas.

| Nodo | Pantalla | Escenarios |
|---|---|---|
| 29:27 | CU-01 · Login · Vacío | CU-01-H01-01 |
| 30:319 | CU-01 · Login · Campos incompletos | CU-01-H02-01, CU-01-H02-02 |
| 30:365 | CU-01 · Login · Credenciales inválidas | CU-01-H03-01, CU-01-H03-02 |
| 30:429 | CU-01 · Login · Rol administrador | CU-01-H01-02, TP-01-H03-01 |
| 32:124 | CU-03 · Registro · Formulario vacío | CU-03-H01-01 |
| 34:546 | CU-03 · Registro · Campos vacíos | CU-03-H02-01 |
| 34:443 | CU-03 · Registro · Datos ingresados | CU-03-H01-01 |
| 34:647 | CU-03 · Registro · Usuario ya registrado | CU-03-H03-01, CU-03-H03-02 |
| 35:312 | CU-03 · Registro · Exitoso | CU-03-H01-01 |
| 35:444 | CU-04 · Cambiar contraseña · Formulario vacío | CU-04-H01-01 |
| 36:436 | CU-04 · Cambiar contraseña · Validación en vivo | CU-04-H03-01 |
| 36:378 | CU-04 · Cambiar contraseña · Error contraseña actual | CU-04-H02-01 |
| 390:6379 | CU-04 · Cambiar contraseña · No coinciden | CU-04-H04-01 |
| 35:350 | CU-04 · Cambiar contraseña · Actualizada | CU-04-H01-01 |
| 35:361 | CU-04b · Recuperar contraseña · Solicitar | CU-04b-H01-01 |
| 390:6450 | CU-04b · Recuperar contraseña · Correo inválido | CU-04b-H03-01 |
| 35:323 | CU-04b · Recuperar contraseña · Email enviado | CU-04b-H01-01, CU-04b-H02-01, CU-04b-H06-01 |
| 35:403 | CU-04b · Recuperar contraseña · Nueva contraseña | CU-04b-H01-01 |
| 390:6480 | CU-04b · Recuperar contraseña · No coinciden | CU-04b-H05-01 |
| 35:336 | CU-04b · Recuperar contraseña · Enlace inválido | CU-04b-H04-01, CU-04b-H04-02 |
| 37:147 | CU-01 · Home · Usuario | TP-01-H01-01, TP-01-H01-02, TP-01-H01-03, TP-01-H01-04, TP-01-H01-05, TP-01-H01-06, TP-01-H01-07 |
| 39:356 | CU-05 · Mi perfil · Lectura | CU-05-H01-01, CU-05-H01-03 |
| 71:4566 | CU-05 · Mi perfil · Modo claro | CU-05-H01-02, CU-06-H01-03 |
| 43:314 | CU-06 · Editar perfil · Edición | CU-06-H01-01, CU-06-H01-02 |
| 43:421 | CU-06 · Editar perfil · Formato inválido | CU-06-H02-01 |
| 43:488 | CU-07 · Eliminar cuenta · Procesando | CU-07-H01-03 |
| 49:434 | CU-08 · Mis reservas · Próximas | CU-08-H01-01, CU-08-H01-02 |
| 49:544 | CU-08 · Mis reservas · Historial | CU-08-H01-03, CU-08-H01-04 |
| 49:651 | CU-08 · Mis reservas · Sin próximas | CU-08-H02-01 |
| 49:697 | CU-08 · Mis reservas · Sin pasadas | CU-08-H02-02 |
| 48:123 | CU-09 · Confirmar reserva | CU-09-H01-01, CU-09-H01-07 |
| 334:6366 | CU-09 · Confirmar reserva · 2 horas | CU-09-H01-03 |
| 334:6410 | CU-09 · Confirmar reserva · 3 horas | CU-09-H01-03 |
| 48:183 | CU-09 · Reserva confirmada | CU-09-H01-01, CU-09-H01-09 |
| 334:6454 | CU-09 · Reserva confirmada · 2 horas | CU-09-H01-03 |
| 334:6493 | CU-09 · Reserva confirmada · 3 horas | CU-09-H01-03 |
| 67:1089 | CU-11 · Modificar reserva · Elegir nuevo horario | CU-11-H01-01, CU-11-H04-01 |
| 51:494 | CU-11 · Modificar reserva · Confirmar cambio | CU-11-H01-01, CU-11-H02-01 |
| 45:359 | CU-12 · Horarios disponibles · Grilla | CU-12-H01-01, CU-12-H01-03, CU-12-H01-05, CU-12-H04-03 |
| 67:984 | CU-12 · Horarios disponibles · Duración 2 horas | CU-12-H04-01 |
| 334:6228 | CU-12 · Horarios disponibles · Duración 3 horas | CU-12-H04-02 |
| 47:555 | CU-12 · Horarios disponibles · Sin horarios | CU-12-H05-01, CU-12-H04-03 |
| 52:734 | CU-13 · Consultar canchas · Filtros | CU-13-H01-01 |
| 52:1085 | CU-13 · Consultar canchas · Horario inválido | CU-13-H03-01, CU-13-H03-02 |
| 52:824 | CU-13 · Consultar canchas · Resultados | CU-13-H01-01, CU-13-H01-03 |
| 52:963 | CU-13 · Consultar canchas · Sin resultados | CU-13-H02-01 |
| 201:6295 | CU-13 · Consultar canchas · Error al consultar | CU-13-H04-01, CU-13-H05-01 |
| 53:319 | CU-16 · Todas las sedes | CU-16-H01-01 |
| 54:986 | CU-16 · Sede sin canchas | CU-16-H02-01, CU-20-H04-01 |
| 406:6534 | CU-20 · Sede Ramos Mejía | CU-16-H01-02 |
| 53:431 | CU-20 · Sede Morón · Fútbol · Todos | CU-20-H01-01, CU-20-H03-01 |
| 54:604 | CU-20 · Sede Morón · Fútbol 5 | CU-20-H01-02 |
| 123:5686 | CU-20 · Sede Morón · Fútbol 7 | CU-20-H01-02 |
| 123:5984 | CU-20 · Sede Morón · Fútbol 11 | CU-20-H01-02 |
| 54:818 | CU-20 · Sede Morón · Hockey (sin variantes) | CU-20-H02-01 |
| 121:5256 | CU-20 · Sede Morón · Tenis | CU-20-H01-01 |
| 123:6273 | CU-20 · Sede Morón · Tenis · Polvo de ladrillo | CU-20-H01-02 |
| 123:6473 | CU-20 · Sede Morón · Tenis · Cemento | CU-20-H01-02 |
| 120:4885 | CU-20 · Sede San Justo · Fútbol | CU-20-H01-01 |
| 121:5974 | CU-20 · Sede San Justo · Golf | CU-20-H02-01 |
| 120:5389 | CU-20 · Sede Castelar · Tenis | CU-20-H01-01 |
| 121:5647 | CU-20 · Sede Castelar · Vóley | CU-20-H01-01 |
| 55:251 | CU-14 · Panel admin · Reservas · Todas | CU-14-H01-01 |
| 55:482 | CU-14 · Panel admin · Reservas · Activas | CU-14-H01-03 |
| 55:656 | CU-14 · Panel admin · Reservas · Completadas | CU-14-H01-03 |
| 55:786 | CU-14 · Panel admin · Reservas · Anuladas | CU-14-H01-03, CU-14-H09-01 |
| 58:957 | CU-14 · Panel admin · Cargando | CU-14-H01-09 |
| 60:1257 | CU-14 · Panel admin · Panel de filtros | CU-14-H01-04 |
| 60:1441 | CU-14 · Panel admin · Rango de fechas inválido | CU-14-H04-01 |
| 58:798 | CU-14 · Panel admin · Resultados filtrados | CU-14-H01-04 |
| 58:881 | CU-14 · Panel admin · Búsqueda activa | CU-14-H01-05 |
| 58:1140 | CU-14 · Panel admin · Sin resultados | CU-14-H02-01 |
| 58:1339 | CU-14 · Panel admin · Historial vacío | CU-14-H07-01 |
| 59:1252 | CU-14 · Panel admin · Detalle de reserva | CU-14-H01-06, CU-14-H01-08 |
| 59:1336 | CU-14 · Panel admin · Detalle · Anulada | CU-14-H01-07, CU-24.2-H01-03 |
| 60:1559 | CU-15 · Anular reserva · Con motivo | CU-15-H01-01 |
| 60:1595 | CU-15 · Anular reserva · Sin motivo | CU-15-H03-01 |
| 62:1648 | CU-17 · Gestionar sedes | CU-17-H01-01, CU-19-H01-03 |
| 62:1828 | CU-17 · Alta de sede · Formulario | CU-17-H01-01 |
| 62:1903 | CU-17 · Alta de sede · Campos faltantes | CU-17-H03-01 |
| 64:2050 | CU-17 · Alta de sede · Éxito | CU-17-H01-01, CU-17-H01-04 |
| 62:1968 | CU-18 · Editar sede | CU-18-H01-01, CU-18-H07-01 |
| 62:2035 | CU-18 · Editar sede · Campo vacío | CU-18-H03-01 |
| 63:1895 | CU-21 · Gestionar espacios | CU-21-H01-01, CU-23-H01-01, TP-05-H01-02 |
| 63:2030 | CU-21 · Alta espacio · Formulario vacío | CU-21-H03-01 |
| 63:2101 | CU-21 · Alta espacio · Formulario completo | CU-21-H01-01, CU-21-H01-02 |
| 63:2162 | CU-21 · Alta espacio · Campo obligatorio | CU-21-H03-01 |
| 63:2223 | CU-21 · Alta espacio · Duplicado | CU-21-H02-01 |
| 64:2065 | CU-21 · Alta espacio · Éxito | CU-21-H01-01, CU-21-H01-04 |
| 63:2302 | CU-22 · Editar espacio | CU-22-H01-01, CU-22-H01-03 |
| 390:6522 | CU-22 · Editar espacio · Precio inválido | CU-22-H03-01 |
| 65:328 | CU-24.1 · Pantalla bloqueada (contexto del sistema) | CU-24.1-H01-01 |
| 65:348 | CU-24.1 · Push recordatoria (en la app) | CU-24.1-H02-01 |
| 65:363 | CU-24.2 · Push cancelación forzosa | CU-24.2-H01-01 |
| 65:383 | CU-24.3 · Push confirmación de cancelación | CU-24.3-H01-01 |
| 65:401 | CU-24 · Centro de notificaciones | CU-24.1-H01-03, CU-24.3-H01-03 |
| 65:470 | CU-24 · Notificaciones desactivadas | CU-24.1-H03-01, CU-24.1-H03-02 |
| 43:1462 | CU-24 · Notificaciones in-app (overlay) | CU-24.1-H04-02 |
| 42:274 | CU-07 · Eliminar cuenta · Confirmar (overlay) | CU-07-H01-01, CU-07-H02-01 |
| 42:296 | CU-10 · Cancelar reserva · Confirmar (overlay) | CU-10-H01-01, CU-10-H02-01 |
| 42:312 | CU-10 · Cancelar reserva · Éxito (overlay) | CU-10-H01-01 |
| 42:329 | CU-19 · Baja de sede · Confirmar (overlay) | CU-19-H01-01, CU-19-H02-01 |
| 42:345 | CU-19 · Baja de sede · Reservas futuras (overlay) | CU-19-H04-01 |
| 42:368 | CU-23 · Baja de espacio · Confirmar (overlay) | CU-23-H01-01, CU-23-H02-01 |
| 43:1422 | CU-02 · Tarjeta del avatar (overlay) | CU-02-H01-01, CU-02-H03-01, CU-05-H02-01, TP-01-H01-08 |
| 393:6496 | CU-18 · Editar sede · Reservas fuera del horario (overlay) | CU-18-H04-01, CU-18-H04-03 |
| 393:6553 | CU-09 · Horario ya reservado (overlay) | CU-09-H02-01 |
| 393:6532 | Compartido · Algo cambió mientras tanto (overlay) | TP-07-H07-01, CU-11-H03-01, CU-18-H05-01, CU-22-H05-01 |
| 42:384 | Compartido · Error de conexión (overlay) | TP-07-H01-01 |
| 42:410 | Compartido · Error del servidor (overlay) | TP-07-H02-01 |
| 42:426 | Compartido · Sesión expirada (overlay) | TP-07-H05-01 |
| 42:442 | Compartido · Acceso denegado (overlay) | TP-07-H06-01, CU-14-H05-01 |
