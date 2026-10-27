import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'campo_texto.dart';
import 'movimiento.dart';
import 'rejilla_de_opciones.dart';
import 'valor_del_selector.dart';

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
          hint: mensaje,
          liveRegion: mensaje != null,
          excludeSemantics: true,
          onTap: alTocar,
          child: Temblor(
            disparador: mensaje,
            child: Material(
              color: soloLectura ? Colors.transparent : p.bgSurface,
              shape: forma,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: alTocar,
                child: SizedBox(
                  height: Medidas.altoControl,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Medidas.s20,
                    ),
                    child: ValorDelSelector(
                      valor: elegido,
                      placeholder: placeholder,
                      icono: icono,
                      soloLectura: soloLectura,
                    ),
                  ),
                ),
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
      return Aparecer(
        escalaDesde: 0.88,
        desdeY: 0,
        curva: Movimiento.rapida,
        child: Dialog(
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
              Flexible(
                child: RejillaDeOpciones<T>(
                  opciones: opciones,
                  columnas: columnas,
                  elegida: elegida,
                  alElegir: (valor) => Navigator.of(context).pop(valor),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
