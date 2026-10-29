// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Club Nahuel Mosse';

  @override
  String get loginWelcome => 'BIENVENIDO A';

  @override
  String get loginTagline => 'Gestión de espacios deportivos';

  @override
  String get loginEmailLabel => 'Correo';

  @override
  String get loginPasswordLabel => 'Contraseña';

  @override
  String get loginForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get loginNoAccount => '¿No tenés cuenta?';

  @override
  String get loginStart => 'COMENZAR';

  @override
  String get adminPanelTitle => 'PANEL ADMIN';

  @override
  String get adminRetry => 'REINTENTAR';

  @override
  String get adminVenuesTitle => 'Sedes';

  @override
  String get adminAddVenue => 'AGREGAR SEDE';

  @override
  String adminActiveVenues(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count SEDES ACTIVAS',
      one: '1 SEDE ACTIVA',
    );
    return '$_temp0';
  }

  @override
  String get adminNoVenues => 'Todavía no hay sedes';

  @override
  String get adminSpacesTitle => 'Espacios';

  @override
  String get adminAddSpace => 'ALTA ESPACIO';

  @override
  String adminSpacesSummary(num spaces, num venues) {
    String _temp0 = intl.Intl.pluralLogic(
      spaces,
      locale: localeName,
      other: '$spaces ESPACIOS ACTIVOS',
      one: '1 ESPACIO ACTIVO',
    );
    String _temp1 = intl.Intl.pluralLogic(
      venues,
      locale: localeName,
      other: '$venues SEDES',
      one: '1 SEDE',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get adminNoSpaces => 'Todavía no hay espacios';

  @override
  String adminCourtsLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'CANCHAS',
      one: 'CANCHA',
    );
    return '$_temp0';
  }

  @override
  String adminCourtsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canchas',
      one: '1 cancha',
    );
    return '$_temp0';
  }

  @override
  String adminVenueSchedule(Object days, Object opening, Object closing) {
    return '$days de $opening a $closing';
  }

  @override
  String adminVenueScheduleShort(Object days, Object opening, Object closing) {
    return '$days · $opening a $closing';
  }

  @override
  String get adminEditVenue => 'Editar sede';

  @override
  String adminEditVenueNamed(Object name) {
    return 'Editar sede $name';
  }

  @override
  String get adminDeactivateVenue => 'Dar de baja';

  @override
  String adminDeactivateVenueNamed(Object name) {
    return 'Dar de baja $name';
  }

  @override
  String get adminEditSpace => 'Editar';

  @override
  String adminEditSpaceNamed(Object name) {
    return 'Editar $name';
  }

  @override
  String get adminDeactivateSpace => 'Baja';

  @override
  String adminDeactivateSpaceNamed(Object name) {
    return 'Baja $name';
  }

  @override
  String adminDeactivatingNamed(Object name) {
    return 'Dando de baja $name';
  }

  @override
  String get adminSpaceDeactivated => 'Baja del espacio deportivo';

  @override
  String get adminLoadingBookings => 'Cargando reservas…';

  @override
  String get adminNoResults => 'Sin resultados';

  @override
  String get adminNoResultsText =>
      'Ninguna reserva coincide con los filtros aplicados.';

  @override
  String get adminClearFilters => 'LIMPIAR FILTROS';

  @override
  String get adminNoBookings => 'No hay reservas';

  @override
  String get adminNoBookingsText =>
      'Todavía no se registró ninguna reserva en el sistema.';

  @override
  String get adminStatusActive => 'ACTIVA';

  @override
  String get adminStatusCompleted => 'COMPLETADA';

  @override
  String get adminStatusCanceled => 'CANCELADA';

  @override
  String get adminStatusVoided => 'ANULADA';

  @override
  String get adminFilterAll => 'Todas';

  @override
  String get adminFilterActive => 'Activas';

  @override
  String get adminFilterCompleted => 'Completadas';

  @override
  String get adminFilterCanceled => 'Canceladas';

  @override
  String get adminFilterVoided => 'Anuladas';

  @override
  String get adminVoidBooking => 'ANULAR RESERVA';

  @override
  String adminVoidBookingLabel(
    Object user,
    Object sport,
    Object date,
    Object schedule,
  ) {
    return 'Anular la reserva de $user, $sport, $date, $schedule';
  }

  @override
  String adminVoidBookingFor(Object user) {
    return 'Anular la reserva de $user';
  }

  @override
  String get adminVoidingBooking => 'Anulando la reserva';

  @override
  String get adminBackToList => 'VOLVER AL LISTADO';

  @override
  String get adminVenueWord => 'sede';

  @override
  String get adminUserWord => 'usuario';

  @override
  String get adminBack => 'Volver';

  @override
  String get adminBookingDetailTitle => 'Detalle de reserva';

  @override
  String get adminVenueUpper => 'SEDE';

  @override
  String get adminSportUpper => 'DEPORTE';

  @override
  String get adminStatusUpper => 'ESTADO';

  @override
  String get adminDateRangeUpper => 'RANGO DE FECHAS';

  @override
  String get adminSearchBooking => 'Buscar reserva';

  @override
  String get adminSearchShort => 'Buscar';

  @override
  String get adminFilters => 'Filtros';

  @override
  String get adminUser => 'Usuario';

  @override
  String get adminVenue => 'Sede';

  @override
  String get adminCourt => 'Cancha';

  @override
  String get adminWhen => 'Cuándo';

  @override
  String get adminAmount => 'Importe';

  @override
  String get adminBookingsTitle => 'Reservas';

  @override
  String adminResultsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count RESULTADOS',
      one: '1 RESULTADO',
    );
    return '$_temp0';
  }

  @override
  String adminTotalBookings(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count RESERVAS EN TOTAL',
      one: '1 RESERVA EN TOTAL',
    );
    return '$_temp0';
  }

  @override
  String get adminDeactivateVenueTitle => '¿Dar de baja la sede?';

  @override
  String get adminDeactivateConfirm => 'DAR DE BAJA';

  @override
  String get adminCancel => 'CANCELAR';

  @override
  String get adminAccept => 'ACEPTAR';

  @override
  String get adminVenueHasBookingsTitle => 'No se puede dar de baja la sede';

  @override
  String get adminVenueHasBookingsText =>
      'La sede posee reservas futuras asociadas a sus espacios deportivos. Gestionalas primero.';

  @override
  String get adminDeactivateSpaceTitle => '¿Dar de baja el espacio?';

  @override
  String adminDeactivateSpaceText(Object name) {
    return '$name. La acción es permanente.';
  }

  @override
  String get adminDeactivateSpaceConfirm => 'CONFIRMAR BAJA';

  @override
  String get adminSpaceHasBookingsTitle => 'No se puede dar de baja el espacio';

  @override
  String get adminSpaceHasBookingsText =>
      'El espacio posee reservas futuras. Gestionalas primero.';

  @override
  String adminDeactivateVenueText(Object name, Object address) {
    return '$name · $address. Sus espacios deportivos dejan de estar disponibles.';
  }

  @override
  String get adminVenueDeactivated => 'La sede fue dada de baja correctamente';

  @override
  String get adminSpaceDeactivatedDone =>
      'El espacio fue dado de baja correctamente';

  @override
  String get adminClear => 'LIMPIAR';

  @override
  String get adminApply => 'APLICAR';

  @override
  String get adminClose => 'Cerrar';

  @override
  String get adminSince => 'Desde';

  @override
  String get adminUntil => 'Hasta';

  @override
  String get adminDatePlaceholder => 'DD / MM / AAAA';

  @override
  String get adminInvalidDate => 'Fecha inválida';

  @override
  String get adminSinceAfterUntil => 'Desde no puede ser posterior a Hasta';

  @override
  String get adminUntilBeforeSince => 'Hasta no puede ser anterior a Desde';

  @override
  String get adminRequiredField => 'Este campo es obligatorio';

  @override
  String get adminPriceRange => 'Ingresá un precio entre \$ 1 y \$ 9.999.999';

  @override
  String get adminMissingAll => 'Completá sede, deporte y tipo';

  @override
  String get adminMissingVenue => 'Falta la sede';

  @override
  String get adminMissingSport => 'Falta el deporte';

  @override
  String get adminMissingType => 'Falta el tipo de cancha';

  @override
  String get adminSpaceFormHint =>
      'El nombre se arma solo con la sede, la dirección, el deporte, el tipo y el número.';

  @override
  String get adminCondition => 'Condición';

  @override
  String get adminConditionUpper => 'CONDICIÓN';

  @override
  String get adminLighting => 'Iluminación';

  @override
  String get adminLightingUpper => 'ILUMINACIÓN';

  @override
  String get adminCovered => 'Techada';

  @override
  String get adminOpenAir => 'Al aire libre';

  @override
  String get adminLit => 'Iluminada';

  @override
  String get adminUnlit => 'Sin iluminación';

  @override
  String get adminSelect => 'Seleccioná';

  @override
  String get adminSelectVenue => 'Seleccioná una sede';

  @override
  String get adminSelectSport => 'Seleccioná un deporte';

  @override
  String get adminSelectType => 'Seleccioná el tipo';

  @override
  String get adminSport => 'Deporte';

  @override
  String get adminType => 'Tipo';

  @override
  String get adminTypeUpper => 'TIPO';

  @override
  String get adminNewSpaceTitle => 'Nuevo espacio';

  @override
  String get adminNewSpaceHeading => 'Nuevo espacio deportivo';

  @override
  String get adminEditSpaceTitle => 'Editar espacio';

  @override
  String get adminEditSpaceHeading => 'Editar espacio deportivo';

  @override
  String get adminSaveSpace => 'GUARDAR ESPACIO';

  @override
  String get adminChangesSaved => 'Los cambios se guardaron correctamente';

  @override
  String get adminGeneratedName => 'NOMBRE GENERADO AUTOMÁTICAMENTE';

  @override
  String get adminNameFailed => 'No se pudo calcular el nombre';

  @override
  String get adminPricePerHour => 'Precio por hora';

  @override
  String get adminPricePerHourUpper => 'PRECIO POR HORA';

  @override
  String get adminGoToList => 'IR AL LISTADO';

  @override
  String get adminSpaceCreatedTitle => '¡Espacio deportivo creado!';

  @override
  String get adminSpaceCreatedText =>
      'Ya está disponible para que los usuarios lo reserven.';

  @override
  String get adminCreateAnother => 'Crear otro';

  @override
  String get adminVenueCreatedTitle => '¡Sede creada!';

  @override
  String get adminVenueCreatedText =>
      'La sede ya aparece en el listado y podés empezar a cargarle espacios deportivos.';

  @override
  String get adminCreateAnotherVenue => 'Crear otra sede';

  @override
  String get adminDeactivatingSpace => 'Dando de baja el espacio';

  @override
  String get adminDeactivateSpaceButton => 'DAR DE BAJA EL ESPACIO';

  @override
  String get adminTraceTitle => 'TRAZABILIDAD';

  @override
  String get adminTraceCreated => 'Reserva creada';

  @override
  String adminTraceBy(Object who, Object date) {
    return 'Por $who · $date';
  }

  @override
  String adminTraceByReason(Object who, Object date, Object reason) {
    return 'Por $who · $date · $reason';
  }

  @override
  String get adminTraceVoided => 'Anulada por el administrador';

  @override
  String get adminTraceAnAdmin => 'un administrador';

  @override
  String get adminTraceCanceled => 'Cancelada por el usuario';

  @override
  String get adminTraceNoticeSent => 'Notificación enviada al usuario';

  @override
  String get adminTraceNoticeInbox => 'Aviso en el centro del usuario';

  @override
  String get adminTracePushFailed => 'El push no salió';

  @override
  String get adminVoidReasonSemantics => 'Motivo de la anulación';

  @override
  String get adminVoidReasonLabel => 'MOTIVO DE LA ANULACIÓN';

  @override
  String get adminVoidReasonRequired => 'El motivo es obligatorio para anular';

  @override
  String get adminVoidDialogTitle => '¿Anular esta reserva?';

  @override
  String get adminVoidConfirm => 'CONFIRMAR ANULACIÓN';

  @override
  String get adminBackUpper => 'VOLVER';

  @override
  String get adminNewVenueHeading => 'Nueva sede';

  @override
  String get adminAddVenueTitle => 'Agregar sede';

  @override
  String get adminVenueFormHint =>
      'Nombre, dirección y horarios son obligatorios.';

  @override
  String get adminVenueNameUpper => 'NOMBRE DE LA SEDE';

  @override
  String get adminVenueName => 'Nombre de la sede';

  @override
  String get adminVenueNamePlaceholder => 'Ej. Sede Haedo';

  @override
  String get adminAddressUpper => 'DIRECCIÓN';

  @override
  String get adminAddress => 'Dirección';

  @override
  String get adminAddressPlaceholderNew => 'Calle y altura';

  @override
  String get adminAddressPlaceholderEdit => 'Escribí la dirección';

  @override
  String get adminOpeningUpper => 'HORARIO DE APERTURA';

  @override
  String get adminOpening => 'Horario de apertura';

  @override
  String get adminClosingUpper => 'HORARIO DE CIERRE';

  @override
  String get adminClosing => 'Horario de cierre';

  @override
  String get adminOpenDaysUpper => 'DÍAS QUE ABRE';

  @override
  String get adminOpenDays => 'Días que abre';

  @override
  String get adminSaveVenue => 'GUARDAR SEDE';

  @override
  String get adminSaveChanges => 'GUARDAR CAMBIOS';

  @override
  String get adminDeactivatingVenue => 'Dando de baja la sede';

  @override
  String get adminDeactivateVenueButton => 'DAR DE BAJA LA SEDE';

  @override
  String get adminVenueNameRequired => 'El nombre es obligatorio';

  @override
  String get adminVenueAddressRequired => 'La dirección es obligatoria';

  @override
  String get adminVenueAddressStreet => 'Escribí la calle y la altura';

  @override
  String get adminOpensAtRequired => 'El horario de apertura es obligatorio';

  @override
  String get adminClosesAtRequired => 'El horario de cierre es obligatorio';

  @override
  String get adminClosesBeforeOpens =>
      'El cierre tiene que ser después de la apertura';

  @override
  String adminOutsideSubject(num count, Object venue) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reservas futuras de $venue',
      one: '1 reserva futura de $venue',
    );
    return '$_temp0';
  }

  @override
  String adminOutsideStartsBefore(num count, Object hour) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'empiezan',
      one: 'empieza',
    );
    return '$_temp0 antes de las $hour';
  }

  @override
  String adminOutsideEndsAfter(num count, Object hour) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'terminan',
      one: 'termina',
    );
    return '$_temp0 después de las $hour';
  }

  @override
  String adminOutsideClosedDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'caen',
      one: 'cae',
    );
    return '$_temp0 en un día que la sede deja de abrir';
  }

  @override
  String adminOutsideNewSchedule(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'quedan',
      one: 'queda',
    );
    return '$_temp0 fuera del horario nuevo';
  }

  @override
  String adminOutsideKeeps(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'se mantienen',
      one: 'se mantiene',
    );
    return '$_temp0 en su horario original';
  }

  @override
  String adminOutsideNotice(Object subject, Object reason, Object keeps) {
    return '$subject $reason. Si guardás, $keeps: el cambio rige para las reservas nuevas.';
  }

  @override
  String get loginSignIn => 'INICIAR SESIÓN';

  @override
  String get loginEmailRequired => 'Completá tu correo electrónico';

  @override
  String get loginPasswordRequired => 'Completá tu contraseña';

  @override
  String get loginInvalidCredentials =>
      'No se pudo iniciar sesión. Revisá tus datos e intentá de nuevo.';
}
