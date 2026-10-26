import 'package:flutter/material.dart';
import '../comun/boton.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// `Card-Error` del prototipo: la consulta falló y los filtros siguen cargados.
class TarjetaErrorDeBusqueda extends StatelessWidget {
  const TarjetaErrorDeBusqueda({
    super.key,
    required this.sinConexion,
    required this.alVolver,
    required this.alReintentar,
  });

  final bool sinConexion;
  final VoidCallback alVolver;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(Medidas.s16),
        decoration: BoxDecoration(
          color: p.stateDangerMuted,
          borderRadius: BorderRadius.circular(Medidas.radioLg),
          border: Border.all(color: p.stateDanger),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'NO SE PUDO CONSULTAR',
              style: Textos.sobretitulo.copyWith(color: p.stateDangerInk),
            ),
            const SizedBox(height: Medidas.s4),
            Text(
              'No se pudo consultar la disponibilidad',
              style: Textos.titulo.copyWith(color: p.textPrimary),
            ),
            const SizedBox(height: Medidas.s4),
            Text(
              '${sinConexion ? 'Revisá tu conexión e intentá nuevamente.' : 'El servidor no respondió. Intentá más tarde.'}'
              ' Los filtros que cargaste se mantienen.',
              style: Textos.cuerpo.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: Medidas.s12),
            Row(
              children: [
                BotonTexto(texto: 'VOLVER', alTocar: alVolver),
                const SizedBox(width: Medidas.s8),
                Expanded(
                  child: BotonContorno(
                    texto: 'REINTENTAR',
                    alTocar: alReintentar,
                    peligro: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
