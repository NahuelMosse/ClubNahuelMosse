import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import 'notification_center.dart';

/// La campana de la cabecera: abre el centro de notificaciones y cuenta las que no se leyeron.
/// Va sobre la foto de la portada, así que el ícono usa el color sobre foto en los dos modos.
class NotificationsButton extends StatelessWidget {
  const NotificationsButton({super.key, required this.center});

  final NotificationCenter center;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: center,
    builder: (context, _) {
      final p = context.palette;
      final l10n = AppLocalizations.of(context);
      final unread = center.unread;
      void open() => context.push('/notificaciones');
      return Semantics(
        container: true,
        button: true,
        label: unread == 0
            ? l10n.notificationsTitle
            : l10n.notificationsBellUnread(unread),
        onTap: open,
        excludeSemantics: true,
        child: InkResponse(
          onTap: open,
          radius: Spacing.controlHeight / 2,
          child: SizedBox.square(
            dimension: Spacing.controlHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 26,
                  color: p.textOnMedia,
                ),
                if (unread > 0)
                  Positioned(
                    top: Spacing.s8,
                    right: Spacing.s4,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: p.accentBase,
                        borderRadius: BorderRadius.circular(Spacing.radiusPill),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: Texts.overline.copyWith(color: p.accentOn),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
