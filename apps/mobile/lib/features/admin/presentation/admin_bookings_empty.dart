import 'package:flutter/material.dart';

import '../../../common/empty_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';

/// The sliver of the history without bookings: no results for the filters, or no bookings.
class AdminBookingsEmpty extends StatelessWidget {
  const AdminBookingsEmpty({
    super.key,
    required this.hasFilters,
    required this.onClearFilters,
  });

  final bool hasFilters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s24),
      sliver: SliverToBoxAdapter(
        child: hasFilters
            ? EmptyState(
                title: l10n.adminNoResults,
                text: l10n.adminNoResultsText,
                action: l10n.adminClearFilters,
                onTap: onClearFilters,
              )
            : EmptyState(
                title: l10n.adminNoBookings,
                text: l10n.adminNoBookingsText,
              ),
      ),
    );
  }
}
