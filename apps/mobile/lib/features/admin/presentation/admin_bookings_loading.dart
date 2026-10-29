import 'package:flutter/material.dart';

import '../../../common/skeleton.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import 'admin_booking_card_skeleton.dart';

/// The history while it loads: the «Cargando reservas…» text and the rows of the bookings.
class AdminBookingsLoading extends StatelessWidget {
  const AdminBookingsLoading({super.key});

  static const _rows = 3;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.s24,
        Spacing.s16,
        Spacing.s24,
        Spacing.s40,
      ),
      sliver: SliverList.list(
        children: [
          Center(
            child: Semantics(
              liveRegion: true,
              child: Text(
                AppLocalizations.of(context).adminLoadingBookings,
                style: Texts.overline.copyWith(color: p.textMuted),
              ),
            ),
          ),
          const SizedBox(height: Spacing.s16),
          SkeletonZone(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _rows; i++) ...[
                  const AdminBookingCardSkeleton(),
                  if (i < _rows - 1) const SizedBox(height: Spacing.s12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
