// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../../venues/domain/venue.dart';
import 'admin_filter_chip.dart';

/// The venues that can be filtered by; [onSelect] receives the one tapped.
class VenueFilter extends StatelessWidget {
  const VenueFilter({
    super.key,
    required this.venues,
    required this.selected,
    required this.onSelect,
  });

  final List<Venue> venues;
  final String? selected;
  final ValueChanged<Venue> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.s8,
      runSpacing: Spacing.s8,
      children: [
        for (final venue in venues)
          AdminFilterChip(
            text: venue.name,
            onTap: () => onSelect(venue),
            selected: selected == venue.id,
          ),
      ],
    );
  }
}
