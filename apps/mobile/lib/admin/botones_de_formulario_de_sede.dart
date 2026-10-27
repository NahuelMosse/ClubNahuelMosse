import 'package:flutter/material.dart';

import '../comun/boton.dart';
import '../comun/en_curso.dart';
import '../tema/tokens.dart';
import 'formulario_de_sede.dart';

/// Los botones del pie del formulario de una sede: guardar y, al editar, dar de baja.
class BotonesDeFormularioDeSede extends StatelessWidget {
  const BotonesDeFormularioDeSede({
    super.key,
    required this.formulario,
    required this.alGuardar,
    required this.alDarDeBaja,
  });

  final FormularioDeSede formulario;
  final VoidCallback alGuardar;
  final VoidCallback alDarDeBaja;

  @override
  Widget build(BuildContext context) {
    final f = formulario;
    if (!f.esEdicion) {
      return BotonPrimario(
        texto: 'GUARDAR SEDE',
        cargando: f.enviando,
        atenuado: !f.completo,
        alTocar: alGuardar,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BotonPrimario(
          texto: 'GUARDAR CAMBIOS',
          cargando: f.enviando,
          atenuado: !f.completo,
          alTocar: f.dandoDeBaja ? null : alGuardar,
        ),
        const SizedBox(height: Medidas.s12),
        if (f.dandoDeBaja)
          const EnCurso('Dando de baja la sede')
        else
          BotonContorno(
            texto: 'DAR DE BAJA LA SEDE',
            peligro: true,
            alTocar: f.enviando ? null : alDarDeBaja,
          ),
      ],
    );
  }
}
