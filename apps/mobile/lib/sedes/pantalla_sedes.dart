import 'package:flutter/material.dart';

import '../comun/barra_inferior.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Las sedes del club, desde la pestaña SEDES.
class PantallaSedes extends StatelessWidget {
  const PantallaSedes({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: const BarraInferior(actual: Seccion.sedes),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Medidas.s24),
          child: Semantics(
            header: true,
            child: Text(
              'Sedes',
              style: Textos.h1.copyWith(color: p.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
