import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../theme/tokens.dart';
import '../../session/presentation/account_card.dart';
import '../../session/presentation/session.dart';

/// «Cerrar sesión» y «Eliminar cuenta»; con la baja en curso, ninguno responde.
class AccountActions extends StatelessWidget {
  const AccountActions({
    super.key,
    required this.session,
    required this.deactivating,
    required this.onConfirmDeactivation,
  });

  final Session session;
  final bool deactivating;
  final VoidCallback onConfirmDeactivation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlineButton(
          label: 'CERRAR SESIÓN',
          onTap: deactivating ? null : () => signOut(context, session),
        ),
        const SizedBox(height: Spacing.s8),
        OutlineButton(
          label: deactivating ? 'ELIMINANDO TU CUENTA…' : 'ELIMINAR CUENTA',
          danger: true,
          onTap: deactivating ? null : onConfirmDeactivation,
        ),
      ],
    );
  }
}
