import 'package:flutter/material.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// `Btn-Small`: acción secundaria dentro de una tarjeta.
class BotonChico extends StatelessWidget {
  const BotonChico({
    super.key,
    required this.texto,
    required this.icono,
    required this.alTocar,
  });

  final String texto;
  final IconData icono;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return OutlinedButton.icon(
      onPressed: alTocar,
      icon: Icon(icono, size: 15),
      label: Text(texto),
      style: OutlinedButton.styleFrom(
        foregroundColor: p.textPrimary,
        side: BorderSide(color: p.borderDefault),
        shape: const StadiumBorder(),
        minimumSize: const Size(0, Medidas.tactil),
        textStyle: Textos.leyenda,
        padding: const EdgeInsets.symmetric(horizontal: Medidas.s12),
      ),
    );
  }
}
