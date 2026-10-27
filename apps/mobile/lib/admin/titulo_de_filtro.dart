import 'package:flutter/material.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

class TituloDeFiltro extends StatelessWidget {
  const TituloDeFiltro(this.texto, {super.key});
  final String texto;

  @override
  Widget build(BuildContext context) => Text(
    texto,
    style: Textos.sobretitulo.copyWith(color: context.paleta.textMuted),
  );
}
