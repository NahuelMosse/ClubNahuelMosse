# Code glossary

The ClubNahuelMosse code is in English: modules, files, classes, functions, variables, comments, tables, columns, JSON fields and API routes. The texts the user sees are in English, the base language of the app, with a Spanish translation. This page fixes what each domain concept is called; a new name follows the same criterion. The first column of each table keeps the Spanish name it replaced.


Criteria: `reserva`→`booking` (not reservation); `sede`→`venue`; `espacio`→`space` (the catalog includes golf); `tipo`→`kind`
(`type` shadows the builtin); US spelling (`canceled`); timestamps `_at`; ranges `since`/`until`; table `usuario`→`app_user`
(`user` is reserved in Postgres).

## Folders and files
| Spanish | English |
|---|---|
| `apps/api/migraciones/` | `migrations/` (0001–0011 conservan su contenido) |
| `app/modules/` | `espacios`→`spaces`, `horarios`→`availability`, `notificaciones`→`notifications`, `recuperacion`→`password_recovery` |
| `app/modules/` | `reservas`→`bookings`, `sedes`→`venues`, `sesion`→`session`, `usuarios`→`users` |
| `casos_de_uso.py` / `reglas.py` / `repositorio.py` / `rutas.py` | `use_cases.py` / `rules.py` / `repository.py` / `routes.py` |
| `almacen.py` / `barrido.py` / `correo.py` / `disponibilidad.py` | `store.py` / `sweep.py` / `email.py` / `slots.py` |
| `perfil.py` / `usuario_actual.py` / `administradores.py` / `baja.py` | `profile.py` / `current_user.py` / `admins.py` / `deactivation.py` |
| `contrasena.py` / `registro.py` / `rutas_cuenta.py` / `rutas_registro.py` / `sembrar_admin.py` | `password.py` / `registration.py` / `account_routes.py` / `registration_routes.py` / `seed_admin.py` |
| `salud.py` / `pruebas.py` | `health.py` / `e2e_support.py` |
| `shared/{correo,mensaje,plantilla_correo}.py` / `reservas/correo.py` | `shared/{email,message,email_template}.py` / `bookings/email.py` |
| `html_de_correo` / `correo_de_reserva` / `tipo_corto` / `correo_recordatorio` | `html_email` / `booking_email` / `short_kind` / `reminder_email` |
| `Mensaje.para` / `.asunto` / `.cuerpo` | `Message.recipient` / `.subject` / `.body` |
| `shared/{credencial_firebase,cuerpo,entradas,errores,errores_http,identidad,respuestas,zona}.py` | `{firebase_credential,body_limit,input_validation,errors,http_errors,identity,responses,club_timezone}.py` |
| `apps/mobile/lib/` | `comun`→`common`, `tema`→`theme`, `inicio`→`home`, `espacios`→`spaces`, `sedes`→`venues`, `reservas`→`bookings`, `sesion`→`session`, `usuarios`→`users`, `notificaciones`→`notifications` (`admin`, `api` igual) |
| `lib/rutas.dart` / `lib/api/rutas.dart` / `lib/redireccion.dart` | `router.dart` / `api/api_routes.dart` / `redirect.dart` |
| `pantalla_X` / `tarjeta_X` / `dialogo_X` / `cabecera_X` | `X_screen` / `X_card` / `X_dialog` / `X_header` |

## Tables, view, functions, triggers
`usuario`→`app_user`, `sede`→`venue`, `espacio`→`space`, `reserva`→`booking`, `enlace_recuperacion`→`recovery_link`,
`correo_saliente`→`outgoing_email`, `dispositivo`→`device`, `notificacion`→`notification`, `notificacion_reserva`→`notification_booking`;
vista `reserva_con_estado`→`booking_with_status` (`estado_actual`→`current_status`); `marcar_modificado()`→`touch_updated_at()`,
`prohibir_borrado()`→`forbid_delete()`, `correo_inmutable()`→`email_immutable()`, `nombre_espacio_inmutable()`→`space_identity_immutable()`;
`uuid_v7()` unchanged; triggers `<t>_modificado`→`<t>_updated`, `<t>_sin_borrado`→`<t>_no_delete`,
`usuario_correo_inmutable`→`app_user_email_immutable`, `espacio_nombre_inmutable`→`space_name_immutable`.

