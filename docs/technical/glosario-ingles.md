# Glosario del código

El código de ClubNahuelMosse está en inglés: módulos, archivos, clases, funciones, variables, comentarios, tablas, columnas, campos JSON y rutas de la API. Los textos que ve el usuario están en castellano. Esta página fija cómo se llama cada concepto del dominio; un nombre nuevo sigue el mismo criterio.


Criterios: `reserva`→`booking` (no reservation); `sede`→`venue`; `espacio`→`space` (el catálogo incluye golf); `tipo`→`kind`
(`type` pisa el builtin); ortografía US (`canceled`); timestamps `_at`; rangos `since`/`until`; tabla `usuario`→`app_user`
(`user` reservado en Postgres).

## Carpetas y archivos
| Español | Inglés |
|---|---|
| `apps/api/migraciones/` | `migrations/` (0001–0010 se mueven sin tocar contenido) |
| `app/modules/` | `espacios`→`spaces`, `horarios`→`availability`, `notificaciones`→`notifications`, `recuperacion`→`password_recovery` |
| `app/modules/` | `reservas`→`bookings`, `sedes`→`venues`, `sesion`→`session`, `usuarios`→`users` |
| `casos_de_uso.py` / `reglas.py` / `repositorio.py` / `rutas.py` | `use_cases.py` / `rules.py` / `repository.py` / `routes.py` |
| `almacen.py` / `barrido.py` / `correo.py` / `disponibilidad.py` | `store.py` / `sweep.py` / `email.py` / `slots.py` |
| `perfil.py` / `usuario_actual.py` / `administradores.py` / `baja.py` | `profile.py` / `current_user.py` / `admins.py` / `deactivation.py` |
| `contrasena.py` / `registro.py` / `rutas_cuenta.py` / `rutas_registro.py` / `sembrar_admin.py` | `password.py` / `registration.py` / `account_routes.py` / `registration_routes.py` / `seed_admin.py` |
| `salud.py` / `pruebas.py` | `health.py` / `e2e_support.py` |
| `shared/{credencial_firebase,cuerpo,entradas,errores,errores_http,identidad,respuestas,zona}.py` | `{firebase_credential,body_limit,input_validation,errors,http_errors,identity,responses,club_timezone}.py` |
| `apps/mobile/lib/` | `comun`→`common`, `tema`→`theme`, `inicio`→`home`, `espacios`→`spaces`, `sedes`→`venues`, `reservas`→`bookings`, `sesion`→`session`, `usuarios`→`users`, `notificaciones`→`notifications` (`admin`, `api` igual) |
| `lib/rutas.dart` / `lib/api/rutas.dart` / `lib/redireccion.dart` | `router.dart` / `api/api_routes.dart` / `redirect.dart` |
| `pantalla_X` / `tarjeta_X` / `dialogo_X` / `cabecera_X` | `X_screen` / `X_card` / `X_dialog` / `X_header` |

## Tablas, vista, funciones, disparadores
`usuario`→`app_user`, `sede`→`venue`, `espacio`→`space`, `reserva`→`booking`, `enlace_recuperacion`→`recovery_link`,
`correo_saliente`→`outgoing_email`, `dispositivo`→`device`, `notificacion`→`notification`, `notificacion_reserva`→`notification_booking`;
vista `reserva_con_estado`→`booking_with_status` (`estado_actual`→`current_status`); `marcar_modificado()`→`touch_updated_at()`,
`prohibir_borrado()`→`forbid_delete()`, `correo_inmutable()`→`email_immutable()`, `nombre_espacio_inmutable()`→`space_identity_immutable()`;
`uuid_v7()` igual; disparadores `<t>_modificado`→`<t>_updated`, `<t>_sin_borrado`→`<t>_no_delete`,
`usuario_correo_inmutable`→`app_user_email_immutable`, `espacio_nombre_inmutable`→`space_name_immutable`.

## Columnas
- todas: `creado_en`→`created_at`, `modificado_en`→`updated_at`, `activo`/`activa`→`active`, `dado_de_baja_en`→`deactivated_at`,
  `dado_de_baja_por`→`deactivated_by`, `creado_por`→`created_by`, `modificado_por`→`updated_by`, `usuario_id`→`user_id`, `reserva_id`→`booking_id`
