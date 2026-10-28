import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/button.dart';
import '../../../common/clock.dart';
import '../../../common/empty_state.dart';
import '../../../common/network_failure.dart';
import '../../../common/skeleton.dart';
import '../../../common/top_bar.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../domain/app_notification.dart';
import 'notice_card.dart';
import 'notification_center.dart';
import 'notifications_disabled.dart';

/// `Centro de notificaciones`: las notificaciones agrupadas por día, con las sin leer
/// marcadas. Sin permiso del sistema, dice «Notificaciones desactivadas» y ofrece activarlas.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.center,
    required this.session,
    required this.onOpen,
    this.now = clubNow,
  });

  final NotificationCenter center;
  final Session session;

  /// Lo que pasa al tocar una notificación: llevarla a lo que avisa.
  final void Function(BuildContext, AppNotification) onOpen;
  final DateTime Function() now;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;

  /// La lectura de esta visita salió bien: hasta entonces un centro vacío sería un dato viejo.
  bool _read = false;

  /// La lectura falló y ya se avisó: queda REINTENTAR en lugar de la lista.
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    Object? failure;
    var expired = false;
    try {
      await widget.center.load();
      if (mounted) {
        setState(() {
          _loading = false;
          _read = true;
        });
      }
      return;
    } on SessionExpired {
      expired = true;
    } on FalloDeRed catch (e) {
      failure = e;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    await avisarFalloDeEnvio(
      context,
      session: widget.session,
      expired: expired,
      error: failure,
      reintentar: _load,
      alNoReintentar: () => setState(() => _failed = true),
    );
  }

  /// Al salir se dan por leídas las que se mostraron; mientras está abierto siguen sin leer
  /// para que se distingan. Va en un microtask: no se avisa a nadie en medio del desmontaje.
  @override
  void dispose() {
    final center = widget.center;
    if (center.unread > 0 || center.unreadList.isNotEmpty) {
      scheduleMicrotask(center.markAll);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListenableBuilder(
      listenable: widget.center,
      builder: (context, _) {
        final center = widget.center;
        final noNotices = _read && center.list.isEmpty;
        final disabled = !center.allowed;
        return Scaffold(
          backgroundColor: p.bgBase,
          appBar: TopBar(
            title: 'Notificaciones',
            onBack: () =>
                context.canPop() ? context.pop() : context.go('/inicio'),
          ),
          bottomNavigationBar: disabled && noNotices
              ? ActionBar(
                  child: PrimaryButton(
                    label: 'ACTIVAR NOTIFICACIONES',
                    onTap: center.enable,
                  ),
                )
              : null,
          body: SafeArea(child: _body(context, center, noNotices)),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    NotificationCenter center,
    bool noNotices,
  ) {
    if (!_read && center.list.isEmpty) {
      if (_loading) {
        return const Padding(
          padding: EdgeInsets.all(Spacing.s24),
          child: SkeletonList(shape: SkeletonShape.notice, count: 5),
        );
      }
      // Con el aviso de error abierto no hay nada más que mostrar: el reintento es el del aviso.
      return _failed
          ? Center(
              child: TextActionButton(label: 'REINTENTAR', onTap: _load),
            )
          : const SizedBox.shrink();
    }
    if (noNotices) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.s24),
        child: center.allowed
            ? const EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'Todavía no tenés notificaciones',
                text: 'Acá vas a ver los recordatorios de tus reservas.',
              )
            : const EmptyState(
                icon: Icons.notifications_none_rounded,
                title: disabledTitle,
                text: disabledText,
              ),
      );
    }
    final now = widget.now();
    final groups = groupByDay(center.list, now);
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.s24,
        Spacing.s8,
        Spacing.s24,
        Spacing.s40,
      ),
      children: [
        if (!center.allowed) ...[
          NotificationsDisabled(onEnable: center.enable),
          const SizedBox(height: Spacing.s16),
        ],
        for (final group in groups) ...[
          Semantics(
            header: true,
            child: Padding(
              padding: const EdgeInsets.only(
                top: Spacing.s8,
                bottom: Spacing.s12,
              ),
              child: Text(
                group.label,
                style: Texts.overline.copyWith(color: p.textMuted),
              ),
            ),
          ),
          for (final n in group.notifications) ...[
            NoticeCard(
              notification: n,
              now: now,
              onTap: () {
                center.markRead(n);
                widget.onOpen(context, n);
              },
            ),
            const SizedBox(height: Spacing.s12),
          ],
        ],
      ],
    );
  }
}