## Columns
- all: `creado_en`→`created_at`, `modificado_en`→`updated_at`, `activo`/`activa`→`active`, `dado_de_baja_en`→`deactivated_at`,
  `dado_de_baja_por`→`deactivated_by`, `creado_por`→`created_by`, `modificado_por`→`updated_by`, `usuario_id`→`user_id`, `reserva_id`→`booking_id`
- app_user: `correo`→`email`, `nombre`→`first_name`, `apellido`→`last_name`, `fecha_nacimiento`→`birth_date`, `rol`→`role`,
  `contrasena_cambiada_en`→`password_changed_at`; `dni`, `firebase_uid` unchanged
- venue: `nombre`→`name`, `calle`→`street`, `altura`→`street_number`, `apertura`→`opens_at`, `cierre`→`closes_at`, `dias`→`open_days`
- space: `sede_id`→`venue_id`, `deporte`→`sport`, `tipo`→`kind`, `numero`→`number`, `nombre`→`name`, `techada`→`covered`,
  `iluminada`→`lit`, `precio_por_hora`→`price_per_hour`
- booking: `espacio_id`→`space_id`, `inicio`→`starts_at`, `fin`→`ends_at`, `precio_por_hora`→`price_per_hour`, `estado`→`status`,
  `cancelada_en`→`canceled_at`, `cancelada_por`→`canceled_by`, `motivo`→`reason`; `total` unchanged
- recovery_link: `codigo_hash`→`code_hash`, `vence_en`→`expires_at`, `usado_en`→`used_at`, `invalidado_en`→`invalidated_at`
- outgoing_email: `para`→`recipient`, `asunto`→`subject`, `cuerpo`→`body`
- device: `plataforma`→`platform`, `permiso`→`permission_granted`; `token` unchanged
- notification: `tipo`→`kind`, `titulo`→`title`, `cuerpo`→`body`, `reserva_inicio`→`booking_starts_at`, `envio`→`delivery`,
  `enviada_en`→`sent_at`, `leida_en`→`read_at`, `reemplazada_por`→`replaced_by`, `cantidad`→`count`, `enviando_desde`→`sending_since`
- notification_booking: `notificacion_id`→`notification_id`, `reserva_id`→`booking_id`

## Named indexes and constraints
`usuario_correo_unico`→`app_user_email_unique`, `usuario_dni_unico`→`app_user_dni_unique`, `sede_nombre_activa_unico`→`venue_name_active_unique`,
`dispositivo_token_activo`→`device_token_active`, `dispositivo_usuario`→`device_user`, `notificacion_recordatorio_unico`→`notification_reminder_unique`,
`notificacion_recordatorio_cinco_unico`→`notification_five_minute_reminder_unique`,
`notificacion_cancelacion_unica`→`notification_cancellation_unique`, `notificacion_usuario`→`notification_user`,
`notificacion_forzosa_sin_leer`→`notification_forced_unread`, `notificacion_por_despachar`→`notification_to_dispatch`,
`notificacion_por_reemplazada_por`→`notification_by_replaced_by`, `reserva_activa_inicio`→`booking_active_starts_at`,
`reserva_por_usuario_inicio`→`booking_by_user_starts_at`, `reserva_por_inicio`→`booking_by_starts_at`,
`reserva_por_cancelada_por`→`booking_by_canceled_by`, `enlace_recuperacion_por_usuario`→`recovery_link_by_user`,
`notificacion_envio_check`→`notification_delivery_check`, `notificacion_cancelacion_con_reserva`→`notification_cancellation_has_booking`;
autogenerated (`_pkey`, `_fkey`, `_check`, `_key`, `_excl`): the name Postgres would give with the new table and column, read from `pg_constraint` by migration 0012 (`apps/api/migrations/versions/0012_english_schema.py`), which applies this whole schema.

## Stored enum values (translated)
`booking.status`: `activa`→`active`, `cancelada`→`canceled`, `anulada`→`voided`, computed `completada`→`completed`.
`notification.delivery`: `pendiente`→`pending`, `enviando`→`sending`, `enviada`→`sent`, `sin_permiso`→`no_permission`, `sin_canal`→`no_channel`, `fallida`→`failed`.
`notification.kind`: `recordatorio`→`reminder`, `recordatorio_cinco`→`five_minute_reminder`, `cancelacion_forzosa`→`forced_cancellation`, `cancelacion_usuario`→`user_cancellation`.
`app_user.role`: `usuario`→`user`, `admin` unchanged. `device.platform` unchanged. Parameter `cuando`: `proximas`→`upcoming`, `historial`→`history`.
Setting `correo_modo`: `buzon`→`outbox`, `smtp` unchanged.

