import 'package:flutter/material.dart';

import '../tema/tokens.dart';
import 'insignia_elegido.dart';
import 'pie_de_tile.dart';

/// Tarjeta de deporte de 124×148 con foto de fondo, emoji y nombre; [elegido] la marca con el acento.
class TileDeporte extends StatelessWidget {
  const TileDeporte({
    super.key,
    required this.imagen,
    required this.emoji,
    required this.nombre,
    this.elegido = false,
    required this.alTocar,
  });

  final ImageProvider imagen;
  final String emoji;
  final String nombre;
  final bool elegido;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final radio = BorderRadius.circular(20);
    return Semantics(
      label: nombre,
      button: alTocar != null ? true : null,
      selected: alTocar != null || elegido ? elegido : null,
      enabled: alTocar != null ? true : null,
      focusable: alTocar != null ? true : null,
      onTap: alTocar,
      child: ExcludeSemantics(
        child: SizedBox(
          width: 124,
          height: 148,
          child: ClipRRect(
            borderRadius: radio,
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: radio,
                border: elegido
                    ? Border.all(color: p.accentBase, width: 3)
                    : null,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image(image: imagen, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xD9000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: PieDeTile(emoji: emoji, nombre: nombre),
                  ),
                  if (elegido)
                    const Positioned(
                      left: 10,
                      top: 10,
                      child: InsigniaElegido(),
                    ),
                  if (alTocar != null)
                    Positioned.fill(
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(onTap: alTocar),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
