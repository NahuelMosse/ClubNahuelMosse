import 'package:flutter/material.dart';

import '../../../common/error_dialog.dart';
import '../../../theme/tokens.dart';

/// Confirm deactivating a venue: DAR DE BAJA returns `true`.
Future<bool> confirmVenueDeactivation(
  BuildContext context,
  String text,
) async =>
    await showDialog<bool>(
      context: context,
      barrierColor: context.palette.bgScrim,
      builder: (context) => NoticeModal(
        icon: Icons.warning_amber_rounded,
        title: '¿Dar de baja la sede?',
        text: text,
        primary: 'DAR DE BAJA',
        primaryDanger: true,
        secondary: 'CANCELAR',
        secondaryOutlined: true,
      ),
    ) ??
    false;

/// The venue has pending bookings and cannot be deactivated.
Future<void> showVenueWithBookings(BuildContext context) => showDialog<void>(
  context: context,
  barrierColor: context.palette.bgScrim,
  builder: (context) => const NoticeModal(
    icon: Icons.event_busy_rounded,
    title: 'No se puede dar de baja la sede',
    text:
        'La sede posee reservas futuras asociadas a sus espacios deportivos. '
        'Gestionalas primero.',
    primary: 'ACEPTAR',
  ),
);

/// Confirm deactivating the space [name]: CONFIRMAR BAJA returns `true`.
Future<bool> confirmSpaceDeactivation(
  BuildContext context,
  String name,
) async =>
    await showDialog<bool>(
      context: context,
      barrierColor: context.palette.bgScrim,
      builder: (context) => NoticeModal(
        icon: Icons.warning_amber_rounded,
        title: '¿Dar de baja el espacio?',
        text: '$name. La acción es permanente.',
        primary: 'CONFIRMAR BAJA',
        primaryDanger: true,
        secondary: 'CANCELAR',
        secondaryOutlined: true,
      ),
    ) ??
    false;

/// The space has pending bookings and cannot be deactivated.
Future<void> showSpaceWithBookings(BuildContext context) => showDialog<void>(
  context: context,
  barrierColor: context.palette.bgScrim,
  builder: (context) => const NoticeModal(
    icon: Icons.event_busy_rounded,
    title: 'No se puede dar de baja el espacio',
    text: 'El espacio posee reservas futuras. Gestionalas primero.',
    primary: 'ACEPTAR',
  ),
);
