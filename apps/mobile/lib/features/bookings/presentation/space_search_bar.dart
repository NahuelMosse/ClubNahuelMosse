import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/fixed_bar.dart';
import '../../../theme/tokens.dart';

class SpaceSearchBar extends StatelessWidget {
  const SpaceSearchBar({
    super.key,
    required this.alLimpiar,
    required this.alConsultar,
  });

  final VoidCallback? alLimpiar;
  final VoidCallback? alConsultar;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return FixedBar(
      color: p.bgSurface,
      child: Row(
        children: [
          TextActionButton(label: 'LIMPIAR', onTap: alLimpiar),
          const SizedBox(width: Spacing.s12),
          Expanded(
            child: PrimaryButton(label: 'CONSULTAR', onTap: alConsultar),
          ),
        ],
      ),
    );
  }
}
