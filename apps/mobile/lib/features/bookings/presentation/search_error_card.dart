import 'package:flutter/material.dart';
import '../../../common/button.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// `Card-Error` del prototipo: la consulta falló y los filtros siguen cargados.
class SearchErrorCard extends StatelessWidget {
  const SearchErrorCard({
    super.key,
    required this.sinConexion,
    required this.alVolver,
    required this.alReintentar,
  });

  final bool sinConexion;
  final VoidCallback alVolver;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(Spacing.s16),
        decoration: BoxDecoration(
          color: p.stateDangerMuted,
          borderRadius: BorderRadius.circular(Spacing.radiusLg),
          border: Border.all(color: p.stateDanger),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'NO SE PUDO CONSULTAR',
              style: Texts.overline.copyWith(color: p.stateDangerInk),
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              'No se pudo consultar la disponibilidad',
              style: Texts.title.copyWith(color: p.textPrimary),
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              '${sinConexion ? 'Revisá tu conexión e intentá nuevamente.' : 'El servidor no respondió. Intentá más tarde.'}'
              ' Los filtros que cargaste se mantienen.',
              style: Texts.body.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: Spacing.s12),
            Row(
              children: [
                TextActionButton(label: 'VOLVER', onTap: alVolver),
                const SizedBox(width: Spacing.s8),
                Expanded(
                  child: OutlineButton(
                    label: 'REINTENTAR',
                    onTap: alReintentar,
                    danger: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
