import 'package:flutter/material.dart';
import '../comun/boton.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

const tituloDesactivadas = 'Notificaciones desactivadas';
const textoDesactivadas =
    'Activá los avisos para que te recordemos tus reservas una hora antes.';

/// La franja de arriba cuando hay avisos pero el sistema no deja mostrarlos.
class NotificacionesDesactivadas extends StatelessWidget {
  const NotificacionesDesactivadas({super.key, required this.alActivar});

  final Future<bool> Function() alActivar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Container(
      padding: const EdgeInsets.all(Medidas.s16),
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        borderRadius: BorderRadius.circular(Medidas.radioLg),
        border: Border.all(color: p.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tituloDesactivadas,
            style: Textos.titulo.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: Medidas.s4),
          Text(
            textoDesactivadas,
            style: Textos.leyenda.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: Medidas.s16),
          BotonPrimario(texto: 'ACTIVAR NOTIFICACIONES', alTocar: alActivar),
        ],
      ),
    );
  }
}
