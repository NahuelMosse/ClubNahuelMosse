import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// El `AppBar` del prototipo: volver a la izquierda y el título.
class BarraSuperior extends StatelessWidget implements PreferredSizeWidget {
  const BarraSuperior({
    super.key,
    required this.titulo,
    this.alVolver,
    this.botonDelSistema = false,
  });

  final String titulo;
  final VoidCallback? alVolver;

  /// El botón de volver se deja localizar como el «Back» del sistema.
  final bool botonDelSistema;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final volver = alVolver ?? () => Navigator.of(context).maybePop();
    return AppBar(
      backgroundColor: p.bgBase,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: kToolbarHeight,
      titleSpacing: 0,
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: Medidas.s12),
        // El tooltip de Flutter no es la etiqueta del botón: sin esto, el lector de
        // pantalla lo anuncia como «Volver» pero no se lo encuentra por su nombre.
        child: Semantics(
          button: true,
          label: 'Volver',
          onTap: volver,
          excludeSemantics: true,
          child: botonDelSistema
              ? Tooltip(
                  // Nunca se muestra: `WidgetTester.pageBack` localiza el botón de volver por
                  // el tooltip «Back» y con el idioma de la app el del sistema dice otra cosa.
                  message: 'Back',
                  triggerMode: TooltipTriggerMode.manual,
                  excludeFromSemantics: true,
                  child: IconButton(
                    onPressed: volver,
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: p.textPrimary,
                      size: 28,
                    ),
                  ),
                )
              : IconButton(
                  tooltip: 'Volver',
                  onPressed: volver,
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color: p.textPrimary,
                    size: 28,
                  ),
                ),
        ),
      ),
      title: Text(titulo, style: Textos.titulo.copyWith(color: p.textPrimary)),
    );
  }
}
