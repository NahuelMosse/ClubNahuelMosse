import 'package:flutter/material.dart';

import '../comun/boton.dart';
import '../tema/tokens.dart';
import 'accion_de_reserva.dart';

/// MODIFICAR y CANCELAR de una reserva, lado a lado o uno sobre otro si la letra es grande.
class AccionesDeReserva extends StatelessWidget {
  const AccionesDeReserva({
    super.key,
    required this.deQue,
    required this.grande,
    required this.alModificar,
    required this.alCancelar,
  });

  /// La descripción de la reserva para las etiquetas accesibles.
  final String deQue;
  final bool grande;
  final VoidCallback? alModificar;
  final VoidCallback? alCancelar;

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: grande ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: grande
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.center,
      children: [
        AccionDeReserva(
          expandir: !grande,
          etiqueta: 'Modificar la reserva de $deQue',
          alTocar: alModificar,
          child: BotonContorno(
            texto: 'MODIFICAR',
            alTocar: alModificar,
            compacto: true,
          ),
        ),
        const SizedBox(width: Medidas.s8, height: Medidas.s8),
        AccionDeReserva(
          expandir: !grande,
          etiqueta: 'Cancelar la reserva de $deQue',
          alTocar: alCancelar,
          child: BotonContorno(
            texto: 'CANCELAR',
            alTocar: alCancelar,
            peligro: true,
            compacto: true,
          ),
        ),
      ],
    );
  }
}
