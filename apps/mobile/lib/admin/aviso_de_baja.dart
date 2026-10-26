import 'package:flutter/material.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// La reserva perteneció a un espacio o una sede que ya se dio de baja (FA8): no se le
/// atribuye la anulación al socio.
class AvisoDeBaja extends StatelessWidget {
  const AvisoDeBaja({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Medidas.s16,
        vertical: Medidas.s12,
      ),
      decoration: BoxDecoration(
        color: p.bgSurface,
        borderRadius: BorderRadius.circular(Medidas.radioMd),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: p.textMuted),
          const SizedBox(width: Medidas.s8),
          Expanded(
            child: Text(
              'Baja del espacio deportivo',
              style: Textos.leyenda.copyWith(color: p.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
