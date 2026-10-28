import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/fixed_bar.dart';
import '../../../theme/tokens.dart';

class AvailabilityActionBar extends StatelessWidget {
  const AvailabilityActionBar({
    super.key,
    required this.texto,
    required this.alContinuar,
  });

  final String texto;
  final VoidCallback? alContinuar;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return FixedBar(
      color: p.bgSurface,
      child: PrimaryButton(label: texto, onTap: alContinuar),
    );
  }
}
