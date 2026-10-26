import 'package:flutter/material.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

class FilaDePerfil extends StatelessWidget {
  const FilaDePerfil({
    super.key,
    required this.icono,
    required this.texto,
    required this.alTocar,
  });

  final IconData icono;
  final String texto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: alTocar,
        borderRadius: BorderRadius.circular(Medidas.radioMd),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Medidas.altoControl),
          child: Row(
            children: [
              Icon(icono, size: 20, color: p.textSecondary),
              const SizedBox(width: Medidas.s12),
              Expanded(
                child: Text(
                  texto,
                  style: Textos.cuerpoFuerte.copyWith(color: p.textPrimary),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: p.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
