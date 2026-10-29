import 'package:flutter/material.dart';
import '../../../common/badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../domain/booking_status.dart';
import 'booking_status_text.dart';

/// `Badge-Estado`.
class StatusLabel extends StatelessWidget {
  const StatusLabel({super.key, required this.estado});

  final BookingStatus estado;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (fondo, tinta) = switch (estado) {
      BookingStatus.active => (p.bgSurface, p.stateSuccessInk),
      BookingStatus.voided => (p.stateDangerMuted, p.stateDangerInk),
      _ => (p.bgSurface, p.textSecondary),
    };
    return StatusBadge(
      label: bookingStatusText(
        AppLocalizations.of(context),
        estado,
      ).toUpperCase(),
      background: fondo,
      ink: tinta,
    );
  }
}
