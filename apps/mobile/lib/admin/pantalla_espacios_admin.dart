import 'package:flutter/material.dart';

import '../comun/barra_inferior.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Los espacios deportivos del panel de administración.
class PantallaEspaciosAdmin extends StatelessWidget {
  const PantallaEspaciosAdmin({super.key, required this.sesion});

  final Sesion sesion;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: const BarraAdmin(actual: SeccionAdmin.espacios),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Medidas.s24,
            Medidas.s24,
            Medidas.s24,
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
                          'Espacios',
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
