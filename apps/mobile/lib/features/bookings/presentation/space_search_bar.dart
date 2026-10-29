import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/fixed_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';

class SpaceSearchBar extends StatelessWidget {
  const SpaceSearchBar({
    super.key,
    required this.alLimpiar,
    required this.alConsultar,
    required this.consultando,
  });

  final VoidCallback? alLimpiar;
  final VoidCallback? alConsultar;
  final bool consultando;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return FixedBar(
      color: p.bgSurface,
      child: Row(
        children: [
          TextActionButton(label: l.spaceSearchClear, onTap: alLimpiar),
          const SizedBox(width: Spacing.s12),
          Expanded(
            child: PrimaryButton(
              label: l.spaceSearchRun,
              onTap: alConsultar,
              loading: consultando,
            ),
          ),
        ],
      ),
    );
  }
}
