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

/// La portada: el saludo, la cuenta y el pedido del día. Va sobre una foto, así que sus
/// colores son los `on-media`, iguales en los dos modos.
class HomeHero extends StatelessWidget {
  const HomeHero({
    super.key,
    required this.sesion,
    required this.celdas,
    required this.yaEntro,
    this.centro,
  });

  final Session sesion;
  final bool yaEntro;

  final NotificationCenter? centro;

  /// `null` mientras se lee.
  final List<MarkerCell>? celdas;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final arriba = MediaQuery.paddingOf(context).top;
    final marcador = celdas;
    return PhotoWithScrim(
      image: sportPhoto('Futbol'),
      child: Stack(
        children: [
          const Positioned.fill(child: HeroVeil()),
          Padding(
            padding: EdgeInsets.fromLTRB(
              Spacing.s24,
              arriba + Spacing.s24,
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
                        child: HomeGreeting(sesion: sesion),
                      ),
                    ),
                    if (centro case final centro?)
                      NotificationsButton(center: centro),
                    AccountButton(session: sesion),
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
                if (marcador != null) ...[
                  const SizedBox(height: Spacing.s24),
                  Padding(
                    padding: const EdgeInsets.only(right: Spacing.s8),
                    child: FadeIn(
                      delay: const Duration(milliseconds: 250),
                      duration: const Duration(milliseconds: 500),
                      fromY: 0,
                      scaleFrom: 0.85,
                      curve: AppMotion.fast,
                      alreadyEntered: yaEntro,
                      child: AppMarker(cells: marcador),
                    ),
                  ),
                ] else
                  // El lugar del marcador mientras llega, para que lo de abajo no salte.
                  const SizedBox(height: _markerSpace),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lo que ocupa el marcador con su separación: lo reserva mientras no hay datos.
const _markerSpace = 136.0;
