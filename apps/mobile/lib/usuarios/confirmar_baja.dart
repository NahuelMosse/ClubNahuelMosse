import 'package:flutter/material.dart';
import '../comun/boton.dart';
import '../comun/dialogo_error.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

class ConfirmarBaja extends StatelessWidget {
  const ConfirmarBaja({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return MarcoDeDialogo(
      hijos: [
        CirculoDeIcono(
          icono: Icons.warning_amber_rounded,
          fondo: p.stateDangerMuted,
          tinta: p.stateDangerInk,
        ),
        const SizedBox(height: Medidas.s12),
        Text(
          '¿Eliminar tu cuenta?',
          textAlign: TextAlign.center,
          style: Textos.h2.copyWith(color: p.textPrimary),
        ),
        const SizedBox(height: Medidas.s12),
        Text(
          'Esta acción es permanente. Se eliminarán tus datos y tus reservas '
          'vigentes.',
          textAlign: TextAlign.center,
          style: Textos.cuerpo.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: Medidas.s12),
        BotonPeligro(
          texto: 'ELIMINAR CUENTA',
          alTocar: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: Medidas.s8),
        BotonContorno(
          texto: 'CANCELAR',
          alTocar: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
