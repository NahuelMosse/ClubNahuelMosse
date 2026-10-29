// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import '../../../common/dates.dart';
import '../../venues/domain/venue.dart';
import 'venue_rules.dart';

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

  /// What shrank in the venue [before] when changing it to [opensAt], [closesAt] and
  /// [openDays], for [count] bookings left outside.
  factory OutsideHours.of(
    int count, {
    required Venue? before,
    required int opensAt,
    required int closesAt,
    required List<int> openDays,
  }) {
    final closesHour = closesAt == 0 ? 24 : closesAt;
    final beforeOpensAt = before == null
        ? null
        : parseWholeHour(before.opening);
    final beforeClosesAt = switch (before == null
        ? null
        : parseWholeHour(before.closing)) {
      0 => 24,
      final c => c,
    };
    return OutsideHours(
      count: count,
      venueName: before?.name,
      reasons: [
        if (beforeOpensAt != null && opensAt > beforeOpensAt)
          OutsideReason.startsBefore,
        if (beforeClosesAt != null && closesHour < beforeClosesAt)
          OutsideReason.endsAfter,
        if (before != null && before.days.any((d) => !openDays.contains(d)))
          OutsideReason.closedDay,
      ],
      opensHour: wholeHour(opensAt),
      closesHour: wholeHour(closesAt),
    );
  }

  final int count;
  final String? venueName;
  final List<OutsideReason> reasons;

  /// The new opening and closing as `HH:MM`.
  final String opensHour;
  final String closesHour;
}
