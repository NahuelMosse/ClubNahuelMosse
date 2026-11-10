// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/marker.dart';
import '../../../common/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../notifications/presentation/bell_button.dart';
import '../../notifications/presentation/notification_center.dart';
import '../../session/presentation/account_card.dart';
import '../../session/presentation/session.dart';
import '../../venues/presentation/photos.dart';
import 'hero_veil.dart';
import 'home_greeting.dart';

/// The cover: the greeting, the account and the request of the day. It goes over a photo,
/// so its colors are the `on-media` ones, the same in both modes.
class HomeHero extends StatelessWidget {
  const HomeHero({
    super.key,
    required this.session,
    required this.cells,
    required this.alreadyEntered,
    this.center,
  });

  final Session session;
  final bool alreadyEntered;

  final NotificationCenter? center;

  /// `null` while it is being read.
  final List<MarkerCell>? cells;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final top = MediaQuery.paddingOf(context).top;
    final marker = cells;
    return PhotoWithScrim(
      image: sportPhoto('Futbol'),
      child: Stack(
        children: [
          const Positioned.fill(child: HeroVeil()),
          Padding(
            padding: EdgeInsets.fromLTRB(
              Spacing.s24,
              top + Spacing.s24,
              Spacing.s16,
              Spacing.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FadeIn(
                        delay: const Duration(milliseconds: 50),
                        child: HomeGreeting(session: session),
                      ),
                    ),
                    if (center case final center?)
                      NotificationsButton(center: center),
                    AccountButton(session: session),
                  ],
                ),
                const SizedBox(height: Spacing.s48),
                Semantics(
                  header: true,
                  child: Text(
                    AppLocalizations.of(context).homeHeroTitle,
                    style: Texts.display.copyWith(color: p.textOnMedia),
                  ),
                ),
                if (marker != null) ...[
                  const SizedBox(height: Spacing.s24),
                  Padding(
                    padding: const EdgeInsets.only(right: Spacing.s8),
                    child: FadeIn(
                      delay: const Duration(milliseconds: 250),
                      duration: const Duration(milliseconds: 500),
                      fromY: 0,
                      scaleFrom: 0.85,
                      curve: AppMotion.fast,
                      alreadyEntered: alreadyEntered,
                      child: AppMarker(cells: marker),
                    ),
                  ),
                ] else
                  // The place of the marker while it arrives, so that what is below does
                  // not jump.
                  const SizedBox(height: _markerSpace),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What the marker takes up with its spacing: it reserves it while there is no data.
const _markerSpace = 136.0;
