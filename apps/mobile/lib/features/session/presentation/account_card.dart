import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/avatar.dart';
import '../../../common/error_dialog.dart';
import '../../../common/network_failure.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import 'account_panel.dart';
import 'session.dart';

/// The avatar of the header: opens the account card.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    // The initials follow the profile, also when it is edited.
    listenable: session,
    builder: (context, _) => _avatar(context),
  );

  Widget _avatar(BuildContext context) {
    final profile = session.profile;
    if (profile == null) return const SizedBox.shrink();
    void open() => showAccountCard(context, session);
    return Semantics(
      container: true,
      button: true,
      label: AppLocalizations.of(context).accountTitle,
      // With the children excluded, the screen reader's tap has to be declared here.
      onTap: open,
      excludeSemantics: true,
      child: InkResponse(
        onTap: open,
        radius: AvatarSize.small.side / 2 + Spacing.s4,
        child: SizedBox.square(
          dimension: Spacing.controlHeight,
          child: Center(
            child: AvatarInitials(
              firstName: profile.firstName,
              lastName: profile.lastName,
              size: AvatarSize.small,
            ),
          ),
        ),
      ),
    );
  }
}

/// Signs out; if Firebase could not delete the session from the device, the person stays
/// in and is told, instead of being shown the login with the session still stored.
Future<void> signOut(BuildContext context, Session session) async {
  try {
    await session.close();
  } on Exception {
    if (context.mounted) {
      await showNetworkError(context, const ServerError(0));
    }
  }
}

/// `Sheet-Perfil` of the prototype: who has the session open and their shortcuts. It
/// closes on tapping outside without doing anything.
///
/// An administrator only sees «Cerrar sesión»: they have no profile or bookings of their
/// own.
Future<void> showAccountCard(BuildContext context, Session session) {
  final profile = session.profile;
  if (profile == null) return Future.value();
  final origin = context;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: AppLocalizations.of(context).accountCloseCard,
    barrierColor: context.palette.bgScrim,
    pageBuilder: (context, _, _) {
      // Profile and bookings stack on top of the home: the phone's back returns to it.
      void goTo(String route) {
        Navigator.of(context).pop();
        GoRouter.of(origin).push(route);
      }

      return SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.s16,
              72,
              Spacing.s16,
              Spacing.s16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: AccountPanel(
                profile: profile,
                onNavigate: goTo,
                onSignOut: () {
                  Navigator.of(context).pop();
                  signOut(origin, session);
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}
