// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'selected_badge.dart';
import 'tile_footer.dart';

/// Sport card of 124×148 with a background photo, emoji and name; [selected] marks it with the accent.
class SportTile extends StatelessWidget {
  const SportTile({
    super.key,
    required this.image,
    required this.emoji,
    required this.name,
    this.selected = false,
    required this.onTap,
  });

  final ImageProvider image;
  final String emoji;
  final String name;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(20);
    return Semantics(
      label: name,
      button: onTap != null ? true : null,
      selected: onTap != null || selected ? selected : null,
      enabled: onTap != null ? true : null,
      focusable: onTap != null ? true : null,
      onTap: onTap,
      child: ExcludeSemantics(
        child: SizedBox(
          width: 124,
          height: 148,
          child: ClipRRect(
            borderRadius: radius,
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: radius,
                border: selected
                    ? Border.all(color: p.accentBase, width: 3)
                    : null,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image(image: image, fit: BoxFit.cover),
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
                    child: TileFooter(emoji: emoji, name: name),
                  ),
                  if (selected)
                    const Positioned(left: 10, top: 10, child: SelectedBadge()),
                  if (onTap != null)
                    Positioned.fill(
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(onTap: onTap),
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
