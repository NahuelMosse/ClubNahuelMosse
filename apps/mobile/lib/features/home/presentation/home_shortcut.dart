import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// Una tarjeta de ACCESOS RÁPIDOS: ícono, título y para qué sirve.
class HomeShortcut extends StatelessWidget {
  const HomeShortcut({
    super.key,
    required this.icono,
    required this.titulo,
    required this.texto,
    required this.alTocar,
  });

  final IconData icono;
  final String titulo;
  final String texto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Spacing.radiusLg),
      side: BorderSide(color: p.borderDefault),
    );
    return Semantics(
      button: true,
      child: Material(
        color: p.bgSurfaceRaised,
        shape: forma,
        child: InkWell(
          onTap: alTocar,
          customBorder: forma,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, color: p.accentInk),
                const SizedBox(height: Spacing.s16),
                Text(
                  titulo,
                  style: Texts.bodyStrong.copyWith(color: p.textPrimary),
                ),
                const SizedBox(height: Spacing.s4),
                Text(
                  texto,
                  style: Texts.caption.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
