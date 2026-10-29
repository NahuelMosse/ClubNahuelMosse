import 'package:flutter/material.dart';

import '../../../common/selector.dart';
import '../../../l10n/app_localizations.dart';
import 'field_pair.dart';

/// Roofing (covered or open air) and lighting of a space, side by side. A `null` callback
/// disables its selector.
class SpaceConditionsPair extends StatelessWidget {
  const SpaceConditionsPair({
    super.key,
    required this.roofed,
    required this.lit,
    required this.onPickRoofing,
    required this.onPickLighting,
  });

  final bool roofed;
  final bool lit;
  final VoidCallback? onPickRoofing;
  final VoidCallback? onPickLighting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FieldPair(
      left: SelectorField(
        label: l10n.adminConditionUpper,
        semanticLabel: l10n.adminCondition,
        value: roofed ? l10n.adminCovered : l10n.adminOpenAir,
        placeholder: '',
        icon: Icons.expand_more_rounded,
        onTap: onPickRoofing,
      ),
      right: SelectorField(
        label: l10n.adminLightingUpper,
        semanticLabel: l10n.adminLighting,
        value: lit ? l10n.adminLit : l10n.adminUnlit,
        placeholder: '',
        icon: Icons.expand_more_rounded,
        onTap: onPickLighting,
      ),
    );
  }
}
