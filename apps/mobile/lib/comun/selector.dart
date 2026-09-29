import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Un campo que no se escribe sino que se elige: se ve como `Input` o `Dropdown` del
/// prototipo y al tocarlo abre las opciones.
class CampoSelector extends StatelessWidget {
  const CampoSelector({
    super.key,
    required this.etiqueta,
    required this.etiquetaAccesible,
    required this.valor,
    required this.placeholder,
    required this.icono,
    required this.alTocar,
    this.error,
    this.soloLectura = false,
  });

  final String etiqueta;
  final String etiquetaAccesible;
  final String? valor;
  final String placeholder;
  final IconData icono;
  final VoidCallback? alTocar;
  final String? error;

  /// Un dato que se muestra pero no se cambia: todo apagado, como el `Dropdown` deshabilitado
  /// del prototipo.
  final bool soloLectura;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final mensaje = error;
    final elegido = valor;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Medidas.radioPill),
      side: mensaje != null
          ? BorderSide(color: p.borderError, width: 1.5)
          : BorderSide(color: soloLectura ? p.borderDefault : p.borderControl),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(
            etiqueta,
            style: Textos.sobretitulo.copyWith(
              color: soloLectura ? p.stateDisabled : p.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: Medidas.s8),
        Semantics(
          container: true,
          button: true,
          enabled: alTocar != null,
          label: etiquetaAccesible,
          value: elegido ?? '',
          excludeSemantics: true,
          onTap: alTocar,
          child: Material(
            color: soloLectura ? Colors.transparent : p.bgSurface,
            shape: forma,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: alTocar,
              child: SizedBox(
                height: Medidas.altoControl,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Medidas.s20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          elegido ?? placeholder,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Textos.cuerpo.copyWith(
                            // Apagado, pero el dato se tiene que poder leer.
                            color: soloLectura
                                ? p.textSecondary
                                : elegido == null
                                ? p.textMuted
                                : p.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: Medidas.s12),
                      Icon(
                        icono,
                        size: 24,
                        color: soloLectura ? p.stateDisabled : p.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (mensaje != null) ...[
          const SizedBox(height: Medidas.s8),
          // El lector de pantalla anuncia el error apenas aparece.
          Semantics(
            liveRegion: true,
            child: Row(
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
          ),
        ],
      ],
    );
  }
}

/// Abre la lista de [opciones] y devuelve la elegida, o `null` si se cierra sin elegir.
Future<T?> elegirOpcion<T>(
  BuildContext context, {
  required String titulo,
  required List<(T, String)> opciones,
  T? elegida,
  int columnas = 1,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) {
      final p = context.paleta;
      return Dialog(
        backgroundColor: p.bgSurfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Medidas.radioLg),
          side: BorderSide(color: p.borderDefault),
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: Medidas.s24,
          vertical: Medidas.s48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Medidas.s24,
                Medidas.s20,
                Medidas.s24,
                Medidas.s8,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  titulo,
                  style: Textos.titulo.copyWith(color: p.textPrimary),
                ),
              ),
            ),
            // Todas las opciones se construyen de una, en [columnas] columnas: son pocas y
            // así se llega a cualquiera sin que la lista las vaya descartando.
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Medidas.s12,
                  0,
                  Medidas.s12,
                  Medidas.s12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < opciones.length; i += columnas)
                      Row(
                        children: [
                          for (var j = i; j < i + columnas; j++)
                            Expanded(
                              child: j < opciones.length
                                  ? _Opcion(
                                      texto: opciones[j].$2,
                                      elegida: opciones[j].$1 == elegida,
                                      centrada: columnas > 1,
                                      alTocar: () => Navigator.of(
                                        context,
                                      ).pop(opciones[j].$1),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.texto,
    required this.elegida,
    required this.centrada,
    required this.alTocar,
  });

  final String texto;
  final bool elegida;
  final bool centrada;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      button: true,
      selected: elegida,
      child: Material(
        color: elegida ? p.accentMuted : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: alTocar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Medidas.tactil + 4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Medidas.s12),
              child: Row(
                mainAxisAlignment: centrada
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      texto,
                      style: (elegida ? Textos.cuerpoFuerte : Textos.cuerpo)
                          .copyWith(color: p.textPrimary),
                    ),
                  ),
                  if (elegida && !centrada) ...[
                    const Spacer(),
                    Icon(Icons.check_rounded, size: 20, color: p.accentInk),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
