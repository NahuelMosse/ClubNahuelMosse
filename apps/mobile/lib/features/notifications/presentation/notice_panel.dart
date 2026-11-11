// kit-shape: a screen or error family kept with its private parts.
import 'package:flutter/material.dart';

import '../../../common/clock.dart';
import '../../../common/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../domain/app_notification.dart';
import 'notice_card.dart';
import 'notification_center.dart';
import 'panel_header.dart';

/// `Notificaciones in-app (overlay)`: with the app open, a panel on top with the unread
/// notifications and «MARCAR TODAS». It is a modal route of the navigator: the screen
/// reader does not reach what is below, the system back closes it and tapping outside
/// closes it without marking anything.
///
/// The widget draws nothing: it opens and closes the route according to [center].
class NoticePanel extends StatefulWidget {
  const NoticePanel({
    super.key,
    required this.center,
    required this.onOpen,
    this.navigator,
    this.now = clubNow,
  });

  final NotificationCenter center;

  /// What happens on tapping a notice: take it to what it announces.
  final void Function(AppNotification) onOpen;

  /// The navigator where it opens. If the widget is above the `Navigator` (in the app's
  /// `builder`), its key is needed; below it, the nearest one is used.
  final GlobalKey<NavigatorState>? navigator;
  final DateTime Function() now;

  @override
  State<NoticePanel> createState() => _NoticePanelState();
}

class _NoticePanelState extends State<NoticePanel> {
  NavigatorState? _navigator;
  Route<void>? _route;

  @override
  void initState() {
    super.initState();
    widget.center.addListener(_check);
    // The center may have opened the panel before this widget existed.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didUpdateWidget(NoticePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.center != widget.center) {
      oldWidget.center.removeListener(_check);
      widget.center.addListener(_check);
    }
  }

  @override
  void dispose() {
    widget.center.removeListener(_check);
    _closeRoute();
    super.dispose();
  }

  void _check() {
    if (!mounted) return;
    final open = _route?.isActive ?? false;
    if (widget.center.panelOpen && !open) {
      _openRoute();
    } else if (!widget.center.panelOpen && open) {
      _closeRoute();
    }
  }

  void _openRoute() {
    final navigator =
        widget.navigator?.currentState ?? Navigator.maybeOf(context);
    if (navigator == null) return;
    final palette = context.palette;
    final route = RawDialogRoute<void>(
      barrierDismissible: true,
      barrierLabel: AppLocalizations.of(context).notificationsCloseLabel,
      barrierColor: palette.bgScrim,
      transitionDuration: Duration.zero,
      pageBuilder: (context, _, _) => _PanelContent(
        center: widget.center,
        onOpen: widget.onOpen,
        now: widget.now,
      ),
    );
    _navigator = navigator;
    _route = route;
    // However it closes —tapping outside, the system back, a notice—, the center stops
    // having the panel open.
    route.popped.then((_) {
      if (identical(_route, route)) _route = null;
      widget.center.closePanel();
    });
    navigator.push(route);
  }

  void _closeRoute() {
    final route = _route;
    if (route != null && route.isActive) _navigator?.removeRoute(route);
    _route = null;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _PanelContent extends StatelessWidget {
  const _PanelContent({
    required this.center,
    required this.onOpen,
    required this.now,
  });

  final NotificationCenter center;
  final void Function(AppNotification) onOpen;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: center,
    builder: (context, _) {
      final p = context.palette;
      final metrics = MediaQuery.of(context);
      final list = center.inPanel;
      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.s16,
              Spacing.s12,
              Spacing.s16,
              0,
            ),
            child: FadeIn(
              duration: const Duration(milliseconds: 600),
              fromY: -150,
              curve: AppMotion.bounce,
              child: Material(
                color: p.bgSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Spacing.radiusLg),
                  side: BorderSide(color: p.borderDefault),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: metrics.size.height * 0.7,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.s12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PanelHeader(onMarkAll: center.markAll),
                        const SizedBox(height: Spacing.s4),
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: list.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: Spacing.s8),
                            itemBuilder: (context, i) => NoticeCard(
                              notification: list[i],
                              now: now(),
                              onTap: () => onOpen(list[i]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
