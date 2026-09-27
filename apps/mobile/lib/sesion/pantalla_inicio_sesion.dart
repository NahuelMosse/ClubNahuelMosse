import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/boton.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Inicio de sesión. El ingreso con correo y contraseña lo agrega CU-01.
class PantallaInicioSesion extends StatelessWidget {
  const PantallaInicioSesion({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Medidas.s24,
            80,
            Medidas.s24,
            Medidas.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'BIENVENIDO A',
                style: Textos.sobretitulo.copyWith(color: p.accentInk),
              ),
              const SizedBox(height: Medidas.s8),
              Semantics(
                header: true,
                label: 'Club Nahuel Mosse',
                child: ExcludeSemantics(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'CLUB ',
                          style: TextStyle(color: p.textPrimary),
                        ),
                        TextSpan(
                          text: 'NAHUELMOSSE',
                          style: TextStyle(color: p.accentInk),
                        ),
                      ],
                    ),
                    style: Textos.display,
                  ),
                ),
              ),
              const SizedBox(height: Medidas.s8),
              Text(
                'Gestión de espacios deportivos',
                style: Textos.cuerpo.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: Medidas.s48),
              const BotonPrimario(texto: 'INICIAR SESIÓN', alTocar: null),
              const SizedBox(height: Medidas.s24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿No tenés cuenta?',
                    style: Textos.leyenda.copyWith(color: p.textSecondary),
                  ),
                  BotonTexto(
                    texto: 'COMENZAR',
                    icono: Icons.arrow_forward_rounded,
                    alTocar: () => context.go('/registro'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
