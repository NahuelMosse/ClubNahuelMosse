// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/club_timezone.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../session/presentation/session.dart';

/// El saludo de la hora del club y el nombre del socio, que se actualiza con la [sesion].
class HomeGreeting extends StatelessWidget {
  const HomeGreeting({super.key, required this.sesion});

  final Session sesion;

  static const _afternoonStarts = 12;
  static const _nightStarts = 20;
  static const _nightEnds = 6;

  /// «BUENOS DÍAS,», «BUENAS TARDES,» o «BUENAS NOCHES,» para una [clubHour].
  static String forHour(DateTime clubHour) {
    final hour = clubHour.hour;
    if (hour < _nightEnds || hour >= _nightStarts) return 'BUENAS NOCHES,';
    return hour < _afternoonStarts ? 'BUENOS DÍAS,' : 'BUENAS TARDES,';
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
          listenable: sesion,
          builder: (context, _) => Text(
            sesion.profile?.firstName ?? '',
            style: Texts.h1.copyWith(color: p.textOnMedia),
          ),
        ),
      ],
    );
  }
}
