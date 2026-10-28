/// Qué avisa una notificación: el recordatorio de una reserva próxima (una hora o cinco minutos antes), la cancelación que
/// hizo el club o la confirmación de la que hizo la propia persona.
enum NotificationKind {
  reminder('recordatorio', 'recordatorio'),
  fiveMinuteReminder('recordatorio', 'recordatorio_cinco'),
  forcedCancellation('cancelación del club', 'cancelacion_forzosa'),
  userCancellation('cancelación propia', 'cancelacion_usuario');

  const NotificationKind(this.label, this.apiValue);

  /// Cómo se nombra en castellano.
  final String label;

  /// Cómo lo escribe la API.
  final String apiValue;

  static NotificationKind? fromApi(String value) =>
      values.where((k) => k.apiValue == value).firstOrNull;
}
