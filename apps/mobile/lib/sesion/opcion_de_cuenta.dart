import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Una fila de la tarjeta de la cuenta: ícono, texto y, salvo «Cerrar sesión», una flecha.
class OpcionDeCuenta extends StatelessWidget {
  const OpcionDeCuenta({
    super.key,
    required this.icono,
    required this.texto,
    required this.alTocar,
    this.peligro = false,
  });

  final IconData icono;
  final String texto;
  final VoidCallback alTocar;
  final bool peligro;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final color = peligro ? p.stateDangerInk : p.textPrimary;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: alTocar,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Medidas.altoControl),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Medidas.s16),
            child: Row(
              children: [
                Icon(icono, size: 20, color: peligro ? color : p.textSecondary),
                const SizedBox(width: Medidas.s12),
                Expanded(
                  child: Text(
                    texto,
                    style: Textos.cuerpoFuerte.copyWith(color: color),
                  ),
                ),
                if (!peligro)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: p.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
