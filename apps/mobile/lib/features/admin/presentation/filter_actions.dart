import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../theme/tokens.dart';

/// LIMPIAR and APLICAR at the foot of the filter panel; a `null` [onApply] disables APLICAR.
class FilterActions extends StatelessWidget {
  const FilterActions({
    super.key,
    required this.onClear,
    required this.onApply,
  });

  final VoidCallback onClear;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.s24,
        0,
        Spacing.s24,
        Spacing.s24,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlineButton(label: 'LIMPIAR', onTap: onClear),
          ),
          const SizedBox(width: Spacing.s12),
          Expanded(
            child: PrimaryButton(label: 'APLICAR', onTap: onApply),
          ),
        ],
      ),
    );
  }
}
