import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'boton.dart';

/// Quien entra al panel de administración por un enlace, sin rol de Administrador (CU-14
/// FA4). Sólo la entrada bare `/admin` llega acá: las subrutas de sedes y espacios conservan
/// su redirección silenciosa de siempre.
class PantallaAccesoDenegado extends StatelessWidget {
  const PantallaAccesoDenegado({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Scaffold(
      backgroundColor: p.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Medidas.s24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: p.stateDangerMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.block_rounded,
                  size: 28,
                  color: p.stateDangerInk,
                ),
              ),
              const SizedBox(height: Medidas.s16),
              Semantics(
                header: true,
                child: Text(
                  'Acceso denegado',
                  textAlign: TextAlign.center,
                  style: Textos.h2.copyWith(color: p.textPrimary),
                ),
              ),
              const SizedBox(height: Medidas.s8),
              Text(
                'Esta sección es sólo para administradores del club.',
                textAlign: TextAlign.center,
                style: Textos.cuerpo.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: Medidas.s24),
              BotonPrimario(
                texto: 'IR A MIS RESERVAS',
                alTocar: () => context.go('/reservas'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
