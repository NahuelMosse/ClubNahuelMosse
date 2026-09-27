import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/barra_superior.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Recuperar contraseña: se llega desde «¿Olvidaste tu contraseña?» del login.
class PantallaRecuperarContrasena extends StatelessWidget {
  const PantallaRecuperarContrasena({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Scaffold(
      appBar: BarraSuperior(
        titulo: 'Recuperar contraseña',
        alVolver: () => context.go('/'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Medidas.s24,
            Medidas.s8,
            Medidas.s24,
            Medidas.s40,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: Textos.h1.copyWith(color: p.textPrimary),
              ),
            ),
            const SizedBox(height: Medidas.s8),
            Text(
              'Ingresá el correo con el que te registraste y te enviamos un '
              'enlace para crear una nueva.',
              style: Textos.cuerpo.copyWith(color: p.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
