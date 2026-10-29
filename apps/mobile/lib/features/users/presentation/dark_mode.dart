import 'package:flutter/material.dart';

import '../../../common/appearance.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

class DarkMode extends StatelessWidget {
  const DarkMode({super.key, required this.appearance});

  final Appearance appearance;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: appearance,
      builder: (context, _) {
        void toggle() => appearance.change(dark: !appearance.dark);
        // Toda la fila alterna el tema, no sólo el interruptor.
        return Semantics(
          container: true,
          label: l10n.profileDarkMode,
          toggled: appearance.dark,
          onTap: toggle,
          excludeSemantics: true,
          child: InkWell(
            onTap: toggle,
            borderRadius: BorderRadius.circular(Spacing.radiusMd),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: Spacing.controlHeight,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.dark_mode_outlined,
                    size: 20,
                    color: p.textSecondary,
                  ),
                  const SizedBox(width: Spacing.s12),
                  Expanded(
                    child: Text(
                      l10n.profileDarkMode,
                      style: Texts.bodyStrong.copyWith(color: p.textPrimary),
                    ),
                  ),
                  Switch(
                    value: appearance.dark,
                    activeTrackColor: p.accentBase,
                    activeThumbColor: p.accentOn,
                    onChanged: (dark) => appearance.change(dark: dark),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
