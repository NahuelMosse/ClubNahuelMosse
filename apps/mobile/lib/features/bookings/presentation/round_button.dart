import 'package:flutter/material.dart';
import '../../../theme/tokens.dart';

class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.icono,
    required this.etiqueta,
    required this.alTocar,
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final activo = alTocar != null;
    return Semantics(
      container: true,
      button: true,
      enabled: activo,
      label: etiqueta,
      excludeSemantics: true,
      onTap: alTocar,
      child: SizedBox(
        width: Spacing.s48,
        height: Spacing.s48,
        child: Material(
          color: activo ? p.bgSurface : Colors.transparent,
          shape: CircleBorder(
            side: BorderSide(
              color: activo ? p.borderControl : Colors.transparent,
            ),
          ),
          child: InkWell(
            onTap: alTocar,
            customBorder: const CircleBorder(),
            child: Icon(
              icono,
              size: 22,
              color: activo ? p.textPrimary : p.stateDisabled,
            ),
          ),
        ),
      ),
    );
  }
}
