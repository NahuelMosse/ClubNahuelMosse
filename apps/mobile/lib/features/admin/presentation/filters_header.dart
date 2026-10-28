import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// The filter panel title and its close button.
class FiltersHeader extends StatelessWidget {
  const FiltersHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.s24,
        Spacing.s16,
        Spacing.s16,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                'Filtros',
                style: Texts.h2.copyWith(color: p.textPrimary),
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Cerrar',
            icon: const Icon(Icons.close_rounded),
            color: p.textSecondary,
          ),
        ],
      ),
    );
  }
}
