/// Qué avisa una notificación: el recordatorio de una reserva próxima (una hora o cinco minutos antes), la cancelación que
/// hizo el club o la confirmación de la que hizo la propia persona.
enum NotificationKind {
  reminder('recordatorio', 'reminder'),
  fiveMinuteReminder('recordatorio', 'five_minute_reminder'),
  forcedCancellation('cancelación del club', 'forced_cancellation'),
  userCancellation('cancelación propia', 'user_cancellation');

  const NotificationKind(this.label, this.apiValue);

  /// Cómo se nombra en castellano.
  final String label;

  /// Cómo lo escribe la API.
  final String apiValue;

  static NotificationKind? fromApi(String value) =>
      values.where((k) => k.apiValue == value).firstOrNull;
}
