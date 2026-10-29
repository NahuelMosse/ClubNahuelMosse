// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/dates.dart';
import '../../../common/price_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../spaces/domain/space.dart';
import '../domain/booking_history_entry.dart';
import 'admin_booking_body.dart';
import 'booking_status_text.dart';

class AdminBookingCard extends StatelessWidget {
  const AdminBookingCard({
    super.key,
    required this.booking,
    required this.catalog,
    required this.onTap,
    required this.onVoid,
  });

  final BookingHistoryEntry booking;
  final Catalog? catalog;
  final VoidCallback onTap;

  /// `null` disables ANULAR RESERVA (another voiding is on its way).
  final VoidCallback? onVoid;

  String get _schedule => timeRange(booking.startsAt, booking.endsAt);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final b = booking;
    final sportName = catalog?.sport(b.sport)?.name ?? b.sport;
    final semantics =
        '$sportName, ${b.venue}, ${b.user}, '
        '${longDate(b.startsAt)}, $_schedule, ${formatPesos(b.total)}, '
        '${statusChipText(l10n, b.status).toLowerCase()}'
        '${b.spaceDeactivated ? ', ${l10n.adminSpaceDeactivated.toLowerCase()}' : ''}';
    final voidBooking = onVoid;
    return Material(
      color: p.bgSurfaceRaised,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacing.radiusLg),
        side: BorderSide(color: p.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: semantics,
            excludeSemantics: true,
            child: InkWell(
              onTap: onTap,
              child: AdminBookingBody(
                booking: b,
                sportName: sportName,
                schedule: _schedule,
              ),
            ),
          ),
          if (b.voidable)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.s16,
                0,
                Spacing.s16,
                Spacing.s16,
              ),
              child: OutlineButton(
                label: l10n.adminVoidBooking,
                danger: true,
                semanticLabel: l10n.adminVoidBookingLabel(
                  b.user,
                  sportName,
                  longDate(b.startsAt),
                  _schedule,
                ),
                onTap: voidBooking,
              ),
            ),
        ],
      ),
    );
  }
}
