// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'fixed_bar.dart';

enum Section {
  home(Icons.home_outlined, '/inicio'),
  venues(Icons.place_outlined, '/sedes'),
  bookings(Icons.calendar_today_outlined, '/reservas'),
  profile(Icons.person_outline_rounded, '/perfil');

  const Section(this.icon, this.route);
  final IconData icon;
  final String route;

  String title(AppLocalizations l10n) => switch (this) {
    home => l10n.navHome,
    venues => l10n.navVenues,
    bookings => l10n.navBookings,
    profile => l10n.navProfile,
  };
}

/// The three tabs of the admin panel (`BottomNav-Admin`).
enum AdminSection {
  bookings(Icons.calendar_today_outlined, '/admin'),
  venues(Icons.place_outlined, '/admin/sedes'),
  spaces(Icons.grid_view_outlined, '/admin/espacios');

  const AdminSection(this.icon, this.route);
  final IconData icon;
  final String route;

  String title(AppLocalizations l10n) => switch (this) {
    bookings => l10n.navBookings,
    venues => l10n.navVenues,
    spaces => l10n.navSpaces,
  };
}

/// The user `BottomNav`: four fixed tabs, the current section in lime.
class BottomBar extends StatelessWidget {
  const BottomBar({super.key, required this.current, this.atRoot = true});

  final Section current;

  /// `false` inside a section (a venue, its schedules): the active tab goes back to the
  /// start of the section.
  final bool atRoot;

  @override
  Widget build(BuildContext context) => _Bar(
    tabs: [
      for (final s in Section.values)
        _Tab(
          title: s.title(AppLocalizations.of(context)),
          icon: s.icon,
          active: s == current,
          tappable: s != current || !atRoot,
          onTap: () => context.go(s.route),
        ),
    ],
  );
}

/// `BottomNav-Admin`: Bookings, Venues and Spaces.
class AdminBar extends StatelessWidget {
  const AdminBar({super.key, required this.current});

  final AdminSection current;

  @override
  Widget build(BuildContext context) => _Bar(
    tabs: [
      for (final s in AdminSection.values)
        _Tab(
          title: s.title(AppLocalizations.of(context)),
          icon: s.icon,
          active: s == current,
          tappable: s != current,
          onTap: () => context.go(s.route),
        ),
    ],
  );
}

class _Bar extends StatelessWidget {
  const _Bar({required this.tabs});

  final List<_Tab> tabs;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return FixedBar(
      color: p.bgSurfaceRaised,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s8,
        vertical: Spacing.s8,
      ),
      child: Row(children: [for (final tab in tabs) Expanded(child: tab)]),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.title,
    required this.icon,
    required this.active,
    required this.tappable,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool active;
  final bool tappable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = active ? p.accentInk : p.textMuted;
    return Semantics(
      button: true,
      selected: active,
      child: InkResponse(
        onTap: tappable ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Spacing.controlHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: Spacing.s4),
              // With large text the label shrinks until it fits.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: Texts.overline.copyWith(color: color),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
