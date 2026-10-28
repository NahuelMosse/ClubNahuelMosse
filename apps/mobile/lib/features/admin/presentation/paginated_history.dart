import 'package:flutter/material.dart';

import '../data/api_failures.dart';
import '../data/booking_history_api.dart';
import '../domain/booking_history_entry.dart';
import '../domain/history_filters.dart';
import '../domain/history_page.dart';

/// The pages of the booking history loaded so far. A counter goes up with each request:
/// the response of a filter no longer being looked at is discarded. Notifies every change.
class PaginatedHistory extends ChangeNotifier {
  PaginatedHistory(this.history);

  final BookingHistory history;
  HistoryPage? result;
  final bookings = <BookingHistoryEntry>[];
  bool failed = false;
  bool loadingMore = false;
  int _request = 0;
  bool _closed = false;

  bool _isStale(int request) => _closed || request != _request;

  /// Whether scrolling must request the next page.
  bool get needsMore =>
      (result?.hasMorePages ?? false) && !loadingMore && !failed;

  @override
  void notifyListeners() {
    if (!_closed) super.notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }

  /// Requests the first page of [filters]; returns why it failed, or `null` if it went well
  /// or the response is no longer looked at.
  Future<({bool expired, Object? error})?> load(HistoryFilters filters) async {
    final request = ++_request;
    result = null;
    bookings.clear();
    failed = false;
    loadingMore = false;
    notifyListeners();
    Object? error;
    var expired = false;
    try {
      final page = await history.page(filters);
      if (_isStale(request)) return null;
      result = page;
      bookings.addAll(page.bookings);
      notifyListeners();
      return null;
    } on SessionExpired {
      expired = true;
    } on FalloDeRed catch (e) {
      error = e;
    }
    if (_isStale(request)) return null;
    failed = true;
    notifyListeners();
    return (expired: expired, error: error);
  }

  /// Requests the next page; without network or with the server down, what was already
  /// loaded stays visible and scrolling tries again later.
  Future<void> loadMore(HistoryFilters filters) async {
    final current = result;
    if (current == null) return;
    final request = _request;
    loadingMore = true;
    notifyListeners();
    HistoryPage? next;
    try {
      next = await history.page(filters, page: current.page + 1);
    } on Exception {
      next = null;
    }
    if (_isStale(request)) return;
    if (next != null) {
      result = next;
      // With OFFSET pagination, a new or voided booking between two pages shifts the
      // rows: the ones already present are discarded.
      final seen = {for (final b in bookings) b.id};
      bookings.addAll(next.bookings.where((b) => seen.add(b.id)));
    }
    loadingMore = false;
    notifyListeners();
  }
}
