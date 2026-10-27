import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/boton.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// «¿No tenés cuenta? COMENZAR», sobre la foto del inicio de sesión.
class EnlaceARegistro extends StatelessWidget {
  const EnlaceARegistro({super.key, required this.enviando});

  final bool enviando;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '¿No tenés cuenta?',
          style: Textos.leyenda.copyWith(color: p.textOnMediaMuted),
        ),
        BotonTexto(
          texto: 'COMENZAR',
          icono: Icons.arrow_forward_rounded,
          sobreFoto: true,
          alTocar: enviando ? null : () => context.go('/registro'),
        ),
      ],
    );
  }
}
