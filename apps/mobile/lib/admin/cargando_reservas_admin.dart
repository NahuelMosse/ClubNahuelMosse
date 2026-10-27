import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// El sliver «Cargando reservas…» del historial.
class CargandoReservasAdmin extends StatelessWidget {
  const CargandoReservasAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Medidas.s40),
        child: Column(
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                'Cargando reservas…',
                style: Textos.sobretitulo.copyWith(color: p.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
