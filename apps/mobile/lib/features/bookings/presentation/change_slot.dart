import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// The previous time, with a cross, or the current one, with a tick and in lime.
class ChangeSlot extends StatelessWidget {
  const ChangeSlot({
    super.key,
    required this.title,
    required this.value,
    required this.isNew,
  });

  final String title;
  final String value;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      container: true,
      label: '$title: $value',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.s8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isNew ? Icons.check_rounded : Icons.close_rounded,
              size: 18,
              color: isNew ? p.stateSuccessInk : p.stateDangerInk,
            ),
            const SizedBox(width: Spacing.s8),
            Text(title, style: Texts.overline.copyWith(color: p.textMuted)),
            const SizedBox(width: Spacing.s16),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: isNew
                    ? Texts.bodyStrong.copyWith(color: p.accentInk)
                    : Texts.body.copyWith(color: p.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
