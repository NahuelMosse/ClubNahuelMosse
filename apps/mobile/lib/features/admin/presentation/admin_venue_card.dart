// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../venues/domain/venue.dart';
import '../../venues/presentation/venue_texts.dart';
import 'admin_card.dart';
import 'venue_header.dart';

/// `Card-Sede-Admin`: name, address, number of courts and days with schedule, with
/// «Editar sede» and «Dar de baja».
class AdminVenueCard extends StatelessWidget {
  const AdminVenueCard({
    super.key,
    required this.venue,
    this.onDeactivate,
    this.deactivating = false,
    this.enabled = true,
  });

  final Venue venue;
  final VoidCallback? onDeactivate;

  /// The deactivation of this venue is on its way.
  final bool deactivating;

  /// `false` disables its buttons (another deactivation is on its way).
  final bool enabled;

  void _edit(BuildContext context) =>
      context.go('/admin/sedes/${venue.id}/editar', extra: venue);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final courts = l10n.adminCourtsCount(venue.spaceCount);
    // The data is read as one; the buttons stay outside, each with its own name.
    final details = Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '${venue.name}, ${venue.address}, $courts, '
          '${l10n.adminVenueSchedule(weekdaysText(l10n, venue.daysLabel), venue.opening, venue.closing)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VenueHeader(venue: venue),
          const SizedBox(height: Spacing.s12),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 16, color: p.textMuted),
              const SizedBox(width: Spacing.s8),
              Expanded(
                child: Text(
                  l10n.adminVenueScheduleShort(
                    weekdaysText(l10n, venue.daysLabel),
                    venue.opening,
                    venue.closing,
                  ),
                  style: Texts.caption.copyWith(color: p.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return AdminCard(
      details: details,
      name: venue.name,
      editText: l10n.adminEditVenue,
      editLabel: l10n.adminEditVenueNamed(venue.name),
      onEdit: enabled ? () => _edit(context) : null,
      deactivateText: l10n.adminDeactivateVenue,
      deactivateLabel: l10n.adminDeactivateVenueNamed(venue.name),
      onDeactivate: enabled ? onDeactivate : null,
      deactivating: deactivating,
    );
  }
}
