/// Why a future booking no longer fits the venue's new schedule.
enum OutsideReason { startsBefore, endsAfter, closedDay }

/// What the owner is told when saving a schedule leaves future bookings outside it.
class OutsideHours {
  const OutsideHours({
    required this.count,
    required this.venueName,
    required this.reasons,
    required this.opensHour,
    required this.closesHour,
  });

  final int count;
  final String? venueName;
  final List<OutsideReason> reasons;

  /// The new opening and closing as `HH:MM`.
  final String opensHour;
  final String closesHour;
}
