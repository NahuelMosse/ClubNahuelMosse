import 'package:flutter/material.dart';
import '../sedes/fotos.dart';
import '../sedes/portada_con_titulo.dart';
import '../sedes/sede.dart';
import '../tema/tokens.dart';

/// La foto del deporte con el camino de vuelta, el tipo y la sede.
class PortadaDeHorarios extends StatelessWidget {
  const PortadaDeHorarios({
    super.key,
    required this.sede,
    required this.tipo,
    required this.deporte,
    required this.volverA,
    required this.alVolver,
  });

  final Sede sede;
  final String tipo;
  final String deporte;

  /// El nombre de la pantalla a la que se vuelve.
  final String volverA;
  final VoidCallback alVolver;

  @override
  Widget build(BuildContext context) {
    return PortadaConTitulo(
      imagen: fotoDeDeporte(deporte),
      volverA: volverA,
      alVolver: alVolver,
      separacion: Medidas.s32,
      sobretitulo: tipo,
      nombre: sede.nombre,
    );
  }
}
