import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';

/// «VER MIS RESERVAS» and «Volver al inicio», at the foot of the receipt.
class BookingExitBar extends StatelessWidget {
  const BookingExitBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
              label: l.bookingSeeMine,
              onTap: () => context.go('/bookings'),
            ),
            const SizedBox(height: Spacing.s8),
            Center(
              child: TextActionButton(
                label: l.bookingBackHome,
                onTap: () => context.go('/home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
