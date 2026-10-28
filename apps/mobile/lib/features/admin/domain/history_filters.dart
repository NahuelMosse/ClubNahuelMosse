import '../../bookings/domain/booking_status.dart';

/// What an administrator picked to narrow the global history (CU-14). `null` in any
/// field means that filter is not applied.
class HistoryFilters {
  const HistoryFilters({
    this.status,
    this.venueId,
    this.sport,
    this.since,
    this.until,
    this.search,
  });

  /// The four prototype tabs: never [BookingStatus.canceled], which only shows up
  /// inside «Todas».
  final BookingStatus? status;
  final String? venueId;
  final String? sport;
  final DateTime? since;
  final DateTime? until;
  final String? search;

  bool get hasFilters =>
      status != null ||
      venueId != null ||
      sport != null ||
      since != null ||
      until != null ||
      searchText != null;

  /// The searched text without surrounding whitespace; `null` if there is none.
  String? get searchText {
    final trimmed = search?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// `true` if `since` is after `until` (FA3): the server is not queried.
  bool get hasInvalidRange {
    final start = since;
    final end = until;
    return start != null && end != null && start.isAfter(end);
  }

  HistoryFilters withStatus(BookingStatus? newStatus) => HistoryFilters(
    status: newStatus,
    venueId: venueId,
    sport: sport,
    since: since,
    until: until,
    search: search,
  );

  HistoryFilters withSearch(String? newSearch) => HistoryFilters(
    status: status,
    venueId: venueId,
    sport: sport,
    since: since,
    until: until,
    search: newSearch,
  );
}
