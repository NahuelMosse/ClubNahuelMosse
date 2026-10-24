import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

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
      button: true,
      selected: elegido,
      enabled: alTocar != null,
      focusable: alTocar != null,
      label: nombre,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 16)),
                        Text(
                          nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Textos.titulo.copyWith(color: p.textOnMedia),
                        ),
                      ],
                    ),
                  ),
                  if (elegido)
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: p.accentBase,
                          borderRadius: BorderRadius.circular(
                            Medidas.radioPill,
                          ),
                        ),
                        child: Text(
                          'ELEGIDO',
                          style: Textos.sobretitulo.copyWith(color: p.accentOn),
                        ),
                      ),
                    ),
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
