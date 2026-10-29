import 'package:flutter/material.dart';

import '../../../common/error_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';

/// La confirmación de cancelar una reserva ([texto] dice cuál). Devuelve `true` si la
/// persona confirmó.
Future<bool> confirmarCancelacion(BuildContext context, String texto) async {
  final l = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        barrierColor: context.palette.bgScrim,
        builder: (context) => NoticeModal(
          icon: Icons.warning_amber_rounded,
          title: l.bookingCancelTitle,
          text: texto,
          primary: l.bookingCancelConfirm,
          primaryDanger: true,
          secondary: l.bookingCancelKeep,
          secondaryOutlined: true,
        ),
      ) ??
      false;
}
