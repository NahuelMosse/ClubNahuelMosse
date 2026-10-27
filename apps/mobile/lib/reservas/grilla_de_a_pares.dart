import 'package:flutter/material.dart';
import '../tema/tokens.dart';

/// Dos columnas iguales, como las grillas del prototipo.
class GrillaDeAPares extends StatelessWidget {
  const GrillaDeAPares({super.key, required this.hijos, this.alto});

  final List<Widget> hijos;
  final double? alto;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < hijos.length; i += 2) ...[
          if (i > 0) const SizedBox(height: Medidas.s8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _alto(hijos[i])),
                const SizedBox(width: Medidas.s8),
                Expanded(
                  child: i + 1 < hijos.length
                      ? _alto(hijos[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _alto(Widget hijo) {
    final a = alto;
    return a == null
        ? hijo
        : ConstrainedBox(
            constraints: BoxConstraints(minHeight: a),
            child: hijo,
          );
  }
}
