import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// `Btn/Type=Primary`: pill lima de 52 de alto. Deshabilitado baja al 40 % de opacidad.
class BotonPrimario extends StatelessWidget {
  const BotonPrimario({
    super.key,
    required this.texto,
    required this.alTocar,
    this.cargando = false,
  });

  final String texto;
  final VoidCallback? alTocar;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final habilitado = alTocar != null && !cargando;
    return Opacity(
      opacity: habilitado || cargando ? 1 : 0.4,
      child: SizedBox(
        height: Medidas.altoControl,
        width: double.infinity,
        child: FilledButton(
          onPressed: habilitado ? alTocar : null,
          style: FilledButton.styleFrom(
            backgroundColor: p.accentBase,
            foregroundColor: p.accentOn,
            disabledBackgroundColor: p.accentBase,
            disabledForegroundColor: p.accentOn,
            shape: const StadiumBorder(),
            side: BorderSide(color: p.accentEdge),
            textStyle: Textos.boton,
            padding: const EdgeInsets.symmetric(horizontal: Medidas.s24),
          ),
          child: cargando
              ? SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: p.accentOn,
                  ),
                )
              : Text(texto),
        ),
      ),
    );
  }
}

/// `Btn/Type=Text`: sin fondo, en `accent/ink`. Con [sobreFoto] usa el lima fijo.
class BotonTexto extends StatelessWidget {
  const BotonTexto({
    super.key,
    required this.texto,
    required this.alTocar,
    this.icono,
    this.sobreFoto = false,
  });

  final String texto;
  final VoidCallback? alTocar;
  final IconData? icono;
  final bool sobreFoto;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final color = sobreFoto ? Paleta.oscura.accentBase : p.accentInk;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Medidas.altoControl),
      child: TextButton(
        onPressed: alTocar,
        style: TextButton.styleFrom(
          foregroundColor: color,
          textStyle: Textos.boton,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: Medidas.s24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(texto, textAlign: TextAlign.center)),
            if (icono != null) ...[
              const SizedBox(width: Medidas.s8),
              Icon(icono, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
