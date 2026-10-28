import 'app_notification.dart';

/// Lo que devuelve el centro: las últimas notificaciones y cuántas hay sin leer en total.
class CenterReading {
  const CenterReading(this.notifications, this.unread);
  final List<AppNotification> notifications;
  final int unread;
}
