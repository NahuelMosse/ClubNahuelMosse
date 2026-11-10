// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../bookings/domain/booking.dart';
import '../../bookings/presentation/booking_card.dart';
import '../../spaces/domain/space.dart';
import 'home_title.dart';

/// «Tu próxima reserva»: la tarjeta de Mis reservas, con sus dos acciones.
class NextBooking extends StatelessWidget {
  const NextBooking({
    super.key,
    required this.booking,
    required this.catalog,
    required this.cancelling,
    required this.onCancel,
    required this.onModify,
  });

  final Booking booking;
  final Catalog catalog;
  final bool cancelling;
  final VoidCallback? onCancel;
  final VoidCallback? onModify;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.s24,
        Spacing.s24,
        Spacing.s24,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: HomeTitle(l10n.homeNextBooking)),
              TextActionButton(
                label: l10n.homeViewAll,
                onTap: () => context.go('/bookings'),
              ),
            ],
          ),
          const SizedBox(height: Spacing.s12),
          BookingCard(
            booking: booking,
            catalog: catalog,
            cancelable: booking.cancelable,
            cancelling: cancelling,
            countdown: true,
            onCancel: onCancel,
            onModify: onModify,
          ),
        ],
      ),
    );
  }
}
