import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../domain/venue.dart';
import '../domain/venue_summary.dart';
import 'venue_card_cover.dart';
import 'venue_card_footer.dart';

/// `Card-Sede`: portada con nombre, dirección, horario y canchas; abajo, los deportes y
/// «Ver canchas». Se toca entera.
class VenueCard extends StatelessWidget {
  const VenueCard({
    super.key,
    required this.venue,
    required this.sports,
    required this.onTap,
  });

  final Venue venue;
  final List<String> sports;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final spaces = spaceCountLabel(venue.spaceCount);
    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label:
          '${venue.name}, ${venue.address}, '
          '${venue.daysLabel} de ${venue.opening} a ${venue.closing}, '
          '$spaces${sports.isEmpty ? '' : ': ${sports.join(', ')}'}',
      onTap: onTap,
      child: Material(
        color: p.bgSurface,
        borderRadius: BorderRadius.circular(Spacing.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VenueCardCover(venue: venue),
              VenueCardFooter(sports: sports),
            ],
          ),
        ),
      ),
    );
  }
}
