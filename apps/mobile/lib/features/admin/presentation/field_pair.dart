import 'package:flutter/material.dart';
import '../../../theme/tokens.dart';

/// Two fields side by side, like the prototype; on a small phone their values do not fit
/// («Al aire libre», «Sin iluminación») and they go one below the other.
class FieldPair extends StatelessWidget {
  const FieldPair({super.key, required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth < 340
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              left,
              const SizedBox(height: Spacing.s12),
              right,
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: Spacing.s12),
              Expanded(child: right),
            ],
          ),
  );
}
