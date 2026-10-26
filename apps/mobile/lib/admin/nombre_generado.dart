import 'package:flutter/material.dart';
import '../comun/boton.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// `Card-PreviewNombre`: el nombre que va a tener el espacio, o lo que falta para armarlo.
class NombreGenerado extends StatelessWidget {
  const NombreGenerado({
    super.key,
    required this.nombre,
    this.calculando = false,
    this.falta = '',
    this.alReintentar,
  });

  final String? nombre;
  final bool calculando;
  final String falta;

  /// Si no se pudo calcular el nombre, la acción para volver a pedirlo.
  final VoidCallback? alReintentar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final listo = nombre;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Medidas.s16,
          vertical: Medidas.s16,
        ),
        decoration: BoxDecoration(
          color: p.bgSurface,
          borderRadius: BorderRadius.circular(Medidas.radioMd),
          border: Border.all(
            color: listo == null ? p.borderControl : p.accentInk,
            width: listo == null ? 1 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              'NOMBRE GENERADO AUTOMÁTICAMENTE',
              textAlign: TextAlign.center,
              style: Textos.sobretitulo.copyWith(color: p.accentInk),
            ),
            const SizedBox(height: Medidas.s8),
            if (calculando)
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (alReintentar case final reintentar?) ...[
              Text(
                'No se pudo calcular el nombre',
                textAlign: TextAlign.center,
                style: Textos.leyenda.copyWith(color: p.stateDangerInk),
              ),
              BotonTexto(texto: 'REINTENTAR', alTocar: reintentar),
            ] else
              Text(
                listo ?? falta,
                textAlign: TextAlign.center,
                style: listo == null
                    ? Textos.leyenda.copyWith(color: p.textMuted)
                    : Textos.mono.copyWith(color: p.textPrimary),
              ),
          ],
        ),
      ),
    );
  }
}
