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
  String get bookingStatusActive => 'Activa';

  @override
  String get bookingStatusCompleted => 'Completada';

  @override
  String get bookingStatusCanceled => 'Cancelada';

  @override
  String get bookingStatusVoided => 'Anulada';

  @override
  String get bookingMyBookings => 'Mis reservas';

  @override
  String get bookingTabUpcoming => 'Próximas';

  @override
  String get bookingTabHistory => 'Historial';

  @override
  String get bookingNoPastTitle => 'No hay reservas pasadas';

  @override
  String get bookingNoPastText =>
      'No se encontraron reservas pasadas asociadas a tu cuenta.';

  @override
  String get bookingNoUpcomingTitle => 'No hay próximas reservas';

  @override
  String get bookingNoUpcomingText =>
      'No se encontraron próximas reservas asociadas a tu cuenta.';

  @override
  String bookingCancelNotice(
    Object day,
    Object kind,
    Object price,
    Object time,
    Object venue,
  ) {
    return '$kind · $venue · $day, $time · $price. El horario vuelve a quedar libre.';
  }

  @override
  String get bookingCancelTitle => '¿Cancelar la reserva?';

  @override
  String get bookingCancelConfirm => 'CANCELAR RESERVA';

  @override
  String get bookingCancelKeep => 'NO CANCELAR';

  @override
  String get bookingModify => 'MODIFICAR';

  @override
  String get bookingCancel => 'CANCELAR';

  @override
  String bookingModifyLabel(Object what) {
    return 'Modificar la reserva de $what';
  }

  @override
  String bookingCancelLabel(Object what) {
    return 'Cancelar la reserva de $what';
  }

  @override
  String get bookingCanceling => 'Cancelando la reserva';

  @override
  String get bookingModified => 'Reserva modificada';

  @override
  String get bookingCanceledByYou =>
      'Cancelada por vos · el horario quedó liberado';

  @override
  String bookingCanceledByYouWithReason(Object reason) {
    return 'Cancelada por vos · el horario quedó liberado · $reason';
  }

  @override
  String get bookingVoidedByAdmin => 'Anulada por el administrador';

  @override
  String bookingVoidedByAdminWithReason(Object reason) {
    return 'Anulada por el administrador · $reason';
  }

  @override
  String get bookingToday => 'HOY';

  @override
  String get bookingTomorrow => 'MAÑANA';

  @override
  String bookingInDays(Object days) {
    return 'FALTAN $days DÍAS';
  }

  @override
  String bookingSpokenPrice(Object amount) {
    return '$amount pesos';
  }

  @override
  String get bookingCheer => '¡A LA CANCHA!';

  @override
  String get bookingConfirmedTitle => '¡Reserva confirmada!';

  @override
  String get bookingSeeMine => 'VER MIS RESERVAS';

  @override
  String get bookingBackHome => 'Volver al inicio';

  @override
  String get bookingReceiptNote =>
      'Te esperamos. Te vamos a avisar una hora antes.';

  @override
  String get bookingStepChoose => 'Elegí cancha';

  @override
  String get bookingStepConfirm => 'Confirmás';

  @override
  String get bookingStepDone => '¡Listo!';

  @override
  String bookingStepLabel(Object name, Object step, Object total) {
    return 'Paso $step de $total: $name';
  }

  @override
  String get bookingRowSpace => 'Espacio';

  @override
  String get bookingRowCourt => 'Cancha';

  @override
  String get bookingRowDate => 'Fecha';

  @override
  String get bookingRowTime => 'Horario';

  @override
  String bookingCourtValue(Object condition, Object number) {
    return 'Cancha $number · $condition';
  }

  @override
  String get bookingBefore => 'ANTES';

  @override
  String get bookingNow => 'AHORA';

  @override
  String get bookingConfirmTitle => 'Confirmá tu reserva';

  @override
  String get bookingConfirmButton => 'CONFIRMAR RESERVA';

  @override
  String bookingTaken(Object day, Object end, Object number, Object start) {
    return 'Mientras confirmabas, otra persona reservó Cancha $number · $day, $start – $end. Elegí otro horario disponible.';
  }

  @override
  String get bookingChangeTitle => 'Confirmá el cambio';

  @override
  String get bookingChangeSave => 'GUARDAR EL CAMBIO';

  @override
  String get bookingChangeKeep => 'DEJAR LA RESERVA COMO ESTÁ';

  @override
  String get bookingTotal => 'TOTAL';

  @override
  String bookingPerHour(Object price) {
    return '$price por hora';
  }

  @override
  String get bookingNoTimeChosen => 'Sin horario elegido';

  @override
  String bookingDuration(num hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String bookingModifyNote(Object day, Object duration, Object range) {
    return 'Estás modificando tu reserva del $day, $range. Mantenés la misma duración de $duration y el horario anterior se libera al guardar.';
  }

  @override
  String get bookingRetry => 'REINTENTAR';

  @override
  String get availabilityContinue => 'CONTINUAR';

  @override
  String get availabilityContinueChange => 'CONTINUAR CON EL CAMBIO';

  @override
  String get availabilitySelectSpace => 'SELECCIONÁ CANCHA';

  @override
  String get availabilityDate => 'FECHA';

  @override
  String get availabilityDuration => 'DURACIÓN';

  @override
  String get availabilitySlots => 'HORARIO DISPONIBLE';

  @override
  String availabilityDurationHint(Object closing, Object max, Object min) {
    return 'Horas completas, de $min a $max h. La sede cierra a las $closing.';
  }

  @override
  String get availabilityLessHour => 'Una hora menos';

  @override
  String get availabilityMoreHour => 'Una hora más';

  @override
  String get availabilityCurrent => '(actual)';

  @override
  String get availabilityNoSlots => 'No hay horarios disponibles';

  @override
  String availabilitySomeTaken(Object count) {
    return 'Algunos horarios ya están ocupados · $count no disponibles';
  }

  @override
  String availabilityFewerStarts(Object count, Object duration) {
    return 'Con $duration hay menos inicios posibles · $count no disponibles';
  }

  @override
  String get availabilityVenueClosed =>
      'La sede no abre ese día. Probá con otra fecha.';

  @override
  String availabilityNoFit(Object duration) {
    return 'Con $duration seguidas no entra ningún turno antes del cierre. Probá con una duración menor, otra fecha u otra cancha.';
  }

  @override
  String get availabilityNoneLeft =>
      'Ya no quedan turnos libres ese día. Probá con otra fecha u otra cancha.';

  @override
  String availabilityCourt(Object number) {
    return 'Cancha $number';
  }

  @override
  String availabilityCourtLabel(Object condition, Object number) {
    return 'Cancha $number, $condition';
  }

  @override
  String get spaceSearchTitle => 'Buscar cancha';

  @override
  String get spaceSearchHeading => 'Consultar canchas';

  @override
  String spaceSearchIntro(Object max, Object min) {
    return 'Elegí sede, deporte y rango horario. Solo horas completas, de $min a $max horas.';
  }

  @override
  String get spaceSearchVenue => 'Sede';

  @override
  String get spaceSearchSport => 'Deporte';

  @override
  String get spaceSearchKind => 'Tipo de cancha';

  @override
  String get spaceSearchDate => 'Fecha';

  @override
  String get spaceSearchFrom => 'Desde';

  @override
  String get spaceSearchTo => 'Hasta';

  @override
  String get spaceSearchPickVenue => 'Seleccioná una sede';

  @override
  String get spaceSearchPickSport => 'Seleccioná un deporte';

  @override
  String get spaceSearchAllKinds => 'Todos los tipos';

  @override
  String get spaceSearchDatePlaceholder => 'DD / MM / AAAA';

  @override
  String get spaceSearchDateFormat => 'Escribí la fecha como DD / MM / AAAA';

  @override
  String get spaceSearchPickDate => 'Elegir la fecha en el calendario';

  @override
  String get spaceSearchClear => 'LIMPIAR';

  @override
  String get spaceSearchRun => 'CONSULTAR';

  @override
  String spaceSearchSubtitle(
    Object date,
    Object from,
    Object to,
    Object venue,
    Object what,
  ) {
    return '$venue · $what · $date · $from a $to';
  }

  @override
  String spaceSearchNoAvailability(Object range, Object what) {
    return 'SIN DISPONIBILIDAD · $what · $range';
  }

  @override
  String spaceSearchResults(num count, Object range, Object what) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count CANCHAS DISPONIBLES',
      one: '1 CANCHA DISPONIBLE',
    );
    return '$_temp0 · $what · $range';
  }

  @override
  String get spaceSearchAll => 'Todas';

  @override
  String get spaceSearchEmptyTitle => 'No hay canchas disponibles';

  @override
  String get spaceSearchEmptyText =>
      'Ninguna cancha coincide con ese horario. Probá con otro rango o otra sede.';

  @override
  String get spaceSearchClearFilters => 'LIMPIAR FILTROS';

  @override
  String get spaceSearchErrorOverline => 'NO SE PUDO CONSULTAR';

  @override
  String get spaceSearchErrorTitle => 'No se pudo consultar la disponibilidad';

  @override
  String get spaceSearchOffline => 'Revisá tu conexión e intentá nuevamente.';

  @override
  String get spaceSearchServerDown =>
      'El servidor no respondió. Intentá más tarde.';

  @override
  String get spaceSearchFiltersKept => 'Los filtros que cargaste se mantienen.';

  @override
  String get spaceSearchBack => 'VOLVER';

  @override
  String get searchProblemPast => 'La fecha tiene que ser futura';

  @override
  String searchProblemFar(Object days) {
    return 'Elegí un día de los próximos $days';
  }

  @override
  String get searchProblemClosedDay => 'La sede no abre ese día';

  @override
  String get searchProblemMinHours => 'La duración mínima es de una hora';

  @override
  String searchProblemMaxHours(Object hours) {
    return 'La duración máxima es de $hours horas';
  }

  @override
  String searchProblemCloses(Object time) {
    return 'La sede cierra a las $time';
  }

  @override
  String searchProblemOpens(Object time) {
    return 'La sede abre a las $time';
  }

  @override
  String get searchProblemNotFuture => 'El horario tiene que ser futuro';

  @override
  String get spaceCovered => 'Techada';

  @override
  String get spaceOpenAir => 'Al aire libre';

  @override
  String get spaceLit => 'Iluminada';

  @override
  String get spaceUnlit => 'Sin iluminación';

  @override
  String get spaceWithLighting => 'con iluminación';

  @override
  String get spaceWithoutLighting => 'sin iluminación';

  @override
  String spacePerHour(Object price) {
    return '$price por hora';
  }

  @override
  String spaceDescription(Object condition, Object kind, Object price) {
    return '$kind · $condition · $price por hora';
  }

  @override
  String spaceSpoken(
    Object condition,
    Object kind,
    Object lighting,
    Object name,
    Object price,
  ) {
    return '$kind, $name, $condition, $lighting, $price pesos por hora';
  }

  @override
  String get spacePerHourBadge => '/ HORA';

  @override
  String get spaceBook => 'VER HORARIOS / RESERVAR';

  @override
  String spaceBookLabel(Object kind, Object number) {
    return '$kind, cancha $number';
  }

  @override
  String get spaceNoneTitle => 'Todavía no hay canchas';

  @override
  String get spaceNoneText =>
      'Esta sede no tiene canchas disponibles por el momento.';

  @override
  String get spaceNoMatchTitle => 'No hay canchas con este filtro';

  @override
  String get spaceNoMatchText => 'Probá con otro deporte o con otro tipo.';

  @override
  String get venuesTitle => 'Sedes';

  @override
  String venueCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sedes',
      one: '1 sede',
    );
    return '$_temp0';
  }

  @override
  String venueSpaceCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canchas',
      one: '1 cancha',
    );
    return '$_temp0';
  }

  @override
  String venuesSummary(Object spaces, Object venues) {
    return '$venues · $spaces · cada una con su horario';
  }

  @override
  String get venuesNoneTitle => 'Todavía no hay sedes';

  @override
  String get venuesNoneText => 'El club todavía no cargó sus sedes.';

  @override
  String get venuesFailedTitle => 'No pudimos mostrar las sedes';

  @override
  String get venuesFailedText => 'Revisá tu conexión y volvé a intentar.';

  @override
  String get venueSeeCourts => 'Ver canchas';

  @override
  String venueDaysHours(Object closing, Object days, Object opening) {
    return '$days · $opening a $closing';
  }

  @override
  String venueCardLabel(
    Object address,
    Object closing,
    Object days,
    Object name,
    Object opening,
    Object spaces,
  ) {
    return '$name, $address, $days de $opening a $closing, $spaces';
  }

  @override
  String venueAddressHours(Object address, Object closing, Object opening) {
    return '$address · $opening a $closing';
  }

  @override
  String get venueBack => 'Todas las sedes';

  @override
  String get venueAllSports => 'todos los deportes';

  @override
  String get venueAllKinds => 'todos los tipos';

  @override
  String get venueSportTitle => 'DEPORTE';

  @override
  String get venueSportPrefix => 'Deporte';

  @override
  String get venueKindTitle => 'TIPO DE CANCHA';

  @override
  String get venueKindPrefix => 'Tipo';

  @override
  String get venueKindAll => 'Todos';

  @override
  String get venueDaysMondayToSunday => 'Lunes a domingo';

  @override
  String get venueDaysMondayToSaturday => 'Lunes a sábado';

  @override
  String get venueDaysMondayToFriday => 'Lunes a viernes';

  @override
  String get loginForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get loginNoAccount => '¿No tenés cuenta?';

  @override
  String get loginStart => 'COMENZAR';

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
