// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'logo_mark.dart';

/// The top row of the profile: «FICHA DE SOCIO», the number if any and the logo mark.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, this.number});

  final String? number;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final numberText = number;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FICHA DE SOCIO',
              style: Texts.overline.copyWith(color: p.accentOnMedia),
            ),
            if (numberText != null)
              Text(
                numberText,
                style: Texts.mono.copyWith(color: p.textOnMediaMuted),
              ),
          ],
        ),
        const Spacer(),
        const LogoMark(size: 32, decorative: true),
      ],
    );
  }
}
