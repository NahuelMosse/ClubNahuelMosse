import 'booking_history_entry.dart';
import 'counters.dart';

/// A page of the global history, with the total and the tab counters.
class HistoryPage {
  const HistoryPage({
    required this.bookings,
    required this.total,
    required this.page,
    required this.perPage,
    required this.counters,
  });

  final List<BookingHistoryEntry> bookings;
  final int total;
  final int page;
  final int perPage;
  final Counters counters;

  bool get hasMorePages => page * perPage < total;
}
