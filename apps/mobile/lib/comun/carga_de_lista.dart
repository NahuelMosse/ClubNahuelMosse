import 'package:flutter/material.dart';

import '../tema/tokens.dart';
import 'boton.dart';
import 'movimiento.dart';

/// Lo que se ve en el lugar de una lista cuando su lectura falló: REINTENTAR.
class ReintentoDeLista extends StatelessWidget {
  const ReintentoDeLista({super.key, required this.alTocar});

  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Medidas.s24),
    child: Center(
      child: BotonTexto(texto: 'REINTENTAR', alTocar: alTocar),
    ),
  );
}

/// El cambio entre las listas de dos filtros o pestañas, sin animar si la persona pidió
/// menos movimiento.
class CambioDeLista extends StatelessWidget {
  const CambioDeLista({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : Movimiento.cambioDeLista,
    layoutBuilder: (actual, anteriores) => Stack(
      alignment: Alignment.topCenter,
      children: [...anteriores, ?actual],
    ),
    child: child,
  );
}
