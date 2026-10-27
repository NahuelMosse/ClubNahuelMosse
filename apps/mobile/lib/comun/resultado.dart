import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'acciones_de_resultado.dart';
import 'detalle_de_resultado.dart';
import 'movimiento.dart';

enum TonoResultado { exito, aviso, peligro }

/// Pantalla de resultado a pantalla completa: ícono en círculo, título, texto y hasta dos
/// acciones. Es la de «Contraseña actualizada», «Revisá tu correo» y «El enlace no es válido».
class PantallaResultado extends StatelessWidget {
  const PantallaResultado({
    super.key,
    required this.icono,
    required this.tono,
    required this.titulo,
    required this.texto,
    required this.principal,
    required this.alTocarPrincipal,
    this.secundaria,
    this.alTocarSecundaria,
    this.cargandoSecundaria = false,
    this.detalle,
    this.diametro = 96,
    this.tamanoIcono = 40,
    this.separacionIcono = Medidas.s24,
    this.separacionTitulo = Medidas.s12,
    this.separacionAcciones = Medidas.s32,
  });

  /// El dato que se acaba de guardar, en un recuadro lima debajo del texto.
  final String? detalle;

  /// El tamaño del círculo y de su ícono, y lo que separa el círculo del título, el
  /// título del texto y el texto de las acciones.
  final double diametro;
  final double tamanoIcono;
  final double separacionIcono;
  final double separacionTitulo;
  final double separacionAcciones;

  final IconData icono;
  final TonoResultado tono;
  final String titulo;
  final String texto;
  final String principal;
  final VoidCallback alTocarPrincipal;
  final String? secundaria;
  final VoidCallback? alTocarSecundaria;
  final bool cargandoSecundaria;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final (fondo, tinta) = switch (tono) {
      TonoResultado.exito => (p.stateSuccessMuted, p.stateSuccessInk),
      TonoResultado.aviso => (p.bgSurfaceRaised, p.textSecondary),
      TonoResultado.peligro => (p.stateDangerMuted, p.stateDangerInk),
    };
    return Scaffold(
      backgroundColor: p.bgBase,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Medidas.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: PulsoDeExito(
                    icono: icono,
                    fondo: fondo,
                    tinta: tinta,
                    diametro: diametro,
                    tamanoIcono: tamanoIcono,
                  ),
                ),
                SizedBox(height: separacionIcono),
                Aparecer(
                  retraso: const Duration(milliseconds: 370),
                  desdeY: 14,
                  child: Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      titulo,
                      textAlign: TextAlign.center,
                      style: Textos.h1.copyWith(color: p.textPrimary),
                    ),
                  ),
                ),
                SizedBox(height: separacionTitulo),
                Aparecer(
                  retraso: const Duration(milliseconds: 460),
                  desdeY: 14,
                  child: DetalleDeResultado(texto: texto, detalle: detalle),
                ),
                SizedBox(height: separacionAcciones),
                Aparecer(
                  retraso: const Duration(milliseconds: 550),
                  desdeY: 14,
                  child: AccionesDeResultado(
                    principal: principal,
                    alTocarPrincipal: alTocarPrincipal,
                    secundaria: secundaria,
                    alTocarSecundaria: alTocarSecundaria,
                    cargandoSecundaria: cargandoSecundaria,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
