import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../venues/domain/venue.dart';

/// The icon, name, address and number of courts of a venue.
class VenueHeader extends StatelessWidget {
  const VenueHeader({super.key, required this.venue});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Container(
          width: Spacing.touchTarget,
          height: Spacing.touchTarget,
          decoration: BoxDecoration(
            color: p.accentMuted,
            borderRadius: BorderRadius.circular(Spacing.radiusMd),
          ),
          child: Icon(Icons.place_outlined, size: 20, color: p.accentInk),
        ),
        const SizedBox(width: Spacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                venue.name,
                style: Texts.title.copyWith(color: p.textPrimary),
              ),
              const SizedBox(height: Spacing.s4),
              Text(
                venue.address,
                style: Texts.caption.copyWith(color: p.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: Spacing.s12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${venue.spaceCount}',
              style: Texts.h2.copyWith(color: p.accentInk),
            ),
            Text(
              venue.spaceCount == 1 ? 'CANCHA' : 'CANCHAS',
              style: Texts.overline.copyWith(color: p.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}
