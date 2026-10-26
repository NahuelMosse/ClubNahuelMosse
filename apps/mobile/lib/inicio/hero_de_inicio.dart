import 'package:flutter/material.dart';
import '../comun/marcador.dart';
import '../comun/movimiento.dart';
import '../notificaciones/campana.dart';
import '../notificaciones/centro.dart';
import '../sedes/fotos.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// La portada: el saludo, la cuenta y el pedido del día. Va sobre una foto, así que sus
/// colores son los `on-media`, iguales en los dos modos.
class HeroDeInicio extends StatelessWidget {
  const HeroDeInicio({
    super.key,
    required this.sesion,
    required this.celdas,
    required this.yaEntro,
    this.centro,
  });

  final Sesion sesion;
  final bool yaEntro;

  final CentroDeNotificaciones? centro;

  /// `null` mientras se lee.
  final List<CeldaMarcador>? celdas;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final arriba = MediaQuery.paddingOf(context).top;
    final marcador = celdas;
    return FotoConVelo(
      imagen: fotoDeDeporte('Futbol'),
      child: Stack(
        children: [
          const Positioned.fill(
            child: ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.5],
                    colors: [Color(0x99000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              Medidas.s24,
              arriba + Medidas.s24,
              Medidas.s16,
              Medidas.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Aparecer(
                        retraso: const Duration(milliseconds: 50),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BUENOS DÍAS,',
                              style: Textos.sobretitulo.copyWith(
                                color: p.accentOnMedia,
                              ),
                            ),
                            const SizedBox(height: Medidas.s4),
                            ListenableBuilder(
                              listenable: sesion,
                              builder: (context, _) => Text(
                                sesion.perfil?.nombre ?? '',
                                style: Textos.h1.copyWith(color: p.textOnMedia),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (centro case final centro?)
                      BotonNotificaciones(centro: centro),
                    BotonCuenta(sesion: sesion),
                  ],
                ),
                const SizedBox(height: Medidas.s48),
                Semantics(
                  header: true,
                  child: Text(
                    'RESERVÁ TU CANCHA',
                    style: Textos.display.copyWith(color: p.textOnMedia),
                  ),
                ),
                if (marcador != null) ...[
                  const SizedBox(height: Medidas.s24),
                  Padding(
                    padding: const EdgeInsets.only(right: Medidas.s8),
                    child: Aparecer(
                      retraso: const Duration(milliseconds: 250),
                      duracion: const Duration(milliseconds: 500),
                      desdeY: 0,
                      escalaDesde: 0.85,
                      curva: Movimiento.rapida,
                      yaEntro: yaEntro,
                      child: Marcador(celdas: marcador),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
