import 'package:flutter/material.dart';

import '../../../common/logo_mark.dart';
import '../../../common/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

class LoginBrand extends StatelessWidget {
  const LoginBrand({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FadeIn(
          duration: Duration(milliseconds: 700),
          fromY: -70,
          turn: 25 / 360,
          curve: AppMotion.bounce,
          child: LogoMark(size: 40, decorative: true),
        ),
        const SizedBox(height: Spacing.s16),
        Text(
          l10n.loginWelcome,
          style: Texts.overline.copyWith(color: p.accentOnMedia),
        ),
        const SizedBox(height: Spacing.s8),
        Semantics(
          header: true,
          label: l10n.appName,
          child: ExcludeSemantics(
            // En el teléfono chico la marca se achica antes que partirse en dos líneas.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'CLUB ',
                      style: TextStyle(color: p.textOnMedia),
                    ),
                    TextSpan(
                      text: 'NAHUELMOSSE',
                      style: TextStyle(color: p.accentOnMedia),
                    ),
                  ],
                ),
                style: Texts.display,
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.s8),
        Text(
          l10n.loginTagline,
          style: Texts.body.copyWith(color: p.textOnMediaMuted),
        ),
      ],
    );
  }
}
