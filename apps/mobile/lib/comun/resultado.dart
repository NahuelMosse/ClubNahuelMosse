import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'boton.dart';

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
  });

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
    final textoSecundario = secundaria;
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
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: fondo,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icono, size: 40, color: tinta),
                  ),
                ),
                const SizedBox(height: Medidas.s24),
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: Textos.h1.copyWith(color: p.textPrimary),
                  ),
                ),
                const SizedBox(height: Medidas.s12),
                Text(
                  texto,
                  textAlign: TextAlign.center,
                  style: Textos.cuerpo.copyWith(color: p.textSecondary),
                ),
                const SizedBox(height: Medidas.s32),
                BotonPrimario(texto: principal, alTocar: alTocarPrincipal),
                if (textoSecundario != null) ...[
                  const SizedBox(height: Medidas.s8),
                  Center(
                    child: cargandoSecundaria
                        ? const SizedBox(
                            height: Medidas.altoControl,
                            child: Center(
                              child: SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                          )
                        : BotonTexto(
                            texto: textoSecundario,
                            alTocar: alTocarSecundaria,
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
