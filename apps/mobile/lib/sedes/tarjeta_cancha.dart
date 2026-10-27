import 'package:flutter/material.dart';

import '../comun/boton.dart';
import '../comun/formato_precio.dart';
import '../comun/marco_de_tarjeta.dart';
import '../espacios/espacio.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'etiquetas_y_precio.dart';
import 'foto_de_cancha.dart';

/// `Card-Cancha`: la foto de su deporte con el tipo y el nombre, sus datos, el precio y
/// «VER HORARIOS / RESERVAR».
class TarjetaCancha extends StatelessWidget {
  const TarjetaCancha({
    super.key,
    required this.cancha,
    required this.catalogo,
    required this.alReservar,
  });

  final Espacio cancha;
  final Catalogo catalogo;
  final VoidCallback alReservar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final tipo = catalogo.tipoCorto(cancha.deporte, cancha.tipo);
    final precio = pesos(cancha.precioPorHora);
    return MarcoDeTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            excludeSemantics: true,
            label:
                '$tipo, ${cancha.nombre}, ${cancha.condicion}, '
                '${cancha.iluminacion}, '
                '${precio.replaceFirst('\$ ', '')} pesos por hora',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FotoDeCancha(cancha: cancha, tipo: tipo),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Medidas.s16,
                    Medidas.s16,
                    Medidas.s16,
                    0,
                  ),
                  child: EtiquetasYPrecio(cancha: cancha, precio: precio),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Medidas.s16,
                    Medidas.s12,
                    Medidas.s16,
                    0,
                  ),
                  child: Text(
                    '${catalogo.tipoLegible(cancha.deporte, cancha.tipo)} · '
                    '${cancha.condicion} · '
                    '${cancha.iluminada ? 'con iluminación' : 'sin iluminación'}',
                    style: Textos.leyenda.copyWith(color: p.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Medidas.s16),
            // Sin esto, el lector de pantalla oye el mismo botón en cada cancha.
            child: Semantics(
              label: '$tipo, cancha ${cancha.numero}',
              child: BotonPrimario(
                texto: 'VER HORARIOS / RESERVAR',
                icono: Icons.bolt_rounded,
                alTocar: alReservar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
