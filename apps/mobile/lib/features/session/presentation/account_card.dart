import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/avatar.dart';
import '../../../common/error_dialog.dart';
import '../../../common/network_failure.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import 'account_panel.dart';
import 'session.dart';

/// El avatar de la cabecera: abre la tarjeta de la cuenta.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    // Las iniciales siguen al perfil, también cuando se edita.
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
      // Con los hijos excluidos, el toque del lector de pantalla tiene que declararse acá.
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

/// Cierra la sesión; si Firebase no la pudo borrar del dispositivo, la persona queda adentro
/// y se le avisa, en vez de mostrarle el login con la sesión todavía guardada.
Future<void> signOut(BuildContext context, Session session) async {
  try {
    await session.close();
  } on Exception {
    if (context.mounted) {
      await showNetworkError(context, const ErrorDelServidor(0));
    }
  }
}

/// `Sheet-Perfil` del prototipo: quién tiene la sesión abierta y sus accesos. Se cierra al
/// tocar afuera sin hacer nada.
///
/// Un administrador sólo ve «Cerrar sesión»: no tiene perfil ni reservas propias.
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
      // Perfil y reservas se apilan sobre el inicio: el atrás del teléfono vuelve a él.
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
