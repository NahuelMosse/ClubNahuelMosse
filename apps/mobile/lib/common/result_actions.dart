// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'button.dart';

/// The primary button of a [ResultScreen] and, if there is one, the secondary text, which
/// is swapped for a loading indicator while [secondaryLoading].
class ResultActions extends StatelessWidget {
  const ResultActions({
    super.key,
    required this.primary,
    required this.onPrimaryTap,
    this.secondary,
    this.onSecondaryTap,
    this.secondaryLoading = false,
  });

  final String primary;
  final VoidCallback onPrimaryTap;
  final String? secondary;
  final VoidCallback? onSecondaryTap;
  final bool secondaryLoading;

  @override
  Widget build(BuildContext context) {
    final secondaryText = secondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton(label: primary, onTap: onPrimaryTap),
        if (secondaryText != null) ...[
          const SizedBox(height: Spacing.s8),
          Center(
            child: secondaryLoading
                ? const SizedBox(
                    height: Spacing.controlHeight,
                    child: Center(
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  )
                : TextActionButton(label: secondaryText, onTap: onSecondaryTap),
          ),
        ],
      ],
    );
  }
}
