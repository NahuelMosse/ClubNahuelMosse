// kit-shape: a screen or error family kept with its private parts.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/button.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import 'account_card.dart';
import 'session.dart';

/// Quien pide una sección de administrador sin serlo (CU-14 FA4), por un enlace al panel o
/// por un 403 de la API. Toda ruta bajo `/admin` sin el rol llega acá.
///
/// Un 403 puede venir de un rol que cambió después de iniciar la sesión: la pantalla vuelve a
/// leer el perfil y recién entonces lleva a Mis reservas, para que el rol guardado no la
/// devuelva al panel. «Cerrar sesión» es la salida de quien no tiene adónde ir.
class AccessDeniedScreen extends StatefulWidget {
  const AccessDeniedScreen({super.key, required this.session});

  final Session session;

  @override
  State<AccessDeniedScreen> createState() => _AccessDeniedScreenState();
}

class _AccessDeniedScreenState extends State<AccessDeniedScreen> {
  late final Future<void> _profile;

  @override
  void initState() {
    super.initState();
    // Fuera de la construcción: releer el perfil avisa a quien escucha la sesión.
    _profile = Future.microtask(_reread);
  }

  Future<void> _reread() async {
    try {
      await widget.session.refresh();
    } on Exception {
      // Sin red o con la sesión vencida se sigue con el perfil que había; lo que falle
      // después lo atiende la pantalla a la que se llegue.
    }
  }

  Future<void> _goToMyBookings() async {
    await _profile;
    if (mounted) context.go('/reservas');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.s24),
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
              const SizedBox(height: Spacing.s16),
              Semantics(
                header: true,
                child: Text(
                  'Acceso denegado',
                  textAlign: TextAlign.center,
                  style: Texts.h2.copyWith(color: p.textPrimary),
                ),
              ),
              const SizedBox(height: Spacing.s8),
              Text(
                'Tu cuenta no tiene permisos de administrador. Te llevamos a Mis reservas.',
                textAlign: TextAlign.center,
                style: Texts.body.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: Spacing.s24),
              PrimaryButton(label: 'IR A MIS RESERVAS', onTap: _goToMyBookings),
              const SizedBox(height: Spacing.s8),
              TextActionButton(
                label: 'Cerrar sesión',
                onTap: () => signOut(context, widget.session),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
