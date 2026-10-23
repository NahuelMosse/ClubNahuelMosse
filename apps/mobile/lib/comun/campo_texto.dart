import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// El componente `Input` del prototipo: etiqueta arriba si la hay, campo pill y error abajo.
class CampoTexto extends StatelessWidget {
  const CampoTexto({
    super.key,
    this.etiqueta,
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
    this.habilitado = true,
  });

  final String? etiqueta;
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
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final mensaje = error;
    final ayuda = placeholder;
    final titulo = etiqueta;
    final conError = mensaje != null;
    OutlineInputBorder borde(Color color, double ancho) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(Medidas.radioPill),
      borderSide: BorderSide(color: color, width: ancho),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (titulo != null) ...[
          ExcludeSemantics(
            child: Text(
              titulo,
              style: Textos.sobretitulo.copyWith(color: p.textSecondary),
            ),
          ),
          const SizedBox(height: Medidas.s8),
        ],
        Semantics(
          container: true,
          label: etiquetaAccesible,
          hint: ayudaAccesible(formato: ayuda, error: mensaje),
          // El error se anuncia apenas aparece.
          liveRegion: conError,
          child: SizedBox(
            height: Medidas.altoControl,
            child: TextField(
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
                disabledBorder: borde(p.borderControl, 1),
                border: borde(p.borderControl, 1),
              ),
            ),
          ),
        ),
        if (mensaje != null) ...[
          const SizedBox(height: Medidas.s8),
          AvisoDeCampo(mensaje),
        ],
      ],
    );
  }
}

/// Un error suelto, fuera de un campo: el lector de pantalla lo anuncia apenas aparece.
class MensajeDeCampo extends StatelessWidget {
  const MensajeDeCampo(this.mensaje, {super.key});

  final String mensaje;

  @override
  Widget build(BuildContext context) =>
      Semantics(liveRegion: true, child: _FilaDeError(mensaje));
}

/// El error que se ve debajo de un campo. El lector de pantalla no lo recorre aparte: lo
/// anuncia el campo, que lo trae en su propio nodo.
class AvisoDeCampo extends StatelessWidget {
  const AvisoDeCampo(this.mensaje, {super.key});

  final String mensaje;

  @override
  Widget build(BuildContext context) =>
      ExcludeSemantics(child: _FilaDeError(mensaje));
}

class _FilaDeError extends StatelessWidget {
  const _FilaDeError(this.mensaje);

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Row(
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
    );
  }
}

/// Lo que el lector dice de un campo además de su etiqueta: el formato esperado y el
/// error, en ese orden. `null` si no hay nada que agregar.
String? ayudaAccesible({String? formato, String? error}) {
  final partes = [?formato, ?error];
  return partes.isEmpty ? null : partes.join('. ');
}

/// El ojo que muestra u oculta la contraseña, al final del campo.
class VerContrasena extends StatelessWidget {
  const VerContrasena({
    super.key,
    required this.visible,
    required this.alCambiar,
  });

  final bool visible;
  final VoidCallback alCambiar;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: visible ? 'Ocultar contraseña' : 'Mostrar contraseña',
      onPressed: alCambiar,
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: context.paleta.textSecondary,
      ),
    );
  }
}
