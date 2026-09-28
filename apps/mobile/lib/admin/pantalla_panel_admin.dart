import 'package:flutter/material.dart';

import '../comun/barra_inferior.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// El panel de administración, adonde entra quien inicia sesión como administrador.
class PantallaPanelAdmin extends StatelessWidget {
  const PantallaPanelAdmin({super.key, required this.sesion});

  final Sesion sesion;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: const BarraAdmin(actual: SeccionAdmin.reservas),
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
                        'PANEL ADMIN',
                        style: Textos.sobretitulo.copyWith(color: p.accentInk),
                      ),
                      const SizedBox(height: Medidas.s4),
                      Semantics(
                        header: true,
                        child: Text(
                          'Reservas',
                          style: Textos.h1.copyWith(color: p.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                BotonCuenta(sesion: sesion),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
