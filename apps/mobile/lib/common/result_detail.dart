// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';

/// The text of a [ResultScreen] and, if there is one, the saved value in its lime box.
class ResultDetail extends StatelessWidget {
  const ResultDetail({super.key, required this.text, this.detail});

  final String text;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: Texts.body.copyWith(color: p.textSecondary),
        ),
        if (detail case final value?) ...[
          const SizedBox(height: Spacing.s16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.s16,
              vertical: Spacing.s8,
            ),
            decoration: BoxDecoration(
              color: p.bgBase,
              borderRadius: BorderRadius.circular(Spacing.radiusMd),
              border: Border.all(color: p.accentInk),
            ),
            child: Text(
              value,
              textAlign: TextAlign.center,
              // The thin mono in the dark lime of light mode does not reach 4.5:1.
              style: Texts.mono.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? p.accentInk
                    : p.textPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
