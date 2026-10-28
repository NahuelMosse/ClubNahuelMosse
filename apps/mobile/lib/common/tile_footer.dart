import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';

/// The emoji and the sport name at the bottom of a [SportTile].
class TileFooter extends StatelessWidget {
  const TileFooter({super.key, required this.emoji, required this.name});

  final String emoji;
  final String name;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Texts.title.copyWith(color: p.textOnMedia),
        ),
      ],
    );
  }
}
