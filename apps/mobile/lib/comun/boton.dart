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

/// `Btn/Type=Secondary`: pill de 52 con borde, para acciones que no son la principal.
class BotonContorno extends StatelessWidget {
  const BotonContorno({
    super.key,
    required this.texto,
    required this.alTocar,
    this.peligro = false,
  });

  final String texto;
  final VoidCallback? alTocar;

  /// `Btn/Type=Danger-Outline`: borde y texto rojos, para acciones que no se deshacen.
  final bool peligro;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: Medidas.altoControl,
        minWidth: double.infinity,
      ),
      child: OutlinedButton(
        onPressed: alTocar,
        style: OutlinedButton.styleFrom(
          foregroundColor: peligro ? p.stateDangerInk : p.textPrimary,
          side: BorderSide(
            color: peligro ? p.stateDanger : p.borderControl,
            width: 1.5,
          ),
          shape: const StadiumBorder(),
          textStyle: Textos.boton,
          padding: const EdgeInsets.symmetric(horizontal: Medidas.s24),
        ),
        child: Text(texto, textAlign: TextAlign.center),
      ),
    );
  }
}

/// La barra fija de abajo con la acción principal de un formulario largo.
class BarraDeAccion extends StatelessWidget {
  const BarraDeAccion({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        border: Border(top: BorderSide(color: p.borderDefault)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Medidas.s24,
            Medidas.s16,
            Medidas.s24,
            Medidas.s24,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// `Btn/Type=Danger`: pill rojo para confirmar algo que no se deshace.
///
/// El rojo es el del modo claro en los dos modos: con el del modo oscuro el texto blanco no
/// llega al contraste mínimo.
class BotonPeligro extends StatelessWidget {
  const BotonPeligro({super.key, required this.texto, required this.alTocar});

  final String texto;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: Medidas.altoControl,
        minWidth: double.infinity,
      ),
      child: FilledButton(
        onPressed: alTocar,
        style: FilledButton.styleFrom(
          backgroundColor: Paleta.clara.stateDanger,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          textStyle: Textos.boton,
          padding: const EdgeInsets.symmetric(horizontal: Medidas.s24),
        ),
        child: Text(texto, textAlign: TextAlign.center),
      ),
    );
  }
}
