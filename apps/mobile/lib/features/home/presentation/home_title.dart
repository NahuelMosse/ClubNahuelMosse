import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// El título de una zona de la pantalla.
class HomeTitle extends StatelessWidget {
  const HomeTitle(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      texto,
      style: Texts.overline.copyWith(color: context.palette.textMuted),
    ),
  );
}
