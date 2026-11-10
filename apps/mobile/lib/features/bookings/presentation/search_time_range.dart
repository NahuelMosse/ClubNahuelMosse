import 'package:flutter/material.dart';

import '../../../common/selector.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../domain/search_rules.dart';

/// Los selectores DESDE y HASTA del formulario de consulta de canchas.
class SearchTimeRange extends StatelessWidget {
  const SearchTimeRange({
    super.key,
    required this.from,
    required this.to,
    required this.fromError,
    required this.toError,
    required this.onPickFrom,
    required this.onPickTo,
  });

  final int from;
  final int to;
  final String? fromError;
  final String? toError;
  final VoidCallback? onPickFrom;
  final VoidCallback? onPickTo;

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
            value: hhmm(from),
            placeholder: '',
            icon: Icons.expand_more_rounded,
            onTap: onPickFrom,
            error: fromError,
          ),
        ),
        const SizedBox(width: Spacing.s12),
        Expanded(
          child: SelectorField(
            label: l.spaceSearchTo.toUpperCase(),
            semanticLabel: l.spaceSearchTo,
            value: hhmm(to),
            placeholder: '',
            icon: Icons.expand_more_rounded,
            onTap: onPickTo,
            error: toError,
          ),
        ),
      ],
    );
  }
}
