import 'app_notification.dart';

/// What the center returns: the latest notifications and how many are unread in total.
class CenterReading {
  const CenterReading(this.notifications, this.unread);
  final List<AppNotification> notifications;
  final int unread;
}
