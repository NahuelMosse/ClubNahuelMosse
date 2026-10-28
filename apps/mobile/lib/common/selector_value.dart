// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';

/// What is shown inside a [SelectorField]: the selected value or the placeholder, and the icon.
class SelectorValue extends StatelessWidget {
  const SelectorValue({
    super.key,
    required this.value,
    required this.placeholder,
    required this.icon,
    required this.readOnly,
  });

  final String? value;
  final String placeholder;
  final IconData icon;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final selected = value;
    return Row(
      children: [
        Expanded(
          child: Text(
            selected ?? placeholder,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Texts.body.copyWith(
              // Dimmed, but the value must still be readable.
              color: readOnly
                  ? p.textSecondary
                  : selected == null
                  ? p.textMuted
                  : p.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: Spacing.s12),
        Icon(
          icon,
          size: 24,
          color: readOnly ? p.stateDisabled : p.textSecondary,
        ),
      ],
    );
  }
}
