import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// La fila de arriba del panel de avisos: el título y «MARCAR TODAS».
class PanelHeader extends StatelessWidget {
  const PanelHeader({super.key, required this.onMarkAll});

  final VoidCallback onMarkAll;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          // Un lector de pantalla anuncia el panel cuando aparece.
          child: Semantics(
            header: true,
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(left: Spacing.s4),
              child: Text(
                'NOTIFICACIONES',
                style: Texts.overline.copyWith(color: p.textMuted),
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          label: 'MARCAR TODAS',
          excludeSemantics: true,
          onTap: onMarkAll,
          child: InkWell(
            onTap: onMarkAll,
            borderRadius: BorderRadius.circular(Spacing.radiusMd),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: kMinInteractiveDimension,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.s8),
                child: Center(
                  child: Text(
                    'MARCAR TODAS',
                    style: Texts.overline.copyWith(color: p.accentInk),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
