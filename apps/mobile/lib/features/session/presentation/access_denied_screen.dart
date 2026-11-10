// kit-shape: a screen or error family kept with its private parts.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import 'account_card.dart';
import 'session.dart';

/// Whoever asks for an admin section without being one (CU-14 FA4), through a link to the
/// panel or through a 403 from the API. Every route under `/admin` without the role
/// arrives here.
///
/// A 403 may come from a role that changed after signing in: the screen reads the profile
/// again and only then leads to «Mis reservas», so the stored role does not send it back
/// to the panel. «Cerrar sesión» is the exit for whoever has nowhere to go.
class AccessDeniedScreen extends StatefulWidget {
  const AccessDeniedScreen({super.key, required this.session});

  final Session session;

  @override
  State<AccessDeniedScreen> createState() => _AccessDeniedScreenState();
}

class _AccessDeniedScreenState extends State<AccessDeniedScreen> {
  late final Future<void> _profile;

  @override
  void initState() {
    super.initState();
    // Outside the build: re-reading the profile notifies whoever listens to the session.
    _profile = Future.microtask(_reread);
  }

  Future<void> _reread() async {
    try {
      await widget.session.refresh();
    } on Exception {
      // Without network or with the session expired it continues with the profile it had;
      // what fails afterwards is handled by the screen that is reached.
    }
  }

  Future<void> _goToMyBookings() async {
    await _profile;
    if (mounted) context.go('/bookings');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: p.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.s24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: p.stateDangerMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.block_rounded,
                  size: 28,
                  color: p.stateDangerInk,
                ),
              ),
              const SizedBox(height: Spacing.s16),
              Semantics(
                header: true,
                child: Text(
                  l10n.accessDeniedTitle,
                  textAlign: TextAlign.center,
                  style: Texts.h2.copyWith(color: p.textPrimary),
                ),
              ),
              const SizedBox(height: Spacing.s8),
              Text(
                l10n.accessDeniedBody,
                textAlign: TextAlign.center,
                style: Texts.body.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: Spacing.s24),
              PrimaryButton(
                label: l10n.accessDeniedGoToBookings,
                onTap: _goToMyBookings,
              ),
              const SizedBox(height: Spacing.s8),
              TextActionButton(
                label: l10n.accountSignOut,
                onTap: () => signOut(context, widget.session),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
