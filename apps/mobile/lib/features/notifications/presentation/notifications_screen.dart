// kit-shape: a screen or error family kept with its private parts.
// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/button.dart';
import '../../../common/clock.dart';
import '../../../common/empty_state.dart';
import '../../../common/network_failure.dart';
import '../../../common/top_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../domain/app_notification.dart';
import 'arrival_text.dart';
import 'notice_card.dart';
import 'notice_card_skeleton.dart';
import 'notification_center.dart';
import 'notifications_disabled.dart';

/// `Centro de notificaciones`: the notifications grouped by day, with the unread ones
/// marked. Without the system permission, it says «Notificaciones desactivadas» and
/// offers to enable them.
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

  /// What happens on tapping a notification: take it to what it announces.
  final void Function(BuildContext, AppNotification) onOpen;
  final DateTime Function() now;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;

  /// The read of this visit went well: until then an empty center would be stale data.
  bool _read = false;

  /// The read failed and was already reported: «REINTENTAR» stays in place of the list.
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
    } on NetworkFailure catch (e) {
      failure = e;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    await notifySendFailure(
      context,
      session: widget.session,
      expired: expired,
      error: failure,
      retry: _load,
      onGiveUp: () => setState(() => _failed = true),
    );
  }

  /// On leaving, the ones that were shown are marked as read; while open they stay unread
  /// so they can be told apart. It goes in a microtask: nobody is notified in the middle
  /// of the teardown.
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
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: widget.center,
      builder: (context, _) {
        final center = widget.center;
        final noNotices = _read && center.list.isEmpty;
        final disabled = !center.allowed;
        return Scaffold(
          backgroundColor: p.bgBase,
          appBar: TopBar(
            title: l10n.notificationsTitle,
            onBack: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
          bottomNavigationBar: disabled && noNotices
              ? ActionBar(
                  child: PrimaryButton(
                    label: l10n.notificationsEnable,
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
    final l10n = AppLocalizations.of(context);
    if (!_read && center.list.isEmpty) {
      if (_loading) return const NoticeCardSkeleton();
      // With the error notice open there is nothing else to show: the retry is the
      // notice's.
      return _failed
          ? Center(
              child: TextActionButton(label: l10n.commonRetry, onTap: _load),
            )
          : const SizedBox.shrink();
    }
    if (noNotices) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.s24),
        child: center.allowed
            ? EmptyState(
                icon: Icons.notifications_none_rounded,
                title: l10n.notificationsEmptyTitle,
                text: l10n.notificationsEmptyText,
              )
            : EmptyState(
                icon: Icons.notifications_none_rounded,
                title: l10n.notificationsDisabledTitle,
                text: l10n.notificationsDisabledText,
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
                arrivalText(l10n, group.arrival),
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
