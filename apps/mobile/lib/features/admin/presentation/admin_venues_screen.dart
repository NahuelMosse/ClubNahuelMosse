// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
// kit-shape: the widget and its State are a single Flutter piece
import 'package:flutter/material.dart';

import '../../../common/bottom_bar.dart';
import '../../../theme/tokens.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../../venues/domain/venue.dart';
import '../../venues/presentation/venues.dart';
import '../data/api_failures.dart';
import 'admin_card_skeleton.dart';
import 'admin_listing.dart';
import 'admin_listing_header.dart';
import 'admin_venue_card.dart';
import 'venue_deactivation.dart';

/// «Gestionar sedes» del panel: las sedes activas y el acceso a dar de alta una nueva.
class AdminVenuesScreen extends StatefulWidget {
  const AdminVenuesScreen({
    super.key,
    required this.venues,
    required this.session,
  });

  final Venues venues;
  final Session session;

  @override
  State<AdminVenuesScreen> createState() => _AdminVenuesScreenState();
}

class _AdminVenuesScreenState extends State<AdminVenuesScreen> {
  List<Venue>? _venues;
  bool _failed = false;

  /// La sede que se está dando de baja: mientras tanto no se toca ninguna tarjeta.
  String? _deactivatingId;

  @override
  void initState() {
    super.initState();
    // El listado queda debajo del alta: cuando se guarda una sede, se vuelve a leer.
    widget.venues.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.venues.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    Object? error;
    var expired = false;
    try {
      final venues = await widget.venues.repository.active();
      if (mounted) setState(() => _venues = venues);
      return;
    } on SessionExpired {
      expired = true;
    } on FalloDeRed catch (e) {
      error = e;
    }
    if (!mounted) return;
    // Sin datos que mostrar, la pantalla deja de esperar antes del aviso.
    setState(() => _failed = true);
    await avisarFalloDeCarga(
      context,
      session: widget.session,
      expired: expired,
      error: error,
      reintentar: _load,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final venues = _venues;
    return AdminListingTemplate(
      section: AdminSection.venues,
      title: 'Sedes',
      session: widget.session,
      createText: 'AGREGAR SEDE',
      createRoute: '/admin/sedes/nueva',
      onRefresh: _load,
      absorbing: _deactivatingId != null,
      hasData: venues != null,
      failed: _failed,
      cardShape: AdminCardShape.venue,
      items: venues == null ? const [] : _items(venues, p),
    );
  }

  List<Widget> _items(List<Venue> venues, Palette p) => [
    ...adminListingHeader(
      p,
      count: venues.length == 1
          ? '1 SEDE ACTIVA'
          : '${venues.length} SEDES ACTIVAS',
      empty: venues.isEmpty,
      emptyText: 'Todavía no hay sedes',
    ),
    for (final venue in venues) ...[
      AdminVenueCard(
        venue: venue,
        deactivating: _deactivatingId == venue.id,
        enabled: _deactivatingId == null,
        onDeactivate: () => deactivateVenue(
          context,
          venue: venue,
          venues: widget.venues,
          session: widget.session,
          submitting: (inFlight) {
            if (!mounted) return;
            setState(() => _deactivatingId = inFlight ? venue.id : null);
          },
        ),
      ),
      const SizedBox(height: Spacing.s16),
    ],
  ];
}
