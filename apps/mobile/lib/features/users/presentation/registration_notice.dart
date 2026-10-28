import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

class RegistrationNotice extends StatelessWidget {
  const RegistrationNotice({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(Spacing.s16),
        decoration: BoxDecoration(
          color: p.stateDangerMuted,
          borderRadius: BorderRadius.circular(Spacing.radiusMd),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: p.stateDangerInk,
            ),
            const SizedBox(width: Spacing.s12),
            Expanded(
              child: Text(
                text,
                style: Texts.bodyStrong.copyWith(color: p.stateDangerInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
