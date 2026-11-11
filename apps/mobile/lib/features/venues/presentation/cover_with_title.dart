import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import 'photos.dart';

/// The photo with a veil and, on top, the way back, an overline, the name of the venue
/// and whatever each screen adds below ([extra]).
class CoverWithTitle extends StatelessWidget {
  const CoverWithTitle({
    super.key,
    required this.image,
    required this.backTo,
    required this.onBack,
    required this.gap,
    required this.overline,
    required this.name,
    this.extra = const [],
  });

  final ImageProvider image;

  /// The name of the screen it goes back to.
  final String backTo;
  final VoidCallback onBack;

  /// The height between the way back and the overline.
  final double gap;
  final String overline;
  final String name;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PhotoWithScrim(
      image: image,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.s12,
            Spacing.s8,
            Spacing.s24,
            Spacing.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: onBack,
                style: TextButton.styleFrom(
                  foregroundColor: p.textOnMedia,
                  minimumSize: const Size(0, Spacing.touchTarget),
                  textStyle: Texts.caption,
                ),
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                label: Text(backTo),
              ),
              SizedBox(height: gap),
              Padding(
                padding: const EdgeInsets.only(left: Spacing.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overline,
                      style: Texts.overline.copyWith(color: p.accentOnMedia),
                    ),
                    const SizedBox(height: Spacing.s4),
                    Semantics(
                      header: true,
                      child: Text(
                        name.toUpperCase(),
                        style: Texts.display.copyWith(color: p.textOnMedia),
                      ),
                    ),
                    ...extra,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
