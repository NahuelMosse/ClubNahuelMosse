import 'package:flutter/material.dart';

import '../../../common/error_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';

/// La confirmación de cancelar una reserva ([text] dice cuál). Devuelve `true` si la
/// persona confirmó.
Future<bool> confirmCancellation(BuildContext context, String text) async {
  final l = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        barrierColor: context.palette.bgScrim,
        builder: (context) => NoticeModal(
          icon: Icons.warning_amber_rounded,
          title: l.bookingCancelTitle,
          text: text,
          primary: l.bookingCancelConfirm,
          primaryDanger: true,
          secondary: l.bookingCancelKeep,
          secondaryOutlined: true,
        ),
      ) ??
      false;
}
