/// Qué avisa una notificación: el recordatorio de una reserva próxima (una hora o cinco minutos antes), la cancelación que
/// hizo el club o la confirmación de la que hizo la propia persona.
enum NotificationKind {
  reminder('recordatorio'),
  fiveMinuteReminder('recordatorio_cinco'),
  forcedCancellation('cancelacion_forzosa'),
  userCancellation('cancelacion_usuario');

  const NotificationKind(this.apiValue);

  /// Cómo lo escribe la API.
  final String apiValue;

  static NotificationKind? fromApi(String value) =>
      values.where((k) => k.apiValue == value).firstOrNull;
}