- app_user: `correo`→`email`, `nombre`→`first_name`, `apellido`→`last_name`, `fecha_nacimiento`→`birth_date`, `rol`→`role`,
  `contrasena_cambiada_en`→`password_changed_at`; `dni`, `firebase_uid` igual
- venue: `nombre`→`name`, `calle`→`street`, `altura`→`street_number`, `apertura`→`opens_at`, `cierre`→`closes_at`, `dias`→`open_days`
- space: `sede_id`→`venue_id`, `deporte`→`sport`, `tipo`→`kind`, `numero`→`number`, `nombre`→`name`, `techada`→`covered`,
  `iluminada`→`lit`, `precio_por_hora`→`price_per_hour`
- booking: `espacio_id`→`space_id`, `inicio`→`starts_at`, `fin`→`ends_at`, `precio_por_hora`→`price_per_hour`, `estado`→`status`,
  `cancelada_en`→`canceled_at`, `cancelada_por`→`canceled_by`, `motivo`→`reason`; `total` igual
- recovery_link: `codigo_hash`→`code_hash`, `vence_en`→`expires_at`, `usado_en`→`used_at`, `invalidado_en`→`invalidated_at`
- outgoing_email: `para`→`recipient`, `asunto`→`subject`, `cuerpo`→`body`
- device: `plataforma`→`platform`, `permiso`→`permission_granted`; `token` igual
- notification: `tipo`→`kind`, `titulo`→`title`, `cuerpo`→`body`, `reserva_inicio`→`booking_starts_at`, `envio`→`delivery`,
  `enviada_en`→`sent_at`, `leida_en`→`read_at`, `reemplazada_por`→`replaced_by`, `cantidad`→`count`, `enviando_desde`→`sending_since`
- notification_booking: `notificacion_id`→`notification_id`, `reserva_id`→`booking_id`

## Índices y restricciones con nombre
`usuario_correo_unico`→`app_user_email_unique`, `usuario_dni_unico`→`app_user_dni_unique`, `sede_nombre_activa_unico`→`venue_name_active_unique`,
`dispositivo_token_activo`→`device_token_active`, `dispositivo_usuario`→`device_user`, `notificacion_recordatorio_unico`→`notification_reminder_unique`,
`notificacion_cancelacion_unica`→`notification_cancellation_unique`, `notificacion_usuario`→`notification_user`,
`notificacion_forzosa_sin_leer`→`notification_forced_unread`, `notificacion_por_despachar`→`notification_to_dispatch`,
`notificacion_por_reemplazada_por`→`notification_by_replaced_by`, `reserva_activa_inicio`→`booking_active_starts_at`,
`reserva_por_usuario_inicio`→`booking_by_user_starts_at`, `reserva_por_inicio`→`booking_by_starts_at`,
`reserva_por_cancelada_por`→`booking_by_canceled_by`, `enlace_recuperacion_por_usuario`→`recovery_link_by_user`,
`notificacion_envio_check`→`notification_delivery_check`, `notificacion_cancelacion_con_reserva`→`notification_cancellation_has_booking`;
autogenerados (`_pkey`, `_fkey`, `_check`, `_key`, `_excl`): el nombre que Postgres daría con tabla/columna nuevas, leído de `pg_constraint` en 0010.

## Valores de enum guardados (se traducen)
`booking.status`: `activa`→`active`, `cancelada`→`canceled`, `anulada`→`voided`, calculado `completada`→`completed`.
`notification.delivery`: `pendiente`→`pending`, `enviando`→`sending`, `enviada`→`sent`, `sin_permiso`→`no_permission`, `sin_canal`→`no_channel`, `fallida`→`failed`.
`notification.kind`: `recordatorio`→`reminder`, `cancelacion_forzosa`→`forced_cancellation`, `cancelacion_usuario`→`user_cancellation`.
`app_user.role`: `usuario`→`user`, `admin` igual. `device.platform` igual. Parámetro `cuando`: `proximas`→`upcoming`, `historial`→`history`.
Config `correo_modo`: `buzon`→`outbox`, `smtp` igual.

