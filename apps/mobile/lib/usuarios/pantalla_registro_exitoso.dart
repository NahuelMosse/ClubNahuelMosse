import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/boton.dart';
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
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: p.stateSuccessMuted,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    size: 44,
                    color: p.stateSuccessInk,
                  ),
                ),
                const SizedBox(height: Medidas.s20),
                Text(
                  '¡Cuenta creada!',
                  textAlign: TextAlign.center,
                  style: Textos.h1.copyWith(color: p.textPrimary),
                ),
                const SizedBox(height: Medidas.s20),
                Text(
                  'Tu cuenta se registró con éxito. Ya podés iniciar sesión con tu correo y contraseña.',
                  textAlign: TextAlign.center,
                  style: Textos.cuerpo.copyWith(color: p.textSecondary),
                ),
                const SizedBox(height: Medidas.s20 + Medidas.s16),
                BotonPrimario(
                  texto: 'VOLVER AL INICIO DE SESIÓN',
                  alTocar: () => context.go('/'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
