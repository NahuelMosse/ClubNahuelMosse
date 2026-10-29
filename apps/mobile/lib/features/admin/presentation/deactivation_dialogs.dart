import 'package:flutter/material.dart';

import '../../../common/error_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';

/// Confirm deactivating a venue: DAR DE BAJA returns `true`.
Future<bool> confirmVenueDeactivation(
  BuildContext context,
  String text,
) async {
  final l10n = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        barrierColor: context.palette.bgScrim,
        builder: (context) => NoticeModal(
          icon: Icons.warning_amber_rounded,
          title: l10n.adminDeactivateVenueTitle,
          text: text,
          primary: l10n.adminDeactivateConfirm,
          primaryDanger: true,
          secondary: l10n.adminCancel,
          secondaryOutlined: true,
        ),
      ) ??
      false;
}

/// The venue has pending bookings and cannot be deactivated.
Future<void> showVenueWithBookings(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    barrierColor: context.palette.bgScrim,
    builder: (context) => NoticeModal(
      icon: Icons.event_busy_rounded,
      title: l10n.adminVenueHasBookingsTitle,
      text: l10n.adminVenueHasBookingsText,
      primary: l10n.adminAccept,
    ),
  );
}

/// Confirm deactivating the space [name]: CONFIRMAR BAJA returns `true`.
Future<bool> confirmSpaceDeactivation(
  BuildContext context,
  String name,
) async {
  final l10n = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        barrierColor: context.palette.bgScrim,
        builder: (context) => NoticeModal(
          icon: Icons.warning_amber_rounded,
          title: l10n.adminDeactivateSpaceTitle,
          text: l10n.adminDeactivateSpaceText(name),
          primary: l10n.adminDeactivateSpaceConfirm,
          primaryDanger: true,
          secondary: l10n.adminCancel,
          secondaryOutlined: true,
        ),
      ) ??
      false;
}

/// The space has pending bookings and cannot be deactivated.
Future<void> showSpaceWithBookings(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    barrierColor: context.palette.bgScrim,
    builder: (context) => NoticeModal(
      icon: Icons.event_busy_rounded,
      title: l10n.adminSpaceHasBookingsTitle,
      text: l10n.adminSpaceHasBookingsText,
      primary: l10n.adminAccept,
    ),
  );
}