## Base de la API (nombres de código)
`Config`→`Settings` (`firebase_credenciales_json`→`firebase_credentials_json`, `url_publica`→`public_url`, `correo_modo`→`email_mode`, `smtp_puerto`→`smtp_port`, `smtp_usuario`→`smtp_user`, `smtp_contrasena`→`smtp_password`, `correo_remitente`→`email_sender`, `pruebas`→`e2e_testing`, `recordatorios_cada`→`reminders_every`; las variables de entorno aceptan el nombre en inglés y el de hoy, gana el inglés);
`DatosInvalidos`→`InvalidData`, `Duplicado`→`Duplicate`, `NoAutenticado`→`NotAuthenticated`, `Demorado`→`RateLimited`, `CuentaExistente`→`AccountExists`, `Prohibido`→`Forbidden`, `NoDisponible`→`Unavailable`, `NumeroOcupado`→`NumberTaken`, `HorarioOcupado`→`SlotTaken`, `NoEncontrada`→`NotFound`, `Cambiado`→`ConcurrentChange`, `ReservasAfuera`→`BookingsOutsideHours`, `AgendaCambiada`→`OpeningHoursChanged`, `ConReservasFuturas`→`HasFutureBookings`;
`motor`→`engine`, `conexion`→`connection`, `Conexion`→`DbConnection`, `en_transaccion`→`in_transaction`, `restriccion_violada`→`violated_constraint`, `VENTANA_DE_REINTENTO`→`RETRY_WINDOW`;
`CuerpoAcotado`→`BodyLimit`, `Identificador`→`Identifier`, `leer_hora`→`parse_time`, `errores_de_forma`→`shape_errors`, `conflicto`→`conflict`, `credencial_de_servicio`→`service_credential`, `ZONA_CLUB`→`CLUB_TIMEZONE`, `crear_app`→`create_app`;
`ProveedorFirebase`→`FirebaseProvider` (`crear_cuenta`→`create_account`, `uid_de`→`uid_of`, `borrar_cuenta`→`delete_account`, `uid_del_token`→`uid_from_token`, `contrasena_correcta`→`password_matches`, `cambiar_contrasena`→`change_password`), `identidad`→`identity`.

## Rutas de la API
`POST /registro`→`/register`; `/yo`→`/me`, `/yo/contrasena`→`/me/password`; `/recuperacion`→`/password-recovery`,
`/recuperacion/consulta`→`/password-recovery/check`; `/enlace/recuperar`→`/link/recover`; `/sedes[/{sede_id}]`→`/venues[/{venue_id}]`;
`/espacios`→`/spaces`, `/espacios/catalogo`→`/spaces/catalog`, `/espacios/nombre`→`/spaces/name`, `/espacios/disponibles`→`/spaces/available`,
`/espacios/{espacio_id}`→`/spaces/{space_id}`, `/espacios/{espacio_id}/horarios`→`/spaces/{space_id}/slots`;
`/reservas`→`/bookings`, `/reservas/{id}/{cancelar,modificar,anular}`→`/bookings/{booking_id}/{cancel,modify,void}`,
`/reservas/todas[/{id}]`→`/bookings/all[/{booking_id}]`; `PUT /dispositivos`→`/devices`, `/dispositivos/baja`→`/devices/unregister`;
`/notificaciones`→`/notifications`, `/leer-todas`→`/read-all`, `/{id}/leer`→`/{notification_id}/read`; `/health` igual (cuerpo
`{"estado":"vivo"}`→`{"status":"ok"}`); `/_pruebas/...`→`/_testing/{emails, bookings[/clear,/start,/void], venues/deactivate, spaces/deactivate, password-recovery/{code}/expire, reminders}`.
Query: `sede_id`→`venue_id`, `deporte`→`sport`, `tipo`→`kind`, `fecha`→`date`, `horas`→`hours`, `reserva_id`→`booking_id`,
`desde`/`hasta`→`since`/`until`, `cuando`→`when`, `estado`→`status`, `pagina`→`page`; `q` igual.

