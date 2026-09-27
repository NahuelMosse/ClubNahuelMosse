import 'package:flutter/material.dart';

import '../api/cliente_api.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Los overlays compartidos de error de conexión y de error del servidor.
///
/// Devuelve `true` si la persona eligió reintentar; quien llama reintenta cuando el
/// intento anterior ya terminó.
Future<bool> mostrarErrorDeRed(BuildContext context, Object error) async {
  final sinConexion = error is SinConexion;
  final reintentar = await showDialog<bool>(
    context: context,
    barrierColor: context.paleta.bgScrim,
    builder: (context) => _Modal(
      icono: sinConexion ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
      titulo: sinConexion ? 'Error de conexión' : 'Error del servidor',
      texto: sinConexion
          ? 'No pudimos conectarnos. Revisá tu conexión a internet y volvé a intentar.'
          : 'No pudimos procesar la operación en este momento. Intentá más tarde.',
      principal: sinConexion ? 'REINTENTAR' : null,
      secundaria: sinConexion ? 'Volver' : 'ACEPTAR',
    ),
  );
  return reintentar ?? false;
}

/// El overlay compartido de sesión expirada. No se puede descartar: la única salida es
/// volver a iniciar sesión, que hace quien llama cuando esto termina.
Future<void> mostrarSesionVencida(BuildContext context) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  barrierColor: context.paleta.bgScrim,
  builder: (context) => const PopScope(
    canPop: false,
    child: _Modal(
      icono: Icons.cloud_off_rounded,
      titulo: 'Tu sesión expiró',
      texto:
          'Por seguridad cerramos tu sesión. Volvé a iniciar sesión para continuar.',
      principal: 'IR AL INICIO DE SESIÓN',
    ),
  ),
);

/// `Modal` del prototipo: ícono en círculo, título, texto y hasta dos acciones. La
/// principal cierra con `true` y la secundaria con `false`.
class _Modal extends StatelessWidget {
  const _Modal({
    required this.icono,
    required this.titulo,
    required this.texto,
    this.principal,
    this.secundaria,
  });

  final IconData icono;
  final String titulo;
  final String texto;
  final String? principal;
  final String? secundaria;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final accionPrincipal = principal;
    final accionSecundaria = secundaria;
    return Dialog(
      backgroundColor: p.bgSurfaceRaised,
      insetPadding: const EdgeInsets.symmetric(horizontal: Medidas.s24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Medidas.radioLg),
        side: BorderSide(color: p.borderDefault),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Medidas.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: p.stateDangerMuted,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icono, size: 28, color: p.stateDangerInk),
                ),
              ),
              const SizedBox(height: Medidas.s12),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: Textos.h2.copyWith(color: p.textPrimary),
              ),
              const SizedBox(height: Medidas.s12),
              Text(
                texto,
                textAlign: TextAlign.center,
                style: Textos.cuerpo.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: Medidas.s12),
              if (accionPrincipal != null)
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: p.accentBase,
                    foregroundColor: p.accentOn,
                    minimumSize: const Size.fromHeight(Medidas.altoControl),
                    shape: const StadiumBorder(),
                    textStyle: Textos.boton,
                  ),
                  child: Text(accionPrincipal, textAlign: TextAlign.center),
                ),
              if (accionPrincipal != null && accionSecundaria != null)
                const SizedBox(height: Medidas.s8),
              if (accionSecundaria != null)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: p.accentInk,
                    minimumSize: const Size.fromHeight(Medidas.altoControl),
                    textStyle: Textos.boton,
                  ),
                  child: Text(accionSecundaria),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
