// kit-shape: a screen or error family kept with its private parts.
import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/app_notification.dart';
import '../domain/notification_kind.dart';

/// `Push-Notification` del prototipo: el ícono del tipo, «CLUBNAHUELMOSSE · cuándo», el título
/// y el cuerpo. Sin leer lleva un punto de acento.
class NoticeCard extends StatelessWidget {
  const NoticeCard({
    super.key,
    required this.notification,
    required this.now,
    required this.onTap,
  });

  final AppNotification notification;

  /// La hora del club con la que se cuenta el «hace cuánto».
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = notification;
    final when = arrivedLabel(n.createdAt, now);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Spacing.radiusLg),
      side: BorderSide(color: p.borderDefault),
    );
    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: '${n.title}. ${n.body}. $when${n.read ? '' : ', sin leer'}',
      onTap: onTap,
      child: Material(
        color: p.bgSurfaceRaised,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.s12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Icon(kind: n.kind),
                const SizedBox(width: Spacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CLUBNAHUELMOSSE · $when',
                        style: Texts.overline.copyWith(color: p.textMuted),
                      ),
                      const SizedBox(height: Spacing.s4),
                      Text(
                        n.title,
                        style: Texts.bodyStrong.copyWith(color: p.textPrimary),
                      ),
                      const SizedBox(height: Spacing.s4),
                      Text(
                        n.body,
                        style: Texts.caption.copyWith(color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (!n.read) ...[
                  const SizedBox(width: Spacing.s8),
                  Padding(
                    padding: const EdgeInsets.only(top: Spacing.s4),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: p.accentInk,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: 8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El ícono del tipo: lima el recordatorio, verde la confirmación, rojo la alerta.
class _Icon extends StatelessWidget {
  const _Icon({required this.kind});

  final NotificationKind kind;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (background, color, icon) = switch (kind) {
      NotificationKind.reminder || NotificationKind.fiveMinuteReminder => (
        p.accentBase,
        p.accentOn,
        Icons.schedule_rounded,
      ),
      NotificationKind.userCancellation => (
        p.stateSuccessMuted,
        p.stateSuccessInk,
        Icons.check_circle_outline_rounded,
      ),
      NotificationKind.forcedCancellation => (
        p.stateDangerMuted,
        p.stateDangerInk,
        Icons.warning_amber_rounded,
      ),
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Spacing.radiusMd),
      ),
      child: Icon(icon, size: 22, color: color),
    );
  }
}
