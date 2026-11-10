import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// A datum of the booking: the name on the left and the value on the right.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
    this.code = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  /// A long code without spaces (the composed name of the space): goes below the datum,
  /// in the mono font, so it is not split in the middle of a word.
  final bool code;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (code) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Texts.body.copyWith(color: p.textSecondary)),
            const SizedBox(height: Spacing.s4),
            Text(value, style: Texts.mono.copyWith(color: p.textPrimary)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Texts.body.copyWith(color: p.textSecondary)),
          const SizedBox(width: Spacing.s16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: (emphasized ? Texts.bodyStrong : Texts.body).copyWith(
                color: emphasized ? p.accentInk : p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
