import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/in_progress.dart';

/// «Dar de baja el espacio», or the notice that the deactivation is in flight. An
/// [onTap] of `null` disables the button.
class SpaceDeactivationButton extends StatelessWidget {
  const SpaceDeactivationButton({
    super.key,
    required this.deactivating,
    required this.onTap,
  });

  final bool deactivating;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (deactivating) return const InProgress('Dando de baja el espacio');
    return OutlineButton(
      label: 'DAR DE BAJA EL ESPACIO',
      danger: true,
      onTap: onTap,
    );
  }
}
