import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// El componente `Input` del prototipo: etiqueta arriba, campo pill y error abajo.
class CampoTexto extends StatelessWidget {
  const CampoTexto({
    super.key,
    required this.etiqueta,
    required this.etiquetaAccesible,
    required this.controlador,
    this.foco,
    this.placeholder,
    this.error,
    this.teclado,
    this.formateadores,
    this.oculto = false,
    this.accionFinal,
    this.alEnviar,
    this.accion,
    this.autocompletar,
  });

  final String etiqueta;
  final String etiquetaAccesible;
  final TextEditingController controlador;
  final FocusNode? foco;
  final String? placeholder;
  final String? error;
  final TextInputType? teclado;
  final List<TextInputFormatter>? formateadores;
  final bool oculto;
  final Widget? accionFinal;
  final ValueChanged<String>? alEnviar;
  final TextInputAction? accion;
  final Iterable<String>? autocompletar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final mensaje = error;
    final ayuda = placeholder;
    final conError = mensaje != null;
    OutlineInputBorder borde(Color color, double ancho) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(Medidas.radioPill),
      borderSide: BorderSide(color: color, width: ancho),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(
            etiqueta,
            style: Textos.sobretitulo.copyWith(color: p.textSecondary),
          ),
        ),
        const SizedBox(height: Medidas.s8),
        Semantics(
          container: true,
          label: etiquetaAccesible,
          child: SizedBox(
            height: Medidas.altoControl,
            child: TextField(
              controller: controlador,
              focusNode: foco,
              obscureText: oculto,
              keyboardType: teclado,
              inputFormatters: formateadores,
              textInputAction: accion,
              onSubmitted: alEnviar,
              autofillHints: autocompletar,
              style: Textos.cuerpo.copyWith(color: p.textPrimary),
              decoration: InputDecoration(
                // El placeholder no forma parte de la etiqueta accesible del campo.
                hint: ayuda == null
                    ? null
                    : ExcludeSemantics(
                        child: Text(
                          ayuda,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Textos.cuerpo.copyWith(color: p.textMuted),
                        ),
                      ),
                filled: true,
                fillColor: p.bgSurface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Medidas.s20,
                ),
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
                border: borde(p.borderControl, 1),
              ),
            ),
          ),
        ),
        if (mensaje != null) ...[
          const SizedBox(height: Medidas.s8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: p.stateDangerInk,
                ),
              ),
              const SizedBox(width: Medidas.s8),
              Expanded(
                child: Text(
                  mensaje,
                  style: Textos.leyenda.copyWith(color: p.stateDangerInk),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