## API base (code names)
`Config`→`Settings` (`firebase_credenciales_json`→`firebase_credentials_json`, `url_publica`→`public_url`, `correo_modo`→`email_mode`, `smtp_puerto`→`smtp_port`, `smtp_usuario`→`smtp_user`, `smtp_contrasena`→`smtp_password`, `correo_remitente`→`email_sender`, `pruebas`→`e2e_testing`, `recordatorios_cada`→`reminders_every`; the environment variables accept the English name and the previous one, the English one wins);
`DatosInvalidos`→`InvalidData`, `Duplicado`→`Duplicate`, `NoAutenticado`→`NotAuthenticated`, `Demorado`→`RateLimited`, `CuentaExistente`→`AccountExists`, `Prohibido`→`Forbidden`, `NoDisponible`→`Unavailable`, `NumeroOcupado`→`NumberTaken`, `HorarioOcupado`→`SlotTaken`, `NoEncontrada`→`NotFound`, `Cambiado`→`ConcurrentChange`, `ReservasAfuera`→`BookingsOutsideHours`, `AgendaCambiada`→`OpeningHoursChanged`, `ConReservasFuturas`→`HasFutureBookings`;
`motor`→`engine`, `conexion`→`connection`, `Conexion`→`DbConnection`, `en_transaccion`→`in_transaction`, `restriccion_violada`→`violated_constraint`, `VENTANA_DE_REINTENTO`→`RETRY_WINDOW`;
`CuerpoAcotado`→`BodyLimit`, `Identificador`→`Identifier`, `leer_hora`→`parse_time`, `errores_de_forma`→`shape_errors`, `conflicto`→`conflict`, `credencial_de_servicio`→`service_credential`, `ZONA_CLUB`→`CLUB_TIMEZONE`, `crear_app`→`create_app`;
`ProveedorFirebase`→`FirebaseProvider` (`crear_cuenta`→`create_account`, `uid_de`→`uid_of`, `borrar_cuenta`→`delete_account`, `uid_del_token`→`uid_from_token`, `contrasena_correcta`→`password_matches`, `cambiar_contrasena`→`change_password`), `identidad`→`identity`.

## API routes
`POST /registro`→`/register`; `/yo`→`/me`, `/yo/contrasena`→`/me/password`; `/recuperacion`→`/password-recovery`,
`/recuperacion/consulta`→`/password-recovery/check`; `/enlace/recuperar`→`/link/recover`; `/sedes[/{sede_id}]`→`/venues[/{venue_id}]`;
`/espacios`→`/spaces`, `/espacios/catalogo`→`/spaces/catalog`, `/espacios/nombre`→`/spaces/name`, `/espacios/disponibles`→`/spaces/available`,
`/espacios/{espacio_id}`→`/spaces/{space_id}`, `/espacios/{espacio_id}/horarios`→`/spaces/{space_id}/slots`;
`/reservas`→`/bookings`, `/reservas/{id}/{cancelar,modificar,anular}`→`/bookings/{booking_id}/{cancel,modify,void}`,
`/reservas/todas[/{id}]`→`/bookings/all[/{booking_id}]`; `PUT /dispositivos`→`/devices`, `/dispositivos/baja`→`/devices/unregister`;
`/notificaciones`→`/notifications`, `/leer-todas`→`/read-all`, `/{id}/leer`→`/{notification_id}/read`; `/health` unchanged (body
`{"estado":"vivo"}`→`{"status":"ok"}`); `/_pruebas/...`→`/_testing/{emails, bookings[/clear,/start,/void], venues/deactivate, spaces/deactivate, password-recovery/{code}/expire, reminders, devices}`.
Query: `sede_id`→`venue_id`, `deporte`→`sport`, `tipo`→`kind`, `fecha`→`date`, `horas`→`hours`, `reserva_id`→`booking_id`,
`desde`/`hasta`→`since`/`until`, `cuando`→`when`, `estado`→`status`, `pagina`→`page`; `q` unchanged.