## Campos JSON
`errores`→`errors` (claves según este glosario; `cambio`→`change`); `nombre`→`first_name` (persona) / `name` (sede, espacio, deporte),
`apellido`→`last_name`, `correo`→`email`, `contrasena`→`password`, `fecha_nacimiento`→`birth_date`, `rol`→`role`;
`actual`→`current_password`, `nueva`→`new_password`, `codigo`→`code`; `direccion`→`address`, `apertura`→`opens_at`, `cierre`→`closes_at`,
`dias`→`open_days`, `confirmar`→`confirm`, `canchas`→`space_count`, `deportes`→`sports`; `sede_id`→`venue_id`, `sede`→`venue`,
`espacio_id`→`space_id`, `espacio`→`space`, `deporte`→`sport`, `tipo`→`kind`, `tipos`→`kinds`, `clave`→`key`; `numero`→`number`,
`techada`→`covered`, `iluminada`→`lit`, `precio_por_hora`→`price_per_hour`; `inicio`→`starts_at`, `fin`→`ends_at`, `fecha`→`date`,
`desde`→`start_hour`, `horas`→`hours`, `hoy`→`today`, `abre`→`opens`, `franjas`→`slots`, `disponible`→`available`, `no_disponibles`→`unavailable`;
`estado`→`status`, `motivo`→`reason`, `anulable`→`voidable`; `total`, `cancelable` igual; `usuario_id`→`user_id`, `usuario`→`user`,
`creado_en`→`created_at`, `cancelada_en`→`canceled_at`, `cancelada_por_nombre`→`canceled_by_name`; `espacio_de_baja`→`space_deactivated`,
`aviso_envio`→`notice_delivery`, `aviso_en`→`notice_at`; `reservas`→`bookings`, `pagina`→`page`, `por_pagina`→`per_page`,
`contadores`→`counters` (`todas`→`all`, `activas`→`active`, `completadas`→`completed`, `anuladas`→`voided`); `espacios`→`spaces`, `sedes`→`venues`,
`reservas_afuera`→`bookings_outside`; `notificaciones`→`notifications`, `no_leidas`→`unread`, `titulo`→`title`, `cuerpo`→`body`,
`creada_en`→`created_at`, `leida`→`read`; `plataforma`→`platform`, `permiso`→`permission_granted`, `mensaje`→`message`, `campos`→`fields`;
datos push `tipo`→`kind`, `reserva_id`→`booking_id`; enlace `clubnahuelmosse://app/recuperar#codigo=`→`app/recover#code=`.

