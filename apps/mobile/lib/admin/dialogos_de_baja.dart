import 'package:flutter/material.dart';

import '../comun/dialogo_error.dart';
import '../tema/tokens.dart';

/// Confirmar la baja de una sede: DAR DE BAJA devuelve `true`.
Future<bool> confirmarBajaDeSede(BuildContext context, String texto) async =>
    await showDialog<bool>(
      context: context,
      barrierColor: context.paleta.bgScrim,
      builder: (context) => ModalDeAviso(
        icono: Icons.warning_amber_rounded,
        titulo: '¿Dar de baja la sede?',
        texto: texto,
        principal: 'DAR DE BAJA',
        principalPeligro: true,
        secundaria: 'CANCELAR',
        secundariaContorno: true,
      ),
    ) ??
    false;

/// La sede tiene reservas pendientes y no se puede dar de baja.
Future<void> mostrarSedeConReservas(BuildContext context) => showDialog<void>(
  context: context,
  barrierColor: context.paleta.bgScrim,
  builder: (context) => const ModalDeAviso(
    icono: Icons.event_busy_rounded,
    titulo: 'No se puede dar de baja la sede',
    texto:
        'La sede posee reservas futuras asociadas a sus espacios deportivos. '
        'Gestionalas primero.',
    principal: 'ACEPTAR',
  ),
);

/// Confirmar la baja del espacio [nombre]: CONFIRMAR BAJA devuelve `true`.
Future<bool> confirmarBajaDeEspacio(
  BuildContext context,
  String nombre,
) async =>
    await showDialog<bool>(
      context: context,
      barrierColor: context.paleta.bgScrim,
      builder: (context) => ModalDeAviso(
        icono: Icons.warning_amber_rounded,
        titulo: '¿Dar de baja el espacio?',
        texto: '$nombre. La acción es permanente.',
        principal: 'CONFIRMAR BAJA',
        principalPeligro: true,
        secundaria: 'CANCELAR',
        secundariaContorno: true,
      ),
    ) ??
    false;

/// El espacio tiene reservas pendientes y no se puede dar de baja.
Future<void> mostrarEspacioConReservas(BuildContext context) =>
    showDialog<void>(
      context: context,
      barrierColor: context.paleta.bgScrim,
      builder: (context) => const ModalDeAviso(
        icono: Icons.event_busy_rounded,
        titulo: 'No se puede dar de baja el espacio',
        texto: 'El espacio posee reservas futuras. Gestionalas primero.',
        principal: 'ACEPTAR',
      ),
    );
