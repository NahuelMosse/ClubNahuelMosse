import 'package:flutter/material.dart';
import '../../../theme/tokens.dart';

/// Dos columnas iguales, como las grillas del prototipo.
class PairedGrid extends StatelessWidget {
  const PairedGrid({super.key, required this.children, this.height});

  final List<Widget> children;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i += 2) ...[
          if (i > 0) const SizedBox(height: Spacing.s8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _withHeight(children[i])),
                const SizedBox(width: Spacing.s8),
                Expanded(
                  child: i + 1 < children.length
                      ? _withHeight(children[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _withHeight(Widget child) {
    final a = height;
    return a == null
        ? child
        : ConstrainedBox(
            constraints: BoxConstraints(minHeight: a),
            child: child,
          );
  }
}
