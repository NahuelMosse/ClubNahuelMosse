import 'package:flutter/material.dart';
import '../../../theme/tokens.dart';

class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final active = onTap != null;
    return Semantics(
      container: true,
      button: true,
      enabled: active,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: SizedBox(
        width: Spacing.s48,
        height: Spacing.s48,
        child: Material(
          color: active ? p.bgSurface : Colors.transparent,
          shape: CircleBorder(
            side: BorderSide(
              color: active ? p.borderControl : Colors.transparent,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Icon(
              icon,
              size: 22,
              color: active ? p.textPrimary : p.stateDisabled,
            ),
          ),
        ),
      ),
    );
  }
}
