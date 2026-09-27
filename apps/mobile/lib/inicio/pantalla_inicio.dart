import 'package:flutter/material.dart';

import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// El Home de quien inicia sesión como usuario.
class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key, required this.sesion});

  final Sesion sesion;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Scaffold(
      backgroundColor: p.bgBase,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Medidas.s24,
            Medidas.s24,
            Medidas.s16,
            Medidas.s40,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BUENOS DÍAS,',
                        style: Textos.sobretitulo.copyWith(color: p.accentInk),
                      ),
                      const SizedBox(height: Medidas.s4),
                      Text(
                        sesion.perfil?.nombre ?? '',
                        style: Textos.h1.copyWith(color: p.textPrimary),
                      ),
                    ],
                  ),
                ),
                BotonCuenta(sesion: sesion),
              ],
            ),
            const SizedBox(height: Medidas.s48),
            Semantics(
              header: true,
              child: Text(
                'RESERVÁ TU CANCHA',
                style: Textos.display.copyWith(color: p.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
