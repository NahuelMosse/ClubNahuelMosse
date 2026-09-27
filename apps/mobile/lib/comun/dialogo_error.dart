import 'package:flutter/material.dart';

import '../api/cliente_api.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Los overlays compartidos de error de conexión y de error del servidor.
Future<void> mostrarErrorDeRed(
  BuildContext context,
  Object error, {
  VoidCallback? reintentar,
}) {
  final sinConexion = error is SinConexion;
  return showDialog<void>(
    context: context,
    barrierColor: context.paleta.bgScrim,
    builder: (context) {
      final p = context.paleta;
      return Dialog(
        backgroundColor: p.bgSurfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Medidas.radioLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Medidas.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                sinConexion ? 'Error de conexión' : 'Error del servidor',
                style: Textos.h2.copyWith(color: p.textPrimary),
              ),
              const SizedBox(height: Medidas.s8),
              Text(
                sinConexion
                    ? 'No pudimos conectarnos. Revisá tu conexión a internet y volvé a intentar.'
                    : 'No pudimos procesar la operación en este momento. Intentá más tarde.',
                style: Textos.cuerpo.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: Medidas.s24),
              if (sinConexion && reintentar != null)
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    reintentar();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: p.accentBase,
                    foregroundColor: p.accentOn,
                    minimumSize: const Size.fromHeight(Medidas.altoControl),
                    shape: const StadiumBorder(),
                    textStyle: Textos.boton,
                  ),
                  child: const Text('REINTENTAR'),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: p.accentInk,
                  minimumSize: const Size.fromHeight(Medidas.altoControl),
                  textStyle: Textos.boton,
                ),
                child: Text(sinConexion ? 'Volver' : 'ACEPTAR'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
