import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Lo que se ve dentro de un [CampoSelector]: el valor elegido o el placeholder, y el ícono.
class ValorDelSelector extends StatelessWidget {
  const ValorDelSelector({
    super.key,
    required this.valor,
    required this.placeholder,
    required this.icono,
    required this.soloLectura,
  });

  final String? valor;
  final String placeholder;
  final IconData icono;
  final bool soloLectura;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final elegido = valor;
    return Row(
      children: [
        Expanded(
          child: Text(
            elegido ?? placeholder,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Textos.cuerpo.copyWith(
              // Apagado, pero el dato se tiene que poder leer.
              color: soloLectura
                  ? p.textSecondary
                  : elegido == null
                  ? p.textMuted
                  : p.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: Medidas.s12),
        Icon(
          icono,
          size: 24,
          color: soloLectura ? p.stateDisabled : p.textSecondary,
        ),
      ],
    );
  }
}
