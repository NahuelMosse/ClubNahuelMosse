import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/fixed_bar.dart';
import '../../../theme/tokens.dart';

class AvailabilityActionBar extends StatelessWidget {
  const AvailabilityActionBar({
    super.key,
    required this.text,
    required this.onContinue,
  });

  final String text;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return FixedBar(
      color: p.bgSurface,
      child: PrimaryButton(label: text, onTap: onContinue),
    );
  }
}
