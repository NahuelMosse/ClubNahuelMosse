import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'boton.dart';

/// El arranque no pudo saber si la sesión guardada vale (sin red o con la API sin responder).
/// No es el login: la cuenta sigue abierta y se reintenta.
class PantallaErrorDeArranque extends StatelessWidget {
  const PantallaErrorDeArranque({
    super.key,
    required this.sinRed,
    required this.alReintentar,
  });

  final bool sinRed;
  final VoidCallback alReintentar;

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                sinRed ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
                size: 48,
                color: p.stateDangerInk,
              ),
              const SizedBox(height: Medidas.s12),
              Text(
                sinRed
                    ? 'Revisá tu conexión a internet y volvé a intentar.'
                    : 'El servidor no responde. Probá de nuevo en unos minutos.',
                textAlign: TextAlign.center,
                style: Textos.cuerpo.copyWith(color: p.textPrimary),
              ),
              const SizedBox(height: Medidas.s24),
              BotonPrimario(texto: 'REINTENTAR', alTocar: alReintentar),
            ],
          ),
        ),
      ),
    );
  }
}
