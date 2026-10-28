import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// `Btn-Small`: acción secundaria dentro de una tarjeta.
class SmallButton extends StatelessWidget {
  const SmallButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        foregroundColor: p.textPrimary,
        side: BorderSide(color: p.borderDefault),
        shape: const StadiumBorder(),
        minimumSize: const Size(0, Spacing.touchTarget),
        textStyle: Texts.caption,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.s12),
      ),
    );
  }
}
