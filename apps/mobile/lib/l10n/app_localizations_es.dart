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
  String get loginSignIn => 'INICIAR SESIÓN';

  @override
  String get loginEmailRequired => 'Completá tu correo electrónico';

  @override
  String commonDuration(num hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String get commonRetry => 'REINTENTAR';

  @override
  String get commonBack => 'Volver';

  @override
  String get commonOk => 'ACEPTAR';

  @override
  String get commonCloseNotice => 'Cerrar aviso';

  @override
  String get commonShowPassword => 'Mostrar contraseña';

  @override
  String get commonHidePassword => 'Ocultar contraseña';

  @override
  String get commonLoading => 'Cargando';

  @override
  String get commonMemberCard => 'FICHA DE SOCIO';

  @override
  String get commonSelected => 'ELEGIDO';

  @override
  String get commonSavePassword => 'GUARDAR CONTRASEÑA';

  @override
  String get commonPasswordUpdatedTitle => 'Contraseña actualizada';

  @override
  String get commonPasswordUpdatedText =>
      'Tu contraseña se cambió correctamente. Usala la próxima vez que inicies sesión.';

  @override
  String get commonYourDay => 'TU DÍA EN LA CANCHA';

  @override
  String get commonSlotFree => 'Libre';

  @override
  String get commonSlotTaken => 'Ocupado';

  @override
  String get commonSlotChosen => 'Elegido';

  @override
  String commonSlotFreeSemantics(Object hour) {
    return '$hour h libre';
  }

  @override
  String commonSlotTakenSemantics(Object hour) {
    return '$hour h ocupada';
  }

  @override
  String commonSlotChosenSemantics(Object hour) {
    return '$hour h elegida';
  }

  @override
  String get navHome => 'INICIO';

  @override
  String get navVenues => 'SEDES';

  @override
  String get navBookings => 'RESERVAS';

  @override
  String get navProfile => 'PERFIL';

  @override
  String get navSpaces => 'ESPACIOS';

  @override
  String get errorConnectionTitle => 'Error de conexión';

  @override
  String get errorConnectionText =>
      'No pudimos conectarnos. Revisá tu conexión a internet y volvé a intentar.';

  @override
  String get errorServerTitle => 'Error del servidor';

  @override
  String get errorNoResponseText =>
      'El servidor no responde. Probá de nuevo en unos minutos.';

  @override
  String get errorGenericText =>
      'No pudimos procesar la operación en este momento. Intentá más tarde.';

  @override
  String get errorTimeSlotTakenTitle => 'Ese horario se ocupó';

  @override
  String get errorTimeSlotRejectedTitle => 'No se pudo confirmar el horario';

  @override
  String get errorChooseAnotherTime => 'ELEGIR OTRO HORARIO';

  @override
  String get errorSaveNewScheduleTitle => '¿Guardar el horario nuevo?';

  @override
  String get errorSaveAnyway => 'GUARDAR IGUAL';

  @override
  String get errorReviewSchedule => 'REVISAR EL HORARIO';

  @override
  String get errorBookingCanceledTitle => 'Reserva cancelada con éxito';

  @override
  String get errorBookingCanceledText =>
      'El horario quedó liberado y la reserva pasó a tu historial.';

  @override
  String get errorBookingVoidedTitle => 'Reserva anulada correctamente';

  @override
  String get errorBookingVoidedText =>
      'El horario quedó liberado y la reserva pasó a las anuladas.';

  @override
  String get errorChangedTitle => 'Esto cambió mientras tanto';

  @override
  String get errorChangedText =>
      'Otra persona modificó estos datos mientras los estabas viendo. Los actualizamos para que veas el estado real.';

  @override
  String get errorChangedAction => 'VER LO ACTUALIZADO';

  @override
  String get errorSessionExpiredTitle => 'Tu sesión expiró';

  @override
  String get errorSessionExpiredText =>
      'Por seguridad cerramos tu sesión. Volvé a iniciar sesión para continuar.';

  @override
  String get errorSessionExpiredAction => 'IR AL INICIO DE SESIÓN';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String notificationsBellUnread(Object unread) {
    return 'Notificaciones, $unread sin leer';
  }

  @override
  String get notificationUnread => 'sin leer';

  @override
  String notificationFrom(Object when) {
    return 'CLUBNAHUELMOSSE · $when';
  }

  @override
  String get notificationsCloseLabel => 'Cerrar las notificaciones';

  @override
  String get notificationsPanelTitle => 'NOTIFICACIONES';

  @override
  String get notificationsMarkAll => 'MARCAR TODAS';

  @override
  String get notificationsDisabledTitle => 'Notificaciones desactivadas';

  @override
  String get notificationsDisabledText =>
      'Activá los avisos para que te recordemos tus reservas una hora antes.';

  @override
  String get notificationsEnable => 'ACTIVAR NOTIFICACIONES';

  @override
  String get notificationsEmptyTitle => 'Todavía no tenés notificaciones';

  @override
  String get notificationsEmptyText =>
      'Acá vas a ver los recordatorios de tus reservas.';

  @override
  String get arrivalToday => 'HOY';

  @override
  String get arrivalYesterday => 'AYER';

  @override
  String get arrivalNow => 'AHORA';

  @override
  String arrivalMinutesAgo(Object minutes) {
    return 'HACE $minutes MIN';
  }

  @override
  String arrivalHoursAgo(Object hours) {
    return 'HACE $hours H';
  }

  @override
  String get loginPasswordRequired => 'Completá tu contraseña';

  @override
  String get loginInvalidCredentials =>
      'No se pudo iniciar sesión. Revisá tus datos e intentá de nuevo.';
}
