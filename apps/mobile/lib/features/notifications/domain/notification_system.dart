import 'app_notification.dart';
import 'notification_kind.dart';

/// What the notice the person tapped in the system tray announced: what is needed to open
/// the corresponding screen.
class NoticeTapped {
  const NoticeTapped({this.kind, this.bookingId, this.legacy = false});

  /// Reads the data of the push message. A `booking_id` that is not a UUID (a numeric
  /// notice prior to UUIDs) marks the notice as [legacy]: that booking cannot be
  /// highlighted.
  factory NoticeTapped.fromData(Map<String, Object?> data) {
    final id = data['booking_id']?.toString() ?? '';
    final isUuid = _uuid.hasMatch(id);
    return NoticeTapped(
      kind: NotificationKind.fromApi(data['kind']?.toString() ?? ''),
      bookingId: isUuid ? id : null,
      legacy: id.isNotEmpty && !isUuid,
    );
  }

  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  final NotificationKind? kind;
  final String? bookingId;
  final bool legacy;

  /// Where tapping it opens: the notification center if it is an old notice.
  String get route => legacy ? '/notifications' : noticeRoute(kind, bookingId);
}

/// The notification system of the phone: the permission, the device token and what
/// arrives while the app is open or is opened by tapping a notice in the tray.
abstract interface class NotificationSystem {
  /// `ios` or `android`, as the API registers it.
  String get platform;

  Future<bool> isAllowed();

  /// Whether the operating system already asked the person about notifications.
  Future<bool> wasAsked();

  /// Asks the operating system for the permission and says whether it was granted.
  Future<bool> requestPermission();

  Future<String?> token();

  /// Deletes the device token: whatever the API still sends to that token stops arriving.
  /// The next [token] is another one.
  Future<void> forgetToken();

  /// A notice arrived with the app open.
  Stream<void> get onArrive;

  /// The person tapped a notice in the tray and the app opened (or came to the front).
  Stream<NoticeTapped> get onTap;

  /// The notice that opened the app from scratch, if one opened it.
  Future<NoticeTapped?> openedBy();
}
