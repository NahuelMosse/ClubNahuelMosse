import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'dorsal.dart';
import 'isotipo.dart';
import 'marcador.dart';

/// Carnet del socio: iniciales, nombre, correo y un [Marcador] de estadísticas, con un dorsal de fondo.
class FichaSocio extends StatelessWidget {
  const FichaSocio({
    super.key,
    required this.iniciales,
    required this.nombre,
    required this.correo,
    required this.estadisticas,
    this.imagen,
    this.numero,
  });

  final String iniciales;
  final String nombre;
  final String correo;
  final List<CeldaMarcador> estadisticas;
  final ImageProvider? imagen;
  final String? numero;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final foto = imagen;
    final nro = numero;
    final radio = BorderRadius.circular(24);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        borderRadius: radio,
        border: Border.all(color: p.accentBase, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: radio,
        child: Stack(
          children: [
            if (foto != null)
              Positioned.fill(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image(image: foto, fit: BoxFit.cover),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x66000000), Color(0xD9000000)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Positioned(
              top: -10,
              right: -6,
              child: DorsalGigante(
                texto: '10',
                tamano: 170,
                color: p.accentBase.withValues(alpha: 0.28),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FICHA DE SOCIO',
                            style: Textos.sobretitulo.copyWith(
                              color: p.accentOnMedia,
                            ),
                          ),
                          if (nro != null)
                            Text(
                              nro,
                              style: Textos.mono.copyWith(
                                color: p.textOnMediaMuted,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      const Isotipo(tamano: 32, decorativo: true),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: p.accentBase,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          iniciales,
                          style: Textos.display.copyWith(color: p.accentOn),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              style: Textos.h2.copyWith(
                                letterSpacing: 0,
                                color: p.textOnMedia,
                              ),
                            ),
                            Text(
                              correo,
                              style: Textos.leyenda.copyWith(
                                color: p.textOnMediaMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (estadisticas.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Marcador(celdas: estadisticas),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
