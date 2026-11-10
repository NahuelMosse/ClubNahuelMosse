// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/app_language.dart';
import '../../../common/club_timezone.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../session/presentation/session.dart';

/// El saludo de la hora del club y el nombre del socio, que se actualiza con la [session].
class HomeGreeting extends StatelessWidget {
  const HomeGreeting({super.key, required this.session});

  final Session session;

  static const _afternoonStarts = 12;
  static const _nightStarts = 20;
  static const _nightEnds = 6;

  /// The greeting of a [clubHour] in the language the app is showing.
  static String forHour(DateTime clubHour) {
    final l10n = lookupAppLocalizations(Locale(currentLanguage()));
    final hour = clubHour.hour;
    if (hour < _nightEnds || hour >= _nightStarts) {
      return l10n.homeGreetingNight;
    }
    return hour < _afternoonStarts
        ? l10n.homeGreetingMorning
        : l10n.homeGreetingAfternoon;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          forHour(clubNow()),
          style: Texts.overline.copyWith(color: p.accentOnMedia),
        ),
        const SizedBox(height: Spacing.s4),
        ListenableBuilder(
          listenable: session,
          builder: (context, _) => Text(
            session.profile?.firstName ?? '',
            style: Texts.h1.copyWith(color: p.textOnMedia),
          ),
        ),
      ],
    );
  }
}
