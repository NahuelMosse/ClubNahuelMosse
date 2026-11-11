/// What a notification announces: the reminder of an upcoming booking (an hour or five
/// minutes before), the cancellation made by the club or the confirmation of the one made
/// by the person themself.
enum NotificationKind {
  reminder('reminder'),
  fiveMinuteReminder('five_minute_reminder'),
  forcedCancellation('forced_cancellation'),
  userCancellation('user_cancellation');

  const NotificationKind(this.apiValue);

  /// How the API writes it.
  final String apiValue;

  static NotificationKind? fromApi(String value) =>
      values.where((k) => k.apiValue == value).firstOrNull;
}