## Clases y funciones principales
`Reserva`→`Booking`, `ReservaHistorial`→`BookingHistoryEntry`, `HistorialDeReservas`→`BookingHistory`, `FiltrosHistorial`→`HistoryFilters`,
`Contadores`→`Counters`, `ReservasSql`→`BookingsSql`, `Cuando`→`When`; `Sede`→`Venue`, `SedeNueva`→`NewVenue`, `SedeDelEspacio`→`SpaceVenue`,
`Espacio`→`Space`, `EspacioNuevo`→`NewSpace`, `CambioDeEspacio`→`SpaceChange`; `Deporte`→`Sport`, `Tipo`→`Kind`, `NombreSugerido`→`SuggestedName`,
`CATALOGO`→`CATALOG`; `Agenda`→`OpeningHours`, `Franja`→`Slot`, `Grilla`→`SlotGrid`, `Horarios`→`Availability`;
`DatosEspacio`→`SpaceData`, `Espacios`→`Spaces`, `EspaciosSql`→`SpacesSql`, `HorariosSql`→`AvailabilitySql`, `Disponibilidad`→`SlotSearch`,
`ListaDeEspacios`→`SpaceList`, `EspacioVista`→`SpaceView`, `TipoVista`→`KindView`, `DeporteVista`→`SportView`, la vista del catálogo `CatalogView` (en Python `Catalogo` pasa a `CatalogView`, no a `Catalog`),
`Sugerencia`→`Suggestion`, `Errores`→`ErrorBody`, `PedidoDeEspacio`→`SpaceRequest`, `PedidoDeCambioDeEspacio`→`SpaceChangeRequest`;
`catalogo`→`catalog`, `nombre_sugerido`→`suggested_name`, `espacios_activos`→`active_spaces`, `tipo_del_catalogo`→`catalog_kind`,
`parte_de_sede`→`venue_part`, `parte_de_calle`→`street_part`, `espacio_de_fila`→`space_of_row`, `agenda_de_fila`→`opening_hours_of_row`,
`repositorio_espacios`→`spaces_repository`, `repositorio_horarios`→`availability_repository`, `vista_de_espacio`→`space_view`,
`canchas_disponibles`→`available_spaces`, `grilla`→`slot_grid`, `rango`→`time_range`, `error_de_duracion`→`duration_error`,
`validar_consulta`→`validate_query`, `validar_rango`→`validate_range`, `validar_reserva`→`validate_booking`, `validar_cambio`→`validate_change`
(kwarg `dados`→`given`), `COLUMNAS_DE_ESPACIO`→`SPACE_COLUMNS`, `DIAS_A_LA_VISTA`→`DAYS_IN_VIEW`, `MIN_HORAS`/`MAX_HORAS`→`MIN_HOURS`/`MAX_HOURS`,
`HORAS_POR_DIA`→`HOURS_PER_DAY`; vistas de horarios `SlotView`, `SlotGridView`; funciones de ruta `ver_catalogo`→`show_catalog`,
`listar_espacios`→`list_spaces`, `sugerir_nombre`→`suggest_name`, `alta_de_espacio`→`create_space_route`, `edicion_de_espacio`→`update_space_route`,
`baja_de_espacio`→`deactivate_space_route`, `ver_horarios`→`show_slots`, `ver_disponibles`→`show_available`; métodos de repositorio `activos`→`active`, `siguiente`→`next_number`, `insertar`→`insert`, `actualizar`→`update`,
`dar_de_baja`→`deactivate`, `dar_de_baja_de_sede`→`deactivate_venue_spaces`, `agenda`→`opening_hours`, `agenda_de_sede`→`venue_opening_hours`,
`ocupadas`→`taken`, `libres`→`free`; atributos `fecha`→`day` (en `SlotGrid`, para no pisar el tipo `date`), `hoy`→`today`, `abre`→`opens`,
`franjas`→`slots`, `no_disponibles`→`unavailable`, `inicio`/`fin`→`start`/`end`, `disponible`→`available`, `apertura`/`cierre`/`dias`→`opens_at`/`closes_at`/`open_days`;
`Notificacion`→`Notification` (Python) / `AppNotification` (Dart); `Aviso`→`Notice`, `Recordatorio`→`Reminder`, `CanalPush`→`PushChannel`,
`ResultadoDeEnvio`→`DeliveryResult`, `DatosDeReserva`→`BookingData`; `DatosInvalidos`→`InvalidData`, `Duplicado`→`Duplicate`,
`NoAutenticado`→`NotAuthenticated`, `Demorado`→`RateLimited`, `CuentaExistente`→`AccountExists`, `Prohibido`→`Forbidden`,
`NoDisponible`→`Unavailable`, `NumeroOcupado`→`NumberTaken`, `HorarioOcupado`→`SlotTaken`, `NoEncontrada`→`NotFound`,
`Cambiado`→`ConcurrentChange`, `ReservasAfuera`→`BookingsOutsideHours`, `AgendaCambiada`→`OpeningHoursChanged`,
`ConReservasFuturas`→`HasFutureBookings`; `reservar`→`book`, `cancelar_reserva`→`cancel_booking`, `modificar_reserva`→`modify_booking`,
`anular_reserva`→`void_booking`, `mis_reservas`→`my_bookings`, `historial_global`→`global_history`; `dar_de_alta_X`→`create_X`,
`dar_de_baja_X`→`deactivate_X`, `editar_X`→`update_X`, `validar_X`→`validate_X`; `registrar_usuario`→`register_user`,
`perfil_propio`→`own_profile`, `cambiar_contrasena`→`change_password`, `pedir_enlace`→`request_link`, `usar_enlace`→`use_link`;
`horarios_disponibles`→`available_slots`, `enviar_recordatorios`→`send_reminders`, `despachar_pendientes`→`dispatch_pending`,
`barrer_cada`→`sweep_every`; `nombre_compuesto`→`composite_name`, `en_transaccion`→`in_transaction`, `conexion`→`connection`,
`instalar`→`install`, `sembrar_admin`→`seed_admin`, `crear_app`→`create_app`, `_ciclo_de_vida`→`_lifespan`.
Dart: `ClienteApi`→`ApiClient`, `Respuesta`→`ApiResponse`, `RutaDeLaApi`→`ApiRoute`, `rutasDeLaApi`→`apiRoutes`, `rutaDeclarada`→`isDeclaredRoute`,
`SinConexion`→`Offline`, `ErrorDelServidor`→`ServerError`, `ServidorSinRespuesta`→`ServerTimeout`, `Sesion`→`Session`, `Perfil`→`Profile`,
`Rol`→`Role`, `CentroDeNotificaciones`→`NotificationCenter`, `Catalogo`→`Catalog`, `TipoDeCancha`→`SpaceKind`,
`EstadoDeReserva`→`BookingStatus`, `TipoDeNotificacion`→`NotificationKind` (con `label` en castellano y valor de API explícito, R1);
`Pantalla*`→`*Screen`, `Tarjeta*`→`*Card`, `Dialogo*`→`*Dialog`, `Cabecera*`→`*Header`, `Boton*`→`*Button`, `Campo*`→`*Field`.

