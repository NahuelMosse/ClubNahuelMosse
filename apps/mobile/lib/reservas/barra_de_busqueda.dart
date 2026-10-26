import 'package:flutter/material.dart';
import '../comun/boton.dart';
import '../tema/tokens.dart';

class BarraDeBusqueda extends StatelessWidget {
  const BarraDeBusqueda({
    super.key,
    required this.alLimpiar,
    required this.alConsultar,
    required this.consultando,
  });

  final VoidCallback? alLimpiar;
  final VoidCallback? alConsultar;
  final bool consultando;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.bgSurface,
        border: Border(top: BorderSide(color: p.borderDefault)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Medidas.s24,
            Medidas.s16,
            Medidas.s24,
            Medidas.s16,
          ),
          child: Row(
            children: [
              BotonTexto(texto: 'LIMPIAR', alTocar: alLimpiar),
              const SizedBox(width: Medidas.s12),
              Expanded(
                child: BotonPrimario(
                  texto: 'CONSULTAR',
                  alTocar: alConsultar,
                  cargando: consultando,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
