import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/boton.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'sesion.dart';
import 'tarjeta_cuenta.dart';

/// Quien pide una sección de administrador sin serlo (CU-14 FA4), por un enlace al panel o
/// por un 403 de la API. Toda ruta bajo `/admin` sin el rol llega acá.
///
/// Un 403 puede venir de un rol que cambió después de iniciar la sesión: la pantalla vuelve a
/// leer el perfil y recién entonces lleva a Mis reservas, para que el rol guardado no la
/// devuelva al panel. «Cerrar sesión» es la salida de quien no tiene adónde ir.
class PantallaAccesoDenegado extends StatefulWidget {
  const PantallaAccesoDenegado({super.key, required this.sesion});

  final Sesion sesion;

  @override
  State<PantallaAccesoDenegado> createState() => _PantallaAccesoDenegadoState();
}

class _PantallaAccesoDenegadoState extends State<PantallaAccesoDenegado> {
  late final Future<void> _perfil;

  @override
  void initState() {
    super.initState();
    // Fuera de la construcción: releer el perfil avisa a quien escucha la sesión.
    _perfil = Future.microtask(_releer);
  }

  Future<void> _releer() async {
    try {
      await widget.sesion.refrescar();
    } on Exception {
      // Sin red o con la sesión vencida se sigue con el perfil que había; lo que falle
      // después lo atiende la pantalla a la que se llegue.
    }
  }

  Future<void> _irAMisReservas() async {
    await _perfil;
    if (mounted) context.go('/reservas');
  }

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
                'Tu cuenta no tiene permisos de administrador. Te llevamos a Mis reservas.',
                textAlign: TextAlign.center,
                style: Textos.cuerpo.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: Medidas.s24),
              BotonPrimario(
                texto: 'IR A MIS RESERVAS',
                alTocar: _irAMisReservas,
              ),
              const SizedBox(height: Medidas.s8),
              BotonTexto(
                texto: 'Cerrar sesión',
                alTocar: () => cerrarSesion(context, widget.sesion),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
