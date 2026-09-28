import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/barra_inferior.dart';
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
      bottomNavigationBar: const BarraInferior(actual: Seccion.inicio),
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
                      ListenableBuilder(
                        listenable: sesion,
                        builder: (context, _) => Text(
                          sesion.perfil?.nombre ?? '',
                          style: Textos.h1.copyWith(color: p.textPrimary),
                        ),
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
            const SizedBox(height: Medidas.s32),
            Semantics(
              header: true,
              child: Text(
                'ACCESOS RÁPIDOS',
                style: Textos.sobretitulo.copyWith(color: p.textMuted),
              ),
            ),
            const SizedBox(height: Medidas.s12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Acceso(
                      icono: Icons.search_rounded,
                      titulo: 'Buscar cancha',
                      texto: 'Por sede, fecha y horario',
                      alTocar: () => context.go('/inicio/buscar'),
                    ),
                  ),
                  const SizedBox(width: Medidas.s12),
                  Expanded(
                    child: _Acceso(
                      icono: Icons.location_on_outlined,
                      titulo: 'Ver sedes',
                      texto: 'Horarios y canchas de cada una',
                      alTocar: () => context.go('/sedes'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una tarjeta de ACCESOS RÁPIDOS: ícono, título y para qué sirve.
class _Acceso extends StatelessWidget {
  const _Acceso({
    required this.icono,
    required this.titulo,
    required this.texto,
    required this.alTocar,
  });

  final IconData icono;
  final String titulo;
  final String texto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Medidas.radioLg),
      side: BorderSide(color: p.borderDefault),
    );
    return Semantics(
      button: true,
      child: Material(
        color: p.bgSurfaceRaised,
        shape: forma,
        child: InkWell(
          onTap: alTocar,
          customBorder: forma,
          child: Padding(
            padding: const EdgeInsets.all(Medidas.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, color: p.accentInk),
                const SizedBox(height: Medidas.s16),
                Text(
                  titulo,
                  style: Textos.cuerpoFuerte.copyWith(color: p.textPrimary),
                ),
                const SizedBox(height: Medidas.s4),
                Text(
                  texto,
                  style: Textos.leyenda.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
