import 'package:flutter/material.dart';

import '../sesion/sesion.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// «BUENOS DÍAS,» y el nombre del socio, que se actualiza con la [sesion].
class SaludoDeInicio extends StatelessWidget {
  const SaludoDeInicio({super.key, required this.sesion});

  final Sesion sesion;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BUENOS DÍAS,',
          style: Textos.sobretitulo.copyWith(color: p.accentOnMedia),
        ),
        const SizedBox(height: Medidas.s4),
        ListenableBuilder(
          listenable: sesion,
          builder: (context, _) => Text(
            sesion.perfil?.nombre ?? '',
            style: Textos.h1.copyWith(color: p.textOnMedia),
          ),
        ),
      ],
    );
  }
}
