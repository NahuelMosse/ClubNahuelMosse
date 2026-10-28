import 'package:flutter/material.dart';

import '../../../common/selectable_chip.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// An option of the filter panel: toggled on and off by tapping it.
class AdminFilterChip extends StatelessWidget {
  const AdminFilterChip({
    super.key,
    required this.text,
    required this.onTap,
    required this.selected,
  });

  final String text;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SelectableChip(
      text: text,
      selected: selected,
      onTap: onTap,
      style: Texts.body,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s16,
        vertical: Spacing.s8,
      ),
      unselectedBackground: p.bgSurface,
    );
  }
}
