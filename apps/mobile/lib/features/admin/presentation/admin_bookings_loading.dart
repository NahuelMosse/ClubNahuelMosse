import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// The «Cargando reservas…» sliver of the history.
class AdminBookingsLoading extends StatelessWidget {
  const AdminBookingsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.s40),
        child: Column(
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                'Cargando reservas…',
                style: Texts.overline.copyWith(color: p.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
