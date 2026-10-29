// kit-shape: a screen or error family kept with its private parts.
import '../../../common/club_timezone.dart';
import '../../../common/dates.dart';
import 'notification_kind.dart';

/// A dónde lleva tocar un aviso: Mis reservas con la reserva resaltada. Las cancelaciones —del
/// club o de la propia persona— dejaron la reserva en el historial, así que abren esa pestaña.
String noticeRoute(NotificationKind? kind, String? bookingId) {
  final history =
      kind == NotificationKind.forcedCancellation ||
      kind == NotificationKind.userCancellation;
  final parameters = [
    if (history) 'historial=1',
    if (bookingId != null) 'reserva=$bookingId',
  ];
  return parameters.isEmpty ? '/reservas' : '/reservas?${parameters.join('&')}';
}

/// Una entrada del centro de notificaciones.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.bookingId,
    required this.createdAt,
    required this.read,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final String? bookingId;

  /// En la hora del club.
  final DateTime createdAt;
  final bool read;

  AppNotification markedRead() => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    bookingId: bookingId,
    createdAt: createdAt,
    read: true,
  );

  static AppNotification? fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'kind': final String kind,
      'title': final String title,
      'body': final String body,
      'created_at': final String createdAt,
      'read': final bool read,
    }) {
      final parsedKind = NotificationKind.fromApi(kind);
      final when = DateTime.tryParse(createdAt);
      if (parsedKind == null || when == null) return null;
      return AppNotification(
        id: id,
        kind: parsedKind,
        title: title,
        body: body,
        bookingId: json['booking_id'] is String
            ? json['booking_id'] as String
            : null,
        createdAt: inClubTime(when),
        read: read,
      );
    }
    return null;
  }
}

/// Los días se cuentan en el club, sea cual sea la zona del teléfono.
DateTime inClubTime(DateTime moment) => toClubTime(moment);

/// Las notificaciones de un mismo día, con su rótulo: HOY, AYER o `dd/mm`.
class DayGroup {
  const DayGroup(this.label, this.notifications);
  final String label;
  final List<AppNotification> notifications;
}

DateTime _day(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// HOY, AYER o `dd/mm`, según [now] en la hora del club.
String dayLabel(DateTime createdAt, DateTime now) {
  final days = _day(now).difference(_day(createdAt)).inDays;
  return switch (days) {
    0 => 'HOY',
    1 => 'AYER',
    _ => dayAndMonth(createdAt),
  };
}

/// Cuándo llegó: AHORA, HACE 2 MIN, HACE 3 H, AYER o `dd/mm`.
String arrivedLabel(DateTime createdAt, DateTime now) {
  final elapsed = now.difference(createdAt);
  final label = dayLabel(createdAt, now);
  if (label != 'HOY') return label;
  if (elapsed.inMinutes < 1) return 'AHORA';
  if (elapsed.inMinutes < 60) return 'HACE ${elapsed.inMinutes} MIN';
  return 'HACE ${elapsed.inHours} H';
}

/// Agrupa por día conservando el orden de [list], de la más nueva a la más vieja.
List<DayGroup> groupByDay(List<AppNotification> list, DateTime now) {
  final groups = <DayGroup>[];
  for (final n in list) {
    final label = dayLabel(n.createdAt, now);
    if (groups.isNotEmpty && groups.last.label == label) {
      groups.last.notifications.add(n);
    } else {
      groups.add(DayGroup(label, [n]));
    }
  }
  return groups;
}
