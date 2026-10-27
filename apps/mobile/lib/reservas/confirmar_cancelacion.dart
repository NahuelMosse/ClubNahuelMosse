import 'package:flutter/material.dart';

import '../comun/dialogo_error.dart';
import '../tema/tokens.dart';

/// La confirmación de cancelar una reserva ([texto] dice cuál). Devuelve `true` si la
/// persona confirmó.
Future<bool> confirmarCancelacion(BuildContext context, String texto) async =>
    await showDialog<bool>(
      context: context,
      barrierColor: context.paleta.bgScrim,
      builder: (context) => ModalDeAviso(
        icono: Icons.warning_amber_rounded,
        titulo: '¿Cancelar la reserva?',
        texto: texto,
        principal: 'CANCELAR RESERVA',
        principalPeligro: true,
        secundaria: 'NO CANCELAR',
        secundariaContorno: true,
      ),
    ) ??
    false;
