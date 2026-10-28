// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/skeleton.dart';
import '../../../theme/tokens.dart';
import '../../spaces/domain/space.dart';
import '../domain/booking_history_entry.dart';
import '../domain/history_page.dart';
import 'admin_bookings_empty.dart';
import 'admin_bookings_list.dart';
import 'admin_bookings_loading.dart';

/// What goes below the panel header: loading, the retry, the list or that there are no
/// bookings, and the indicator of the page being requested.
List<Widget> adminPanelBody({
  required HistoryPage? result,
  required bool failed,
  required bool loadingMore,
  required bool hasFilters,
  required List<BookingHistoryEntry> bookings,
  required Catalog? catalog,
  required VoidCallback onRetry,
  required VoidCallback onClearFilters,
  required void Function(BookingHistoryEntry) onTap,
  required void Function(BookingHistoryEntry)? onVoid,
}) {
  return [
    if (result == null && !failed) const AdminBookingsLoading(),
    if (result == null && failed)
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.s24),
          child: Center(
            child: TextActionButton(label: 'REINTENTAR', onTap: onRetry),
          ),
        ),
      ),
    if (result != null && result.total == 0)
      AdminBookingsEmpty(
        hasFilters: hasFilters,
        onClearFilters: onClearFilters,
      ),
    if (result != null && result.total > 0)
      AdminBookingsList(
        bookings: bookings,
        catalog: catalog,
        onTap: onTap,
        onVoid: onVoid,
      ),
    if (loadingMore)
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: Spacing.s16),
          child: SkeletonList(shape: SkeletonShape.booking, count: 1),
        ),
      ),
  ];
}
