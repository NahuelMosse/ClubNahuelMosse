import 'package:flutter/material.dart';
import '../sesion/sesion.dart';
import '../comun/reglas_registro.dart';
import 'fila_de_dato_de_perfil.dart';

/// Los datos personales en modo lectura. El correo no se puede cambiar (RF 2) y se ve y se
/// anuncia así.
class DatosDePerfil extends StatelessWidget {
  const DatosDePerfil({super.key, required this.perfil});

  final Perfil perfil;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilaDeDatoDePerfil(etiqueta: 'Nombre', valor: perfil.nombre),
        FilaDeDatoDePerfil(etiqueta: 'Apellido', valor: perfil.apellido),
        FilaDeDatoDePerfil(etiqueta: 'DNI', valor: dniLegible(perfil.dni)),
        FilaDeDatoDePerfil(
          etiqueta: 'Nacimiento',
          valor: fechaLegible(perfil.fechaNacimiento),
        ),
        FilaDeDatoDePerfil(
          etiqueta: 'Correo',
          valor: perfil.correo,
          fija: true,
        ),
      ],
    );
  }
}
