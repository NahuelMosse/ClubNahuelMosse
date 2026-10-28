import 'history_filters.dart';

/// The global history filters that were applied when the session expired (CU-14 FA5):
/// they are restored on returning to the panel, like `PendingBooking` with the booking.
class PendingPanelFilters {
  HistoryFilters? _filters;

  void save(HistoryFilters filters) => _filters = filters;

  /// The saved filters, which are then discarded: they are restored only once.
  HistoryFilters? take() {
    final filters = _filters;
    _filters = null;
    return filters;
  }
}
