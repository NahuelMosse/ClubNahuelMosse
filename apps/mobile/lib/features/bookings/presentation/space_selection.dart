// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../spaces/domain/space.dart';
import 'availability_space_card.dart';
import 'paired_grid.dart';
import 'slots_section.dart';

/// SELECCIONÁ CANCHA: las canchas del mismo tipo, con la elegida marcada.
class SpaceSelection extends StatelessWidget {
  const SpaceSelection({
    super.key,
    required this.spaceOptions,
    required this.chosen,
    required this.onSelect,
  });

  final List<Space> spaceOptions;
  final String chosen;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SlotsSection(
      title: AppLocalizations.of(context).availabilitySelectSpace,
      child: PairedGrid(
        children: [
          for (final c in spaceOptions)
            AvailabilitySpaceCard(
              space: c,
              chosen: c.id == chosen,
              onTap: () => onSelect(c.id),
            ),
        ],
      ),
    );
  }
}
