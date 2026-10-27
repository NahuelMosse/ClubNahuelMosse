import 'package:flutter/material.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// El título de una zona de la pantalla.
class TituloDeInicio extends StatelessWidget {
  const TituloDeInicio(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      texto,
      style: Textos.sobretitulo.copyWith(color: context.paleta.textMuted),
    ),
  );
}