## JSON fields
`errores`→`errors` (keys as in this glossary; `cambio`→`change`); `nombre`→`first_name` (person) / `name` (venue, space, sport),
`apellido`→`last_name`, `correo`→`email`, `contrasena`→`password`, `fecha_nacimiento`→`birth_date`, `rol`→`role`;
`actual`→`current_password`, `nueva`→`new_password`, `codigo`→`code`; `direccion`→`address`, `apertura`→`opens_at`, `cierre`→`closes_at`,
`dias`→`open_days`, `confirmar`→`confirm`, `canchas`→`space_count`, `deportes`→`sports`; `sede_id`→`venue_id`, `sede`→`venue`,
`espacio_id`→`space_id`, `espacio`→`space`, `deporte`→`sport`, `tipo`→`kind`, `tipos`→`kinds`, `clave`→`key`; `numero`→`number`,
`techada`→`covered`, `iluminada`→`lit`, `precio_por_hora`→`price_per_hour`; `inicio`→`starts_at`, `fin`→`ends_at`, `fecha`→`date`,
`desde`→`start_hour`, `horas`→`hours`, `hoy`→`today`, `abre`→`opens`, `franjas`→`slots`, `disponible`→`available`, `no_disponibles`→`unavailable`;
`estado`→`status`, `motivo`→`reason`, `anulable`→`voidable`; `total`, `cancelable` unchanged; `usuario_id`→`user_id`, `usuario`→`user`,
`creado_en`→`created_at`, `cancelada_en`→`canceled_at`, `cancelada_por_nombre`→`canceled_by_name`; `espacio_de_baja`→`space_deactivated`,
`aviso_envio`→`notice_delivery`, `aviso_en`→`notice_at`; `reservas`→`bookings`, `pagina`→`page`, `por_pagina`→`per_page`,
`contadores`→`counters` (`todas`→`all`, `activas`→`active`, `completadas`→`completed`, `anuladas`→`voided`); `espacios`→`spaces`, `sedes`→`venues`,
`reservas_afuera`→`bookings_outside`; `notificaciones`→`notifications`, `no_leidas`→`unread`, `titulo`→`title`, `cuerpo`→`body`,
`creada_en`→`created_at`, `leida`→`read`; `plataforma`→`platform`, `permiso`→`permission_granted`, `mensaje`→`message`, `campos`→`fields`;
datos push `tipo`→`kind`, `reserva_id`→`booking_id`; enlace `clubnahuelmosse://app/recuperar#codigo=`→`app/recover#code=`.
Error and body keys the glossary did not name (ENG-18): `fechas`→`dates`, `hasta` (error key)→`until`, `cuerpo` (error key of an unreadable body)→`body`,
`horario`→`slot`, `reserva` (error key)→`booking`, `hora`→`hour`. The error key vocabulary is the same for the body and the query: `start_hour`, `until`, `date`, `hours`.
Test support (`/_testing`): `emails?to=`, `bookings[/clear,/start,/void]`, `venues/deactivate`, `spaces/deactivate`, `password-recovery/{code}/expire`, `reminders`, `devices?email=`;
body keys `space`, `date`, `hour`, `hours`, `email`, `status`, `reason`, `name`, `now`, `registered`, `subject`, `body`, `emails`, `devices`, `permission_granted`.

