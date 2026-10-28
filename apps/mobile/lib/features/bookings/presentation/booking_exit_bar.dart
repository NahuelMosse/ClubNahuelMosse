import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/button.dart';
import '../../../theme/tokens.dart';

/// VER MIS RESERVAS y «Volver al inicio», al pie del comprobante.
class BookingExitBar extends StatelessWidget {
  const BookingExitBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.s24,
          Spacing.s8,
          Spacing.s24,
          Spacing.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrimaryButton(
              label: 'VER MIS RESERVAS',
              onTap: () => context.go('/reservas'),
            ),
            const SizedBox(height: Spacing.s8),
            Center(
              child: TextActionButton(
                label: 'Volver al inicio',
                onTap: () => context.go('/inicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
