import 'package:flutter/material.dart';

import '../../../common/selectable_chip.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// Una fila de chips para elegir una opción: la elegida en lima. [prefijo] va en la
/// etiqueta accesible de cada chip («Deporte Fútbol»), porque el mismo nombre aparece en
/// la portada y en las tarjetas.
class SpaceFilter extends StatelessWidget {
  const SpaceFilter({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.enabled,
    required this.prefix,
    required this.onSelected,
  });

  final String title;
  final List<(String?, String, IconData?)> options;
  final String? selected;
  final bool enabled;
  final String prefix;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            title,
            style: Texts.overline.copyWith(color: p.textMuted),
          ),
        ),
        const SizedBox(height: Spacing.s8),
        Wrap(
          spacing: Spacing.s8,
          runSpacing: Spacing.s8,
          children: [
            for (final (key, text, icon) in options)
              SelectableChip(
                text: text,
                icon: icon,
                label: '$prefix $text',
                selected: key == selected,
                onTap: enabled ? () => onSelected(key) : null,
                minHeight: Spacing.touchTarget + 4,
                bordered: true,
              ),
          ],
        ),
      ],
    );
  }
}
