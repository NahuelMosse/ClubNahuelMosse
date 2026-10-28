// kit-shape: a screen or error family kept with its private parts.
// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/bottom_bar.dart';
import '../../../common/empty_state.dart';
import '../../../common/network_failure.dart';
import '../../../common/skeleton.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../../spaces/domain/space.dart';
import '../../spaces/presentation/spaces.dart';
import '../domain/venue.dart';
import '../domain/venue_summary.dart';
import 'venue_card.dart';
import 'venues.dart';

export 'venue_card.dart' show VenueCard;

/// «Todas las sedes»: el catálogo del club, desde la pestaña SEDES.
class VenuesScreen extends StatefulWidget {
  const VenuesScreen({
    super.key,
    required this.venues,
    required this.spaces,
    required this.session,
  });

  final Venues venues;
  final Spaces spaces;
  final Session session;

  @override
  State<VenuesScreen> createState() => _VenuesScreenState();
}

class _VenuesScreenState extends State<VenuesScreen> {
  (List<Venue>, Catalog)? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // La sede o la cancha que se abrió puede avisar que ya no está: se vuelve a leer.
    widget.venues.addListener(_load);
    widget.spaces.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.venues.removeListener(_load);
    widget.spaces.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    Object? failure;
    var expired = false;
    try {
      final catalog = await widget.spaces.repository.catalog();
      final venues = await widget.venues.repository.active();
      if (!mounted) return;
      setState(() {
        _data = (venues, catalog);
        _loading = false;
      });
      return;
    } on SessionExpired {
      expired = true;
    } on FalloDeRed catch (e) {
      failure = e;
    }
    if (!mounted) return;
    // Sin datos frescos no se muestra nada: ni parciales ni viejos.
    setState(() {
      _data = null;
      _loading = false;
    });
    // Tapado por la sede o los horarios no avisa: la pantalla de arriba ya avisa lo suyo.
    await avisarFalloDeCarga(
      context,
      session: widget.session,
      expired: expired,
      error: failure,
      reintentar: _load,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final data = _data;
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: const BottomBar(current: Section.venues),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            key: const PageStorageKey('sedes'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              Spacing.s24,
              Spacing.s24,
              Spacing.s24,
              Spacing.s40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Sedes',
                    style: Texts.h1.copyWith(color: p.textPrimary),
                  ),
                ),
                if (data != null) ...[
                  const SizedBox(height: Spacing.s4),
                  Text(
                    '${data.$1.length == 1 ? '1 sede' : '${data.$1.length} sedes'} · '
                    '${spaceCountLabel(data.$1.fold(0, (n, s) => n + s.spaceCount))} · '
                    'cada una con su horario',
                    style: Texts.caption.copyWith(color: p.textSecondary),
                  ),
                  const SizedBox(height: Spacing.s16),
                  if (data.$1.isEmpty)
                    const EmptyState(
                      title: 'Todavía no hay sedes',
                      text: 'El club todavía no cargó sus sedes.',
                    ),
                  for (final venue in data.$1) ...[
                    VenueCard(
                      venue: venue,
                      sports: sportsOf(venue, data.$2),
                      onTap: () => context.go('/sedes/${venue.id}'),
                    ),
                    const SizedBox(height: Spacing.s16),
                  ],
                ],
                if (data == null && _loading)
                  const SkeletonList(shape: SkeletonShape.venue),
                if (data == null && !_loading)
                  EmptyState(
                    title: 'No pudimos mostrar las sedes',
                    text: 'Revisá tu conexión y volvé a intentar.',
                    action: 'REINTENTAR',
                    onTap: _load,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
