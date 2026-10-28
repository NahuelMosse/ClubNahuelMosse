import 'package:flutter/material.dart';

import '../../../common/error_dialog.dart';
import '../../../theme/tokens.dart';

/// La confirmación de cancelar una reserva ([texto] dice cuál). Devuelve `true` si la
/// persona confirmó.
Future<bool> confirmarCancelacion(BuildContext context, String texto) async =>
    await showDialog<bool>(
      context: context,
      barrierColor: context.palette.bgScrim,
      builder: (context) => NoticeModal(
        icon: Icons.warning_amber_rounded,
        title: '¿Cancelar la reserva?',
        text: texto,
        primary: 'CANCELAR RESERVA',
        primaryDanger: true,
        secondary: 'NO CANCELAR',
        secondaryOutlined: true,
      ),
    ) ??
    false;
