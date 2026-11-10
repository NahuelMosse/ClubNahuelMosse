import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/slot.dart';
import 'grow.dart';
import 'selectable_frame.dart';

class SlotCard extends StatelessWidget {
  const SlotCard({
    super.key,
    required this.slot,
    required this.chosen,
    required this.onTap,
    this.actual = false,
  });

  final Slot slot;
  final bool chosen;
  final VoidCallback? onTap;

  /// Es el horario de la reserva que se modifica.
  final bool actual;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final ink = chosen ? p.accentOn : p.textPrimary;
    return Grow(
      active: chosen,
      child: SelectableFrame(
        label: actual ? '${slot.text} ${l.availabilityCurrent}' : slot.text,
        selected: chosen,
        onTap: onTap,
        dimmed: !slot.available,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(slot.text, style: Texts.bodyStrong.copyWith(color: ink)),
              if (actual)
                Text(
                  l.availabilityCurrent,
                  style: Texts.caption.copyWith(
                    color: chosen ? p.accentOn : p.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
