import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Avisa que la API se está despertando mientras [despertando] sea `true`.
class AvisoDespertando extends StatelessWidget {
  const AvisoDespertando({super.key, required this.despertando});

  final ValueListenable<bool> despertando;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: despertando,
      builder: (context, visible, _) {
        if (!visible) return const SizedBox.shrink();
        final p = context.paleta;
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(Medidas.s12),
              child: Material(
                color: p.bgSurfaceRaised,
                borderRadius: BorderRadius.circular(Medidas.radioLg),
                child: Padding(
                  padding: const EdgeInsets.all(Medidas.s12),
                  child: Text(
                    'El servidor se está despertando, puede tardar hasta un minuto.',
                    textAlign: TextAlign.center,
                    style: Textos.cuerpo.copyWith(color: p.textPrimary),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
