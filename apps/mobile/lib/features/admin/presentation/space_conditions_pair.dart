import 'package:flutter/material.dart';

import '../../../common/selector.dart';
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
    return FieldPair(
      left: SelectorField(
        label: 'CONDICIÓN',
        semanticLabel: 'Condición',
        value: roofed ? 'Techada' : 'Al aire libre',
        placeholder: '',
        icon: Icons.expand_more_rounded,
        onTap: onPickRoofing,
      ),
      right: SelectorField(
        label: 'ILUMINACIÓN',
        semanticLabel: 'Iluminación',
        value: lit ? 'Iluminada' : 'Sin iluminación',
        placeholder: '',
        icon: Icons.expand_more_rounded,
        onTap: onPickLighting,
      ),
    );
  }
}
