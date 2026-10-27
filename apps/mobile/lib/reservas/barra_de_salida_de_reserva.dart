import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/boton.dart';
import '../tema/tokens.dart';

/// VER MIS RESERVAS y «Volver al inicio», al pie del comprobante.
class BarraDeSalidaDeReserva extends StatelessWidget {
  const BarraDeSalidaDeReserva({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Medidas.s24,
          Medidas.s8,
          Medidas.s24,
          Medidas.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BotonPrimario(
              texto: 'VER MIS RESERVAS',
              alTocar: () => context.go('/reservas'),
            ),
            const SizedBox(height: Medidas.s8),
            Center(
              child: BotonTexto(
                texto: 'Volver al inicio',
                alTocar: () => context.go('/inicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
