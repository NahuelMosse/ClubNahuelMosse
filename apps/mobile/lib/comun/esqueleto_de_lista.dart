import 'package:flutter/material.dart';

import '../tema/tokens.dart';
import 'esqueleto.dart';

// kit-shape: _Aviso es un detalle privado de la forma `aviso`, no tiene otro uso.
/// La forma de lo que va a aparecer en una lista.
enum FormaDeEsqueleto { sede, cancha, reserva, aviso, grilla }

/// Los bloques de una lista que carga, con la forma de la tarjeta real.
class EsqueletoDeLista extends StatelessWidget {
  const EsqueletoDeLista({super.key, required this.forma, this.cantidad = 3});

  final FormaDeEsqueleto forma;
  final int cantidad;

  @override
  Widget build(BuildContext context) => ZonaDeEsqueletos(
    child: SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cantidad; i++) ...[
            if (i > 0) SizedBox(height: _separacion),
            _fila(),
          ],
        ],
      ),
    ),
  );

  double get _separacion =>
      forma == FormaDeEsqueleto.grilla ? Medidas.s8 : Medidas.s12;

  Widget _fila() => switch (forma) {
    FormaDeEsqueleto.sede => const Esqueleto(alto: 220, radio: Medidas.radioLg),
    FormaDeEsqueleto.cancha => const Esqueleto(alto: 96),
    FormaDeEsqueleto.reserva => const Esqueleto(alto: 112),
    FormaDeEsqueleto.aviso => const _Aviso(),
    FormaDeEsqueleto.grilla => const Row(
      children: [
        Expanded(child: Esqueleto(alto: Medidas.altoControl)),
        SizedBox(width: Medidas.s8),
        Expanded(child: Esqueleto(alto: Medidas.altoControl)),
      ],
    ),
  };
}

class _Aviso extends StatelessWidget {
  const _Aviso();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 76,
    child: Row(
      children: [
        Esqueleto(width: 40, alto: 40),
        SizedBox(width: Medidas.s12),
        Expanded(child: Esqueleto(alto: 40)),
      ],
    ),
  );
}
