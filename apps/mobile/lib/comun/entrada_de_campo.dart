import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// El `TextField` pill de un [CampoTexto]: relleno, placeholder y borde según el error.
class EntradaDeCampo extends StatelessWidget {
  const EntradaDeCampo({
    super.key,
    required this.controlador,
    required this.habilitado,
    required this.oculto,
    required this.conError,
    this.foco,
    this.ayuda,
    this.teclado,
    this.formateadores,
    this.accionFinal,
    this.alEnviar,
    this.accion,
    this.autocompletar,
  });

  final TextEditingController controlador;
  final bool habilitado;
  final bool oculto;
  final bool conError;
  final FocusNode? foco;
  final String? ayuda;
  final TextInputType? teclado;
  final List<TextInputFormatter>? formateadores;
  final Widget? accionFinal;
  final ValueChanged<String>? alEnviar;
  final TextInputAction? accion;
  final Iterable<String>? autocompletar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final texto = ayuda;
    OutlineInputBorder borde(Color color, double ancho) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(Medidas.radioPill),
      borderSide: BorderSide(color: color, width: ancho),
    );

    return TextField(
      controller: controlador,
      enabled: habilitado,
      focusNode: foco,
      obscureText: oculto,
      keyboardType: teclado,
      inputFormatters: formateadores,
      textInputAction: accion,
      onSubmitted: alEnviar,
      autofillHints: autocompletar,
      style: Textos.cuerpo.copyWith(color: p.textPrimary),
      decoration: InputDecoration(
        // El placeholder se anuncia como ayuda del campo, no como su etiqueta.
        hint: texto == null
            ? null
            : ExcludeSemantics(
                child: Text(
                  texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Textos.cuerpo.copyWith(color: p.textMuted),
                ),
              ),
        filled: true,
        fillColor: p.bgSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: Medidas.s20),
        suffixIcon: accionFinal == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: Medidas.s8),
                child: accionFinal,
              ),
        enabledBorder: conError
            ? borde(p.borderError, 1.5)
            : borde(p.borderControl, 1),
        focusedBorder: conError
            ? borde(p.borderError, 1.5)
            : borde(p.borderFocus, 1.5),
        disabledBorder: borde(p.borderControl, 1),
        border: borde(p.borderControl, 1),
      ),
    );
  }
}
