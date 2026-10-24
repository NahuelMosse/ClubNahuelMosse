import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/boton.dart';
import '../comun/movimiento.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

class PantallaRegistroExitoso extends StatelessWidget {
  const PantallaRegistroExitoso({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: Medidas.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PulsoDeExito(
                  icono: Icons.check_circle_outline_rounded,
                  fondo: p.stateSuccessMuted,
                  tinta: p.stateSuccessInk,
                  diametro: 100,
                  tamanoIcono: 44,
                ),
                const SizedBox(height: Medidas.s20),
                Aparecer(
                  retraso: const Duration(milliseconds: 370),
                  desdeY: 14,
                  child: Text(
                    '¡Cuenta creada!',
                    textAlign: TextAlign.center,
                    style: Textos.h1.copyWith(color: p.textPrimary),
                  ),
                ),
                const SizedBox(height: Medidas.s20),
                Aparecer(
                  retraso: const Duration(milliseconds: 460),
                  desdeY: 14,
                  child: Text(
                    'Tu cuenta se registró con éxito. Ya podés iniciar sesión con tu correo y contraseña.',
                    textAlign: TextAlign.center,
                    style: Textos.cuerpo.copyWith(color: p.textSecondary),
                  ),
                ),
                const SizedBox(height: Medidas.s20 + Medidas.s16),
                Aparecer(
                  retraso: const Duration(milliseconds: 550),
                  desdeY: 14,
                  child: BotonPrimario(
                    texto: 'VOLVER AL INICIO DE SESIÓN',
                    alTocar: () => context.go('/'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
