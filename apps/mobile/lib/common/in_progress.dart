import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// What takes the place of a button while its action is on its way: a progress indicator
/// the height of a control that the screen reader announces as [label].
class InProgress extends StatelessWidget {
  const InProgress(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    excludeSemantics: true,
    child: const SizedBox(
      height: Spacing.controlHeight,
      child: Center(child: CircularProgressIndicator()),
    ),
  );
}
