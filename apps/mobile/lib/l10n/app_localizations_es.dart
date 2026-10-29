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
  String adminVenueSchedule(Object closing, Object days, Object opening) {
    return '$days de $opening a $closing';
  }

  @override
  String adminVenueScheduleShort(Object closing, Object days, Object opening) {
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
    Object date,
    Object schedule,
    Object sport,
    Object user,
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
  String adminDeactivateVenueText(Object address, Object name) {
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
  String get loginSignIn => 'INICIAR SESIÓN';

  @override
  String get loginEmailRequired => 'Completá tu correo electrónico';

  @override
  String get loginPasswordRequired => 'Completá tu contraseña';

  @override
  String get loginInvalidCredentials =>
      'No se pudo iniciar sesión. Revisá tus datos e intentá de nuevo.';
}
