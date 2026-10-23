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

/// Las tres pestañas del panel de administración (`BottomNav-Admin`).
enum SeccionAdmin {
  reservas('RESERVAS', Icons.calendar_today_outlined, '/admin'),
  sedes('SEDES', Icons.place_outlined, '/admin/sedes'),
  espacios('ESPACIOS', Icons.grid_view_outlined, '/admin/espacios');

  const SeccionAdmin(this.titulo, this.icono, this.ruta);
  final String titulo;
  final IconData icono;
  final String ruta;
}

/// `BottomNav` del usuario: cuatro pestañas fijas, la de la sección actual en lima.
class BarraInferior extends StatelessWidget {
  const BarraInferior({super.key, required this.actual, this.enRaiz = true});

  final Seccion actual;

  /// `false` adentro de la sección (una sede, sus horarios): la pestaña activa vuelve al
  /// principio de la sección.
  final bool enRaiz;

  @override
  Widget build(BuildContext context) => _Barra(
    pestanas: [
      for (final s in Seccion.values)
        _Pestana(
          titulo: s.titulo,
          icono: s.icono,
          activa: s == actual,
          tocable: s != actual || !enRaiz,
          alTocar: () => context.go(s.ruta),
        ),
    ],
  );
}

/// `BottomNav-Admin`: Reservas, Sedes y Espacios.
class BarraAdmin extends StatelessWidget {
  const BarraAdmin({super.key, required this.actual});

  final SeccionAdmin actual;

  @override
  Widget build(BuildContext context) => _Barra(
    pestanas: [
      for (final s in SeccionAdmin.values)
        _Pestana(
          titulo: s.titulo,
          icono: s.icono,
          activa: s == actual,
          tocable: s != actual,
          alTocar: () => context.go(s.ruta),
        ),
    ],
  );
}

class _Barra extends StatelessWidget {
  const _Barra({required this.pestanas});

  final List<_Pestana> pestanas;

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
          padding: const EdgeInsets.symmetric(
            horizontal: Medidas.s8,
            vertical: Medidas.s8,
          ),
          child: Row(
            children: [
              for (final pestana in pestanas) Expanded(child: pestana),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pestana extends StatelessWidget {
  const _Pestana({
    required this.titulo,
    required this.icono,
    required this.activa,
    required this.tocable,
    required this.alTocar,
  });

  final String titulo;
  final IconData icono;
  final bool activa;
  final bool tocable;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final color = activa ? p.accentInk : p.textMuted;
    return Semantics(
      button: true,
      selected: activa,
      child: InkResponse(
        onTap: tocable ? alTocar : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Medidas.altoControl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 24, color: color),
              const SizedBox(height: Medidas.s4),
              // Con el texto grande la etiqueta se achica hasta entrar entera.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Medidas.s4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    titulo,
                    maxLines: 1,
                    style: Textos.sobretitulo.copyWith(color: color),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
