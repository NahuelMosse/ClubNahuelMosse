// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../venues/domain/venue.dart';
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
    final courts = venue.spaceCount == 1
        ? '1 cancha'
        : '${venue.spaceCount} canchas';
    // The data is read as one; the buttons stay outside, each with its own name.
    final details = Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '${venue.name}, ${venue.address}, $courts, '
          '${venue.daysLabel} de ${venue.opening} a ${venue.closing}',
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
                  '${venue.daysLabel} · ${venue.opening} a ${venue.closing}',
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
      editText: 'Editar sede',
      editLabel: 'Editar sede ${venue.name}',
      onEdit: enabled ? () => _edit(context) : null,
      deactivateText: 'Dar de baja',
      deactivateLabel: 'Dar de baja ${venue.name}',
      onDeactivate: enabled ? onDeactivate : null,
      deactivating: deactivating,
    );
  }
}
