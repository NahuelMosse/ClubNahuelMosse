import 'package:flutter/material.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Una tarjeta de ACCESOS RÁPIDOS: ícono, título y para qué sirve.
class AccesoDeInicio extends StatelessWidget {
  const AccesoDeInicio({
    super.key,
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
