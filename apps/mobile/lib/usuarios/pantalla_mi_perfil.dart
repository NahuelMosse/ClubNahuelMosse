import 'package:flutter/material.dart';

import '../comun/avatar.dart';
import '../comun/boton.dart';
import '../comun/insignia.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Mi perfil: quién es la persona y la salida de la cuenta.
class PantallaMiPerfil extends StatelessWidget {
  const PantallaMiPerfil({super.key, required this.sesion});

  final Sesion sesion;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final perfil = sesion.perfil;
    if (perfil == null) return const SizedBox.shrink();
    return Scaffold(
      backgroundColor: p.bgBase,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Medidas.s24,
            Medidas.s48,
            Medidas.s24,
            Medidas.s48,
          ),
          children: [
            Center(
              child: AvatarIniciales(
                nombre: perfil.nombre,
                apellido: perfil.apellido,
                tamano: TamanoAvatar.grande,
              ),
            ),
            const SizedBox(height: Medidas.s8),
            Semantics(
              header: true,
              child: Text(
                '${perfil.nombre} ${perfil.apellido}',
                textAlign: TextAlign.center,
                style: Textos.h1.copyWith(color: p.textPrimary),
              ),
            ),
            const SizedBox(height: Medidas.s8),
            Text(
              perfil.correo,
              textAlign: TextAlign.center,
              style: Textos.leyenda.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: Medidas.s8),
            const Center(child: Insignia(texto: 'MIEMBRO ACTIVO')),
            const SizedBox(height: Medidas.s48),
            BotonContorno(
              texto: 'CERRAR SESIÓN',
              alTocar: () => cerrarSesion(context, sesion),
            ),
          ],
        ),
      ),
    );
  }
}
