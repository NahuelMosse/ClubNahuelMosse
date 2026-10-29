// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
// kit-shape: the widget and its State are a single Flutter piece
import 'package:flutter/material.dart';

import '../../../common/bottom_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../../spaces/domain/space.dart';
import '../../spaces/presentation/spaces.dart';
import '../data/api_failures.dart';
import 'admin_card_skeleton.dart';
import 'admin_listing.dart';
import 'admin_listing_header.dart';
import 'admin_space_card.dart';
import 'space_deactivation.dart';

/// «Gestionar espacios» del panel: los espacios activos y el acceso al alta.
class AdminSpacesScreen extends StatefulWidget {
  const AdminSpacesScreen({
    super.key,
    required this.spaces,
    required this.session,
  });

  final Spaces spaces;
  final Session session;

  @override
  State<AdminSpacesScreen> createState() => _AdminSpacesScreenState();
}

class _AdminSpacesScreenState extends State<AdminSpacesScreen> {
  (List<Space>, Catalog)? _data;
  bool _failed = false;

  /// El espacio que se está dando de baja: mientras tanto no se toca ninguna tarjeta.
  String? _deactivatingId;

  @override
  void initState() {
    super.initState();
    // El listado queda debajo del alta: cuando se guarda un espacio, se vuelve a leer.
    widget.spaces.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.spaces.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    Object? error;
    var expired = false;
    try {
      final catalog = await widget.spaces.repository.catalog();
      final spaces = await widget.spaces.repository.active();
      if (mounted) setState(() => _data = (spaces, catalog));
      return;
    } on SessionExpired {
      expired = true;
    } on FalloDeRed catch (e) {
      error = e;
    }
    if (!mounted) return;
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
    final l10n = AppLocalizations.of(context);
    final data = _data;
    return AdminListingTemplate(
      section: AdminSection.spaces,
      title: l10n.adminSpacesTitle,
      session: widget.session,
      createText: l10n.adminAddSpace,
      createRoute: '/admin/espacios/nuevo',
      onRefresh: _load,
      absorbing: _deactivatingId != null,
      hasData: data != null,
      failed: _failed,
      cardShape: AdminCardShape.space,
      items: data == null ? const [] : _items(data.$1, data.$2, p, l10n),
    );
  }

  List<Widget> _items(
    List<Space> spaces,
    Catalog catalog,
    Palette p,
    AppLocalizations l10n,
  ) {
    final venues = {for (final e in spaces) e.venueId}.length;
    return [
      ...adminListingHeader(
        p,
        count: l10n.adminSpacesSummary(spaces.length, venues),
        empty: spaces.isEmpty,
        emptyText: l10n.adminNoSpaces,
      ),
      for (final space in spaces) ...[
        AdminSpaceCard(
          space: space,
          catalog: catalog,
          deactivating: _deactivatingId == space.id,
          enabled: _deactivatingId == null,
          onDeactivate: () => deactivateSpace(
            context,
            space: space,
            spaces: widget.spaces,
            session: widget.session,
            submitting: (inFlight) {
              if (!mounted) return;
              setState(() => _deactivatingId = inFlight ? space.id : null);
            },
          ),
        ),
        const SizedBox(height: Spacing.s12),
      ],
    ];
  }
}
