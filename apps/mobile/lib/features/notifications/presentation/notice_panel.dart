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

/// `Notificaciones in-app (overlay)`: con la app abierta, un panel arriba con las
/// notificaciones sin leer y «MARCAR TODAS». Es una ruta modal del navegador: el lector de
/// pantalla no llega a lo que queda abajo, el atrás del sistema lo cierra y tocar afuera lo
/// cierra sin marcar nada.
///
/// El widget no dibuja nada: abre y cierra la ruta según [center].
class NoticePanel extends StatefulWidget {
  const NoticePanel({
    super.key,
    required this.center,
    required this.onOpen,
    this.navigator,
    this.now = clubNow,
  });

  final NotificationCenter center;

  /// Lo que pasa al tocar un aviso: llevarlo a lo que avisa.
  final void Function(AppNotification) onOpen;

  /// El navegador donde se abre. Si el widget está arriba del `Navigator` (en el `builder` de la
  /// app), hace falta su llave; debajo de él, se usa el más cercano.
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
    // El centro pudo haber abierto el panel antes de que este widget existiera.
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
    // Se cierre como se cierre —tocando afuera, el atrás del sistema, un aviso—, el centro
    // deja de tener el panel abierto.
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
