import 'package:flutter/material.dart';

import '../../../common/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/booking.dart';
import 'booking_exit_bar.dart';
import 'booking_photo_background.dart';
import 'booking_receipt.dart';
import 'booking_steps.dart';

/// El comprobante: la reserva quedó hecha. Espera a que la persona elija adónde ir.
class BookingConfirmedScreen extends StatelessWidget {
  const BookingConfirmedScreen({super.key, required this.reserva});

  final Booking reserva;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: const BookingExitBar(),
      body: Stack(
        children: [
          BookingPhotoBackground(deporte: reserva.sport),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Spacing.s24,
                Spacing.s40,
                Spacing.s24,
                Spacing.s40,
              ),
              children: [
                const BookingSteps(actual: 2),
                const SizedBox(height: Spacing.s24),
                Celebration(
                  center: SuccessPulse(
                    icon: Icons.check_circle_outline_rounded,
                    background: p.stateSuccessMuted,
                    ink: p.stateSuccessInk,
                  ),
                  cheer: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            l.bookingCheer,
                            style: Texts.display.copyWith(
                              fontSize: 36,
                              color: p.accentBase,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.s8),
                      Semantics(
                        header: true,
                        liveRegion: true,
                        child: Text(
                          l.bookingConfirmedTitle,
                          textAlign: TextAlign.center,
                          style: Texts.h1.copyWith(color: p.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  receipt: BookingReceipt(reserva: reserva),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