## Rutas de pantalla y variables de entorno
go_router: `/registro[/exitoso]`→`/register[/done]`, `recuperar-contrasena`→`forgot-password`, `/recuperar`→`/recover`, `/inicio`→`/home`,
`buscar`→`search`, `/notificaciones`→`/notifications`, `/perfil`→`/profile`, `contrasena`→`password`,
`/sedes/:sede/canchas/:cancha/reservar`→`/venues/:venue/spaces/:space/book`, `/reservas/:reserva/modificar/confirmar`→`/bookings/:booking/modify/confirm`,
`confirmada`→`confirmed`, `/reservar`→`/book`, `?historial=1`→`?history=1`, `/admin/acceso-denegado`→`/admin/access-denied`,
`reserva/:id`→`booking/:id`, `/admin/sedes[/nueva|/:sede/editar|/creada]`→`/admin/venues[/new|/:venue/edit|/created]`, ídem `/admin/espacios`→`/admin/spaces`.
Env: `FIREBASE_CREDENCIALES_JSON`→`FIREBASE_CREDENTIALS_JSON`, `URL_PUBLICA`→`PUBLIC_URL`, `CORREO_MODO`→`EMAIL_MODE`, `SMTP_PUERTO`→`SMTP_PORT`,
`SMTP_USUARIO`→`SMTP_USER`, `SMTP_CONTRASENA`→`SMTP_PASSWORD`, `CORREO_REMITENTE`→`EMAIL_SENDER`, `PRUEBAS`→`E2E_TESTING`,
`RECORDATORIOS_CADA`→`REMINDERS_EVERY`; la config acepta el nombre nuevo y el viejo (`AliasChoices(nuevo, viejo)`).

## Reglas
- R1. Un enum cuyo `.name` llega a la UI o a la API recibe primero `label` en castellano y valor de API explícito; después se renombra.
- R2. Las claves del catálogo (`Futbol`, `F5`, `PDL`…) son datos: no se traducen.
- R3. Un nombre que el glosario no cubre se traduce con el mismo criterio y se agrega como ASM de la card que lo toca; nunca dos traducciones.
- R4. Títulos y docstrings con tag y nombres de archivo de test no cambian (281 líneas `replaces:` los nombran por título exacto); dentro de
  los tests cambia sólo lo que los renombres obligan (imports, símbolos, SQL, rutas, claves JSON), con `refactor-tests:`.

## Queda en castellano

Todo texto que ve el usuario, contenidos (títulos y cuerpos de avisos, correos), claves del catálogo y `space.name`, `dni`,
migraciones 0001–0010, `specs/` y registros, títulos y archivos de test (R4), la prosa de docs (cambian sólo los nombres citados).
