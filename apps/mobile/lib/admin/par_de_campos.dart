import 'package:flutter/material.dart';
import '../tema/tokens.dart';

/// Dos campos lado a lado, como el prototipo; en un teléfono chico no entran sus valores
/// («Al aire libre», «Sin iluminación») y van uno debajo del otro.
class ParDeCampos extends StatelessWidget {
  const ParDeCampos({
    super.key,
    required this.izquierda,
    required this.derecha,
  });

  final Widget izquierda;
  final Widget derecha;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, limites) => limites.maxWidth < 340
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              izquierda,
              const SizedBox(height: Medidas.s12),
              derecha,
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: izquierda),
              const SizedBox(width: Medidas.s12),
              Expanded(child: derecha),
            ],
          ),
  );
}