## Main classes and functions
`Reserva`→`Booking`, `ReservaHistorial`→`BookingHistoryEntry`, `HistorialDeReservas`→`BookingHistory`, `FiltrosHistorial`→`HistoryFilters`,
`Contadores`→`Counters`, `ReservasSql`→`BookingsSql`, `Cuando`→`When`; `Sede`→`Venue`, `SedeNueva`→`NewVenue`, `SedeDelEspacio`→`SpaceVenue`,
`Espacio`→`Space`, `EspacioNuevo`→`NewSpace`, `CambioDeEspacio`→`SpaceChange`; `Deporte`→`Sport`, `Tipo`→`Kind`, `NombreSugerido`→`SuggestedName`,
`CATALOGO`→`CATALOG`; `Agenda`→`OpeningHours`, `Franja`→`Slot`, `Grilla`→`SlotGrid`, `Horarios`→`Availability`;
`DatosEspacio`→`SpaceData`, `Espacios`→`Spaces`, `EspaciosSql`→`SpacesSql`, `HorariosSql`→`AvailabilitySql`, `Disponibilidad`→`SlotSearch`,
`ListaDeEspacios`→`SpaceList`, `EspacioVista`→`SpaceView`, `TipoVista`→`KindView`, `DeporteVista`→`SportView`, the catalog view `CatalogView` (in Python `Catalogo` becomes `CatalogView`, not `Catalog`),
`Sugerencia`→`Suggestion`, `Errores` (espacios y horarios) → `ErrorBody`, `PedidoDeEspacio`→`SpaceRequest`, `PedidoDeCambioDeEspacio`→`SpaceChangeRequest`;
`catalogo`→`catalog`, `nombre_sugerido`→`suggested_name`, `espacios_activos`→`active_spaces`, `tipo_del_catalogo`→`catalog_kind`,
`parte_de_sede`→`venue_part`, `parte_de_calle`→`street_part`, `espacio_de_fila`→`space_of_row`, `agenda_de_fila`→`opening_hours_of_row`,
`repositorio_espacios`→`spaces_repository`, `repositorio_horarios`→`availability_repository`, `vista_de_espacio`→`space_view`,
`canchas_disponibles`→`available_spaces`, `grilla`→`slot_grid`, `rango`→`time_range`, `error_de_duracion`→`duration_error`,
`validar_consulta`→`validate_query`, `validar_rango`→`validate_range`, `validar_reserva`→`validate_booking`, `validar_cambio`→`validate_change`
(kwarg `dados`→`given`), `COLUMNAS_DE_ESPACIO`→`SPACE_COLUMNS`, `DIAS_A_LA_VISTA`→`DAYS_IN_VIEW`, `MIN_HORAS`/`MAX_HORAS`→`MIN_HOURS`/`MAX_HOURS`,
`HORAS_POR_DIA`→`HOURS_PER_DAY`; availability views `SlotView`, `SlotGridView`; route functions `ver_catalogo`→`show_catalog`,
`listar_espacios`→`list_spaces`, `sugerir_nombre`→`suggest_name`, `alta_de_espacio`→`create_space_route`, `edicion_de_espacio`→`update_space_route`,
`baja_de_espacio`→`deactivate_space_route`, `ver_horarios`→`show_slots`, `ver_disponibles`→`show_available`; repository methods `activos`→`active`, `siguiente`→`next_number`, `insertar`→`insert`, `actualizar`→`update`,
`dar_de_baja`→`deactivate`, `dar_de_baja_de_sede`→`deactivate_venue_spaces`, `agenda`→`opening_hours`, `agenda_de_sede`→`venue_opening_hours`,
`ocupadas`→`taken`, `libres`→`free`; attributes `fecha`→`day` (in `SlotGrid`, so as not to shadow the `date` type), `hoy`→`today`, `abre`→`opens`,
`franjas`→`slots`, `no_disponibles`→`unavailable`, `inicio`/`fin`→`start`/`end`, `disponible`→`available`, `apertura`/`cierre`/`dias`→`opens_at`/`closes_at`/`open_days`;
`Notificacion`→`Notification` (Python) / `AppNotification` (Dart); `Aviso`→`Notice`, `Recordatorio`→`Reminder`, `CanalPush`→`PushChannel`,
`ResultadoDeEnvio`→`DeliveryResult`, `DatosDeReserva`→`BookingData`, `Pendiente`→`PendingNotice`, `AvisoPerdido`→`LostNotice`,
`ReservaAnulada`→`VoidedBooking`, `CanalNulo`→`NullChannel`, `CanalFcm`→`FcmChannel`, `CanalNoConfigurado`→`ChannelNotConfigured`,
`TipoDeAviso`→`NoticeKind`, `Envio`→`Delivery`, `PedidoDeDispositivo`→`DeviceRequest`, `BajaDeDispositivo`→`DeviceUnregistration`,
`Errores`→`Errors`, `NotificacionVista`→`NotificationView`, `Centro`→`Center`, `ANTICIPACION`→`LEAD_TIME`, `DIAS`→`WEEKDAYS`,
`LIMITE_DEL_MOTIVO`→`REASON_LIMIT`, `ESPERA_DEL_RECORDATORIO`→`REMINDER_GRACE`, `ESPERA_DEL_ENVIO`→`SENDING_TIMEOUT`,
`LIMITE_DEL_CENTRO`→`CENTER_LIMIT`, `PLATAFORMAS`→`PLATFORMS`; functions: `entregar`→`deliver`, `despachar_pendientes`→`dispatch_pending`,
`enviar_recordatorios`→`send_reminders`, `registrar_dispositivo`→`register_device`, `dar_de_baja_dispositivo`→`deactivate_device`,
`mis_notificaciones`→`my_notifications`, `marcar_leida`→`mark_read`, `marcar_todas`→`mark_all_read`, `tipo_corto`→`short_kind`,
`mensaje_recordatorio`→`reminder_message`, `mensaje_cancelacion`→`cancellation_message`, `encolar_cancelacion_forzosa`→`enqueue_forced_cancellation`,
`repositorio_notificaciones`→`notifications_repository`, `barrer_una_vez`→`sweep_once`, `barrer_cada`→`sweep_every`, `canal_push`→`push_channel`,
`armar_mensaje`→`build_message`, `despachar_de`→`dispatch_for`; `DatosInvalidos`→`InvalidData`, `Duplicado`→`Duplicate`,
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
Venues, users, session and recovery (API): `Perfiles`→`Profiles`, `SinSesion`→`NoSession`, `usuario_actual`→`current_user`, `PerfilesSql`→`ProfilesSql`,
`repositorio_perfiles`→`profile_repository`, `perfil_autenticado`→`authenticated_profile`, `perfil_activo`→`active_profile`, `VerificadorDeTokens`→`TokenVerifier`,
`DatosSede`→`VenueData`, `SedesSql`→`VenuesSql`, `repositorio_sedes`→`venue_repository`, `sedes_activas`→`active_venues`, `SedeVista`→`VenueView`,
`PedidoDeSede`→`VenueRequest`, `UsuariosSql`→`UsersSql`, `repositorio_usuarios`→`user_repository`, `RepositorioUsuarios`→`UserRepository`,
`ProveedorIdentidad`→`IdentityProvider`, `DatosRegistro`→`RegistrationData`, `Registro`→`Registration`, `validar_registro`→`validate_registration`,
`normalizar_correo`→`normalize_email`, `correo_valido`→`valid_email`, `normalizar_dni`→`normalize_dni`, `problemas_contrasena`→`password_problems`,
`DatosPersonales`→`PersonalData`, `PerfilEditado`→`EditedProfile`, `validar_edicion`→`validate_edit`, `editar_perfil`→`update_profile`,
`dar_de_baja`→`deactivate`, `PerfilPropio`→`OwnProfile`, `EnlacesSql`→`LinksSql`, `repositorio_enlaces`→`link_repository`,
`RepositorioEnlaces`→`LinkRepository`, `hash_de`→`hash_of`, `enlace_vigente`→`link_is_valid`, `Mensaje`→`Message`, `Destinatario`→`Recipient`,
`EnlaceReclamado`→`ClaimedLink`, `EnlaceInvalido`→`InvalidLink`, `enviar`→`send`; `Pedido*`→`*Request`, `*Vista`→`*View`, `ErroresDe*`→`*Errors`.
Module `bookings`: `Estado`→`Status`, `FiltroEstado`→`StatusFilter`, `POR_PAGINA`→`PAGE_SIZE`; protocol `Reservas`→`Bookings` (`de_usuario`→`of_user`,
`agenda`→`opening_hours`, `repetida`→`repeated`, `propia`→`own`, `tipo_de_espacio`→`space_kind`, `mover`→`move`, `cancelar`→`cancel`,
`insertar`→`insert`, `anular`→`void`, `historial`→`history`, `una_de_cualquiera`→`any_one`; en `BookingsSql` también `cancelar_futuras_de`→`cancel_future_of`);
use cases `detalle_admin`→`admin_detail`; constants `MOTIVO_MAXIMO`→`MAX_REASON_LENGTH`, `INTENTOS_CON_AGENDA_NUEVA`→`ATTEMPTS_WITH_NEW_HOURS`,
`PAGINA_MAXIMA`→`MAX_PAGE`, `OCUPADO`→`SLOT_TAKEN_MESSAGE`, `NO_DISPONIBLE`→`UNAVAILABLE_MESSAGE`, `CAMBIO`→`CHANGED_MESSAGE`;
HTTP schemas `ReservaVista`→`BookingView`, `ReservaHistorialVista`→`BookingHistoryView`, `ListaDeReservas`→`BookingList`, `PedidoDeReserva`→`BookingRequest`,
`PedidoDeCambioDeReserva`→`BookingChangeRequest`, `PedidoDeAnulacion`→`VoidRequest`, `HistorialVista`→`HistoryView`, `ContadoresVista`→`CountersView`,
`Errores`→`Errors` (los de `bookings`), `_vista`→`_view`, `_vista_admin`→`_admin_view`; handlers `listar_reservas`→`list_bookings`,
`hacer_reserva`→`create_booking`, `cancelar`→`cancel`, `modificar`→`modify`, `listar_todas`→`list_all`, `detalle`→`detail`, `anular`→`void`;
provider `repositorio_reservas`→`bookings_repository`.
Dart: `ClienteApi`→`ApiClient`, `Respuesta`→`ApiResponse`, `RutaDeLaApi`→`ApiRoute`, `rutasDeLaApi`→`apiRoutes`, `rutaDeclarada`→`isDeclaredRoute`,
`SinConexion`→`Offline`, `ErrorDelServidor`→`ServerError`, `ServidorSinRespuesta`→`ServerTimeout`, `Sesion`→`Session`, `Perfil`→`Profile`,
`Rol`→`Role`, `CentroDeNotificaciones`→`NotificationCenter`, `Catalogo`→`Catalog`, `TipoDeCancha`→`SpaceKind`,
`EstadoDeReserva`→`BookingStatus`, `TipoDeNotificacion`→`NotificationKind` (with a Spanish `label` and an explicit API value, R1);
`Pantalla*`→`*Screen`, `Tarjeta*`→`*Card`, `Dialogo*`→`*Dialog`, `Cabecera*`→`*Header`, `Boton*`→`*Button`, `Campo*`→`*Field`.

