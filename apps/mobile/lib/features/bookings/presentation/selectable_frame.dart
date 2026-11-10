import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';

/// El marco de un control que se elige, con el estilo de los del prototipo: lima el
/// elegido. El contenido es libre.
class SelectableFrame extends StatelessWidget {
  const SelectableFrame({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
    this.dimmed = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget child;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Spacing.radiusMd),
      side: BorderSide(
        color: selected
            ? p.accentEdge
            : dimmed
            ? p.borderDefault
            : p.borderControl,
      ),
    );
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Opacity(
        opacity: dimmed ? 0.45 : 1,
        child: Material(
          color: selected ? p.accentBase : p.bgSurfaceRaised,
          shape: shape,
          child: InkWell(onTap: onTap, customBorder: shape, child: child),
        ),
      ),
    );
  }
}
