// kit-shape: a screen or error family kept with its private parts.
// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/bottom_bar.dart';
import '../../../common/error_dialog.dart';
import '../../../common/network_failure.dart';
import '../../../common/skeleton.dart';
import '../../../theme/tokens.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../../spaces/domain/space.dart';
import '../../spaces/presentation/spaces.dart';
import '../domain/venue.dart';
import 'venue_content.dart';
import 'venues.dart';

/// Una sede con todas sus canchas, cada una con sus datos y el paso a los horarios.
class VenueScreen extends StatefulWidget {
  const VenueScreen({
    super.key,
    required this.venueId,
    required this.venues,
    required this.spaces,
    required this.session,
  });

  final String venueId;
  final Venues venues;
  final Spaces spaces;
  final Session session;

  @override
  State<VenueScreen> createState() => _VenueScreenState();
}

class _VenueScreenState extends State<VenueScreen> {
  (Venue, List<Space>, Catalog)? _data;
  bool _loading = true;

  /// El filtro de CU-20: el deporte y el tipo elegidos, las canchas que quedan y los tipos
  /// que ofrece ese deporte en la sede.
  String? _sport;
  String? _kind;
  List<Space>? _filtered;
  List<String> _sportKinds = const [];
  bool _filtering = false;

  /// Cada lectura o filtro toma un número; la respuesta de uno que ya no es el último se
  /// descarta, así una recarga vieja no pisa un filtro nuevo.
  int _request = 0;

  @override
  void initState() {
    super.initState();
    // Los horarios de una cancha pueden avisar que ya no está: se vuelve a leer.
    widget.spaces.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.spaces.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    // El filtro que se vuelve a pedir es el que había al empezar.
    final sportBefore = _sport;
    final kindBefore = _kind;
    setState(() => _loading = true);
    Object? failure;
    var expired = false;
    try {
      final catalog = await widget.spaces.repository.catalog();
      final venues = await widget.venues.repository.active();
      final venue = venues.where((s) => s.id == widget.venueId).firstOrNull;
      if (venue == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        await showChangedMeanwhile(context);
        if (!mounted) return;
        widget.venues.notifyChange();
        context.go('/sedes');
        return;
      }
      final spaces = await widget.spaces.repository.active(venueId: venue.id);
      // El filtro elegido sigue, salvo que su deporte o su tipo ya no tengan canchas.
      final sport = spaces.any((c) => c.sport == sportBefore)
          ? sportBefore
          : null;
      final bySport = sport == null
          ? null
          : await widget.spaces.repository.active(
              venueId: venue.id,
              sport: sport,
            );
      final kinds = bySport == null
          ? const <String>[]
          : _kindsInOrder(bySport, catalog, sport);
      final kind = kinds.contains(kindBefore) ? kindBefore : null;
      final byKind = sport == null || kind == null
          ? bySport
          : await widget.spaces.repository.active(
              venueId: venue.id,
              sport: sport,
              kind: kind,
            );
      if (!mounted || request != _request) return;
      setState(() {
        _data = (venue, spaces, catalog);
        _sport = sport;
        _kind = kind;
        _filtered = byKind;
        _sportKinds = kinds;
        _loading = false;
      });
      return;
    } on SessionExpired {
      expired = true;
    } on FalloDeRed catch (e) {
      failure = e;
    }
    if (!mounted || request != _request) return;
    // Sin datos frescos no se muestra nada: ni parciales ni viejos.
    setState(() {
      _data = null;
      _loading = false;
    });
    if (ModalRoute.of(context)?.isCurrent == false) return;
    if (expired) {
      await avisarSesionVencida(context, widget.session);
    } else if (failure != null) {
      final outcome = await handleNetworkError(context, failure);
      if (!mounted) return;
      if (outcome == ErrorOutcome.retry) {
        await _load();
      } else if (outcome == ErrorOutcome.closed && _data == null) {
        context.go('/sedes');
      }
    }
  }

  /// Los tipos de [deporte] que tienen canchas, en el orden del catálogo.
  static List<String> _kindsInOrder(
    List<Space> spaces,
    Catalog catalog,
    String? sport,
  ) {
    final present = {for (final c in spaces) c.kind};
    return [
      for (final t in catalog.sport(sport ?? '')?.kinds ?? const <SpaceKind>[])
        if (present.contains(t.key)) t.key,
    ];
  }

  /// Pide a la API las canchas con ese [deporte] y [tipo]; si falla, avisa y todo queda
  /// como estaba.
  Future<void> _applyFilter({
    required String? sport,
    required String? kind,
  }) async {
    final data = _data;
    if (data == null || _filtering || _loading) return;
    final request = ++_request;
    setState(() => _filtering = true);
    Object? failure;
    var expired = false;
    try {
      // Sin deporte también se pregunta: la sede pudo sumar canchas o deportes.
      final spaces = await widget.spaces.repository.active(
        venueId: data.$1.id,
        sport: sport,
        kind: kind,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _sport = sport;
        _kind = kind;
        if (sport == null) {
          _data = (data.$1, spaces, data.$3);
          _filtered = null;
          _sportKinds = const [];
        } else {
          _filtered = spaces;
          // Sin tipo elegido la respuesta trae todos los del deporte, nuevos incluidos.
          if (kind == null) {
            _sportKinds = _kindsInOrder(spaces, data.$3, sport);
          }
        }
      });
    } on SessionExpired {
      expired = true;
    } on FalloDeRed catch (e) {
      failure = e;
    } finally {
      if (mounted) setState(() => _filtering = false);
    }
    if (!mounted || request != _request) return;
    await avisarFalloDeEnvio(
      context,
      session: widget.session,
      expired: expired,
      error: failure,
      reintentar: () => _applyFilter(sport: sport, kind: kind),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final data = _data;
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: const BottomBar(
        current: Section.venues,
        atRoot: false,
      ),
      body: data == null
          ? SafeArea(
              child: _loading
                  ? const Padding(
                      padding: Spacing.listPagePadding,
                      child: SkeletonList(shape: SkeletonShape.space),
                    )
                  : const SizedBox.shrink(),
            )
          : VenueContent(
              venue: data.$1,
              spaces: _filtered ?? data.$2,
              allSpaces: data.$2,
              catalog: data.$3,
              sport: _sport,
              kind: _kind,
              sportKinds: _sportKinds,
              enabled: !_filtering && !_loading,
              filtering: _filtering,
              // Tocar el deporte elegido lo quita; «Todos» quita el tipo.
              onSportSelected: (d) =>
                  _applyFilter(sport: d == _sport ? null : d, kind: null),
              onKindSelected: (t) => _applyFilter(sport: _sport, kind: t),
            ),
    );
  }
}