## Screen routes and environment variables
go_router: `/registro[/exitoso]`→`/register[/done]`, `recuperar-contrasena`→`forgot-password`, `/recuperar`→`/recover`, `/inicio`→`/home`,
`buscar`→`search`, `/notificaciones`→`/notifications`, `/perfil`→`/profile`, `contrasena`→`password`,
`/sedes/:sede/canchas/:cancha/reservar`→`/venues/:venue/spaces/:space/book`, `/reservas/:reserva/modificar/confirmar`→`/bookings/:booking/modify/confirm`,
`confirmada`→`confirmed`, `/reservar`→`/book`, `?historial=1`→`?history=1`, `/admin/acceso-denegado`→`/admin/access-denied`,
`reserva/:id`→`booking/:id`, `/admin/sedes[/nueva|/:sede/editar|/creada]`→`/admin/venues[/new|/:venue/edit|/created]`, likewise `/admin/espacios`→`/admin/spaces`.
Env: `FIREBASE_CREDENCIALES_JSON`→`FIREBASE_CREDENTIALS_JSON`, `URL_PUBLICA`→`PUBLIC_URL`, `CORREO_MODO`→`EMAIL_MODE`, `SMTP_PUERTO`→`SMTP_PORT`,
`SMTP_USUARIO`→`SMTP_USER`, `SMTP_CONTRASENA`→`SMTP_PASSWORD`, `CORREO_REMITENTE`→`EMAIL_SENDER`, `PRUEBAS`→`E2E_TESTING`,
`RECORDATORIOS_CADA`→`REMINDERS_EVERY`; the settings accept the new name and the old one (`AliasChoices(new, old)`).

## Rules
- R1. An enum whose `.name` reaches the UI or the API first gets a Spanish `label` and an explicit API value; then it is renamed.
- R2. The catalog keys (`Futbol`, `F5`, `PDL`…) are data: they are not translated.
- R3. A name the glossary does not cover is translated with the same criterion and added as an ASM of the card that touches it; never two translations.
- R4. Titles and docstrings with a tag and test file names do not change (281 `replaces:` lines name them by exact title); inside
  the tests only what the renames force changes (imports, symbols, SQL, routes, JSON keys), with `refactor-tests:`.

## What stays in Spanish

The Spanish translation of the app texts, the contents of notices and emails, the catalog keys and `space.name`, `dni`,
migrations 0001–0010 and 0011, `specs/` and the method records, test titles and files (R4).
