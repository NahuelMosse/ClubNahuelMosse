// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/list_loading.dart';
import '../../../common/skeleton.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../spaces/domain/space.dart';
import '../../spaces/presentation/sport_icons.dart';
import '../domain/venue.dart';
import '../domain/venue_summary.dart';
import 'cover_with_title.dart';
import 'light_label.dart';
import 'photos.dart';
import 'space_filter.dart';
import 'space_list.dart';

class VenueContent extends StatelessWidget {
  const VenueContent({
    super.key,
    required this.venue,
    required this.spaces,
    required this.allSpaces,
    required this.catalog,
    required this.sport,
    required this.kind,
    required this.sportKinds,
    required this.enabled,
    required this.filtering,
    required this.onSportSelected,
    required this.onKindSelected,
  });

  final Venue venue;

  /// Las que pasan el filtro; [todas] son las de la sede, de donde salen los deportes.
  final List<Space> spaces;
  final List<Space> allSpaces;
  final Catalog catalog;
  final String? sport;
  final String? kind;
  final List<String> sportKinds;
  final bool enabled;

  /// Mientras llega la lista filtrada, en su lugar se ve la carga.
  final bool filtering;
  final ValueChanged<String> onSportSelected;
  final ValueChanged<String?> onKindSelected;

  String _kindName(String key) =>
      catalog
          .sport(sport ?? '')
          ?.kinds
          .where((x) => x.key == key)
          .firstOrNull
          ?.name ??
      key;

  /// «4 CANCHAS · FÚTBOL · TODOS LOS TIPOS», como el prototipo.
  String _counter() {
    final count = spaceCountLabel(spaces.length);
    final d = sport;
    final t = kind;
    if (allSpaces.isEmpty) return count.toUpperCase();
    if (d == null) return '$count · todos los deportes'.toUpperCase();
    if (t != null) return '$count · ${_kindName(t)}'.toUpperCase();
    final sportName = catalog.sport(d)?.name ?? d;
    if (sportKinds.length > 1) {
      return '$count · $sportName · todos los tipos'.toUpperCase();
    }
    return '$count · $sportName'.toUpperCase();
  }

  Widget _filters() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SpaceFilter(
        title: 'DEPORTE',
        options: [
          for (final d in catalog.sports)
            if (allSpaces.any((c) => c.sport == d.key))
              (d.key, d.name, sportIcon(d.key)),
        ],
        selected: sport,
        enabled: enabled,
        prefix: 'Deporte',
        onSelected: (key) {
          if (key != null) onSportSelected(key);
        },
      ),
      if (sport != null && sportKinds.length > 1) ...[
        const SizedBox(height: Spacing.s16),
        SpaceFilter(
          title: 'TIPO DE CANCHA',
          options: [
            (null, 'Todos', null),
            for (final t in sportKinds) (t, _kindName(t), null),
          ],
          selected: kind,
          enabled: enabled,
          prefix: 'Tipo',
          onSelected: onKindSelected,
        ),
      ],
      const SizedBox(height: Spacing.s24),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final sports = sportsOf(venue, catalog);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CoverWithTitle(
            image: venueCover(venue.id),
            backTo: 'Todas las sedes',
            onBack: () => context.go('/sedes'),
            gap: Spacing.s40,
            overline: '${venue.address} · ${venue.opening} a ${venue.closing}'
                .toUpperCase(),
            name: venue.name,
            extra: [
              if (sports.isNotEmpty) ...[
                const SizedBox(height: Spacing.s8),
                Wrap(
                  spacing: Spacing.s4,
                  runSpacing: Spacing.s4,
                  children: [for (final d in sports) LightLabel(text: d)],
                ),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.s24,
              Spacing.s24,
              Spacing.s24,
              Spacing.s40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (allSpaces.isNotEmpty) _filters(),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _counter(),
                    style: Texts.overline.copyWith(color: p.accentInk),
                  ),
                ),
                const SizedBox(height: Spacing.s12),
                ListSwitcher(
                  child: filtering
                      ? const SkeletonList(
                          key: ValueKey('carga'),
                          shape: SkeletonShape.space,
                        )
                      : SpaceList(
                          key: ValueKey((sport, kind)),
                          venueId: venue.id,
                          spaces: spaces,
                          allSpaces: allSpaces,
                          catalog: catalog,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
