import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

enum Seccion {
  inicio('INICIO', Icons.home_outlined, '/inicio'),
  sedes('SEDES', Icons.place_outlined, '/sedes'),
  reservas('RESERVAS', Icons.calendar_today_outlined, '/reservas'),
  perfil('PERFIL', Icons.person_outline_rounded, '/perfil');

  const Seccion(this.titulo, this.icono, this.ruta);
  final String titulo;
  final IconData icono;
  final String ruta;
}

/// `BottomNav` del usuario: cuatro pestañas fijas, la de la sección actual en lima.
class BarraInferior extends StatelessWidget {
  const BarraInferior({super.key, required this.actual});

  final Seccion actual;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        border: Border(top: BorderSide(color: p.borderDefault)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: Medidas.s8, bottom: Medidas.s8),
          child: Row(
            children: [
              for (final seccion in Seccion.values)
                Expanded(
                  child: _Pestana(
                    seccion: seccion,
                    activa: seccion == actual,
                    alTocar: () => context.go(seccion.ruta),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pestana extends StatelessWidget {
  const _Pestana({
    required this.seccion,
    required this.activa,
    required this.alTocar,
  });

  final Seccion seccion;
  final bool activa;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final color = activa ? p.accentInk : p.textMuted;
    return Semantics(
      button: true,
      selected: activa,
      child: InkResponse(
        onTap: activa ? null : alTocar,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Medidas.altoControl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(seccion.icono, size: 24, color: color),
              const SizedBox(height: Medidas.s4),
              Text(
                seccion.titulo,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: Textos.sobretitulo.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
