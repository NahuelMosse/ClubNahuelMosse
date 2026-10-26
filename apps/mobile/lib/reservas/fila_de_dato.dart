import 'package:flutter/material.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Un dato de la reserva: el nombre a la izquierda y el valor a la derecha.
class FilaDeDato extends StatelessWidget {
  const FilaDeDato({
    super.key,
    required this.dato,
    required this.valor,
    this.destacado = false,
    this.codigo = false,
  });

  final String dato;
  final String valor;
  final bool destacado;

  /// Un código largo sin espacios (el nombre compuesto del espacio): va debajo del dato,
  /// en la fuente mono, para no partirse a mitad de palabra.
  final bool codigo;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    if (codigo) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Medidas.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dato, style: Textos.cuerpo.copyWith(color: p.textSecondary)),
            const SizedBox(height: Medidas.s4),
            Text(valor, style: Textos.mono.copyWith(color: p.textPrimary)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Medidas.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dato, style: Textos.cuerpo.copyWith(color: p.textSecondary)),
          const SizedBox(width: Medidas.s16),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: (destacado ? Textos.cuerpoFuerte : Textos.cuerpo).copyWith(
                color: destacado ? p.accentInk : p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
