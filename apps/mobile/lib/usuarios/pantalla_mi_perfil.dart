import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
            const SizedBox(height: Medidas.s24),
            _Tarjeta(
              titulo: 'SEGURIDAD',
              child: _Fila(
                icono: Icons.lock_outline_rounded,
                texto: 'Cambiar contraseña',
                alTocar: () => context.push('/perfil/contrasena'),
              ),
            ),
            const SizedBox(height: Medidas.s24),
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

/// Un bloque del perfil: título en sobretítulo y su contenido sobre la superficie.
class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Container(
      padding: const EdgeInsets.all(Medidas.s16),
      decoration: BoxDecoration(
        color: p.bgSurface,
        border: Border.all(color: p.borderDefault),
        borderRadius: BorderRadius.circular(Medidas.radioLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: Textos.sobretitulo.copyWith(color: p.textMuted)),
          const SizedBox(height: Medidas.s8),
          child,
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.icono,
    required this.texto,
    required this.alTocar,
  });

  final IconData icono;
  final String texto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: alTocar,
        borderRadius: BorderRadius.circular(Medidas.radioMd),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Medidas.altoControl),
          child: Row(
            children: [
              Icon(icono, size: 20, color: p.textSecondary),
              const SizedBox(width: Medidas.s12),
              Expanded(
                child: Text(
                  texto,
                  style: Textos.cuerpoFuerte.copyWith(color: p.textPrimary),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: p.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
