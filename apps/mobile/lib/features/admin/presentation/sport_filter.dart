import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../../spaces/domain/space.dart';
import 'admin_filter_chip.dart';

/// The catalog sports that can be filtered by; [onSelect] receives the one tapped.
class SportFilter extends StatelessWidget {
  const SportFilter({
    super.key,
    required this.sports,
    required this.selected,
    required this.onSelect,
  });

  final List<Sport> sports;
  final String? selected;
  final ValueChanged<Sport> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.s8,
      runSpacing: Spacing.s8,
      children: [
        for (final sport in sports)
          AdminFilterChip(
            text: sport.name,
            onTap: () => onSelect(sport),
            selected: selected == sport.key,
          ),
      ],
    );
  }
}
