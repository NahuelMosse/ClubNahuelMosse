// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/badge.dart';
import '../../../theme/tokens.dart';
import '../../bookings/domain/booking_status.dart';

/// `Badge-Estado` of the admin history: same color code as «Mis reservas».
class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip({super.key, required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (background, ink) = switch (status) {
      BookingStatus.active => (p.stateSuccessMuted, p.stateSuccessInk),
      BookingStatus.voided ||
      BookingStatus.canceled => (p.stateDangerMuted, p.stateDangerInk),
      BookingStatus.completed => (p.bgSurface, p.textSecondary),
    };
    return StatusBadge(
      label: status.label.toUpperCase(),
      background: background,
      ink: ink,
    );
  }
}
