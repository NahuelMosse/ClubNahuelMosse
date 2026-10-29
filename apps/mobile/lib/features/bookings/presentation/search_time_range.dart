import 'package:flutter/material.dart';

import '../../../common/selector.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../domain/search_rules.dart';

/// Los selectores DESDE y HASTA del formulario de consulta de canchas.
class SearchTimeRange extends StatelessWidget {
  const SearchTimeRange({
    super.key,
    required this.desde,
    required this.hasta,
    required this.errorDesde,
    required this.errorHasta,
    required this.alElegirDesde,
    required this.alElegirHasta,
  });

  final int desde;
  final int hasta;
  final String? errorDesde;
  final String? errorHasta;
  final VoidCallback? alElegirDesde;
  final VoidCallback? alElegirHasta;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SelectorField(
            label: l.spaceSearchFrom.toUpperCase(),
            semanticLabel: l.spaceSearchFrom,
            value: hhmm(desde),
            placeholder: '',
            icon: Icons.expand_more_rounded,
            onTap: alElegirDesde,
            error: errorDesde,
          ),
        ),
        const SizedBox(width: Spacing.s12),
        Expanded(
          child: SelectorField(
            label: l.spaceSearchTo.toUpperCase(),
            semanticLabel: l.spaceSearchTo,
            value: hhmm(hasta),
            placeholder: '',
            icon: Icons.expand_more_rounded,
            onTap: alElegirHasta,
            error: errorHasta,
          ),
        ),
      ],
    );
  }
}
