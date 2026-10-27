import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// El campo multilínea del motivo de una anulación; con [sinMotivo] se marca en error.
class CampoDeMotivo extends StatelessWidget {
  const CampoDeMotivo({
    super.key,
    required this.controller,
    required this.largoMaximo,
    required this.sinMotivo,
    required this.alCambiar,
  });

  final TextEditingController controller;
  final int largoMaximo;
  final bool sinMotivo;
  final ValueChanged<String> alCambiar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    OutlineInputBorder borde(Color color, double ancho) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(Medidas.radioMd),
      borderSide: BorderSide(color: color, width: ancho),
    );
    return Semantics(
      container: true,
      label: 'Motivo de la anulación',
      child: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 5,
        maxLength: largoMaximo,
        buildCounter:
            (
              context, {
              required currentLength,
              required isFocused,
              required maxLength,
            }) => null,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        onChanged: alCambiar,
        style: Textos.cuerpo.copyWith(color: p.textPrimary),
        decoration: InputDecoration(
          filled: true,
          fillColor: p.bgSurface,
          contentPadding: const EdgeInsets.all(Medidas.s16),
          enabledBorder: sinMotivo
              ? borde(p.borderError, 1.5)
              : borde(p.borderControl, 1),
          focusedBorder: sinMotivo
              ? borde(p.borderError, 1.5)
              : borde(p.borderFocus, 1.5),
          border: borde(p.borderControl, 1),
        ),
      ),
    );
  }
}
