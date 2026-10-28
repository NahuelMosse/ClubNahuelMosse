import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// A «label — value» row of the booking data table.
class VoidDetail extends StatelessWidget {
  const VoidDetail(this.label, this.value, {super.key, this.technical = false});

  final String label;
  final String value;

  /// The value is the technical name of the space.
  final bool technical;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '$label, $value',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.s4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Texts.caption.copyWith(color: p.textSecondary)),
            const SizedBox(width: Spacing.s12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: technical
                    ? Texts.mono.copyWith(color: p.textPrimary)
                    : Texts.bodyStrong.copyWith(color: p.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
