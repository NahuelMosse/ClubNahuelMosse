import 'package:flutter/material.dart';

import '../tema/tokens.dart';
import 'isotipo.dart';

/// Espera de arranque: el isotipo oscuro sobre el verde eléctrico, igual que la pantalla nativa,
/// con un indicador de progreso debajo porque la API puede tardar en despertar.
class PantallaDeCarga extends StatelessWidget {
  const PantallaDeCarga({super.key});

  /// Oscuro en ambos temas: sobre el verde el acento no se vería.
  static final _tinta = Paleta.oscura.textInverse;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.paleta.accentBase,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Isotipo(tamano: 120, decorativo: true, color: _tinta),
          const SizedBox(height: 32),
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(color: _tinta, strokeWidth: 3),
          ),
        ],
      ),
    ),
  );
}
