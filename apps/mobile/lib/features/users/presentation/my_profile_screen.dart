// kit-shape: a screen or error family kept with its private parts.
// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/appearance.dart';
import '../../../common/bottom_bar.dart';
import '../../../common/error_dialog.dart';
import '../../../common/network_failure.dart';
import '../../../theme/tokens.dart';
import '../../session/domain/profile.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import 'confirm_deactivation.dart';
import 'my_profile_content.dart';
import 'my_profile_skeleton.dart';

/// «Mi perfil»: all the account data, requested from the API every time it is opened, and
/// the shortcuts to what can be done with it.
class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({
    super.key,
    required this.session,
    required this.appearance,
  });

  final Session session;
  final Appearance appearance;

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  Profile? _profile;
  bool _editing = false;
  bool _loading = true;
  bool _deactivating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_loading) setState(() => _loading = true);
    Object? failure;
    try {
      final profile = await widget.session.refresh();
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
      return;
    } on SessionExpired {
      if (!mounted) {
        // It left the profile while loading: the session that no longer applies is closed
        // anyway, and the routes take it to the login.
        try {
          await widget.session.close();
        } on Exception {
          // If Firebase could not close it, the next request finds it expired again.
        }
        return;
      }
      setState(() => _loading = false);
      await notifySessionExpired(context, widget.session);
      return;
    } on NetworkFailure catch (e) {
      failure = e;
    }
    if (!mounted) return;
    // Without fresh data nothing is shown: neither partial nor old.
    setState(() => _loading = false);
    final outcome = await handleNetworkError(context, failure);
    if (!mounted) return;
    if (outcome == ErrorOutcome.retry) {
      await _load();
    } else if (outcome == ErrorOutcome.closed) {
      context.go('/home');
    }
  }

  Future<void> _confirmDeactivation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: context.palette.bgScrim,
      builder: (context) => const ConfirmDeactivation(),
    );
    if (confirmed == true && mounted) await _deactivate();
  }

  /// If the previous attempt was cut by the network, the server may have finished the
  /// deletion.
  bool _hadCutoff = false;

  Future<void> _deactivate() async {
    if (_deactivating) return;
    setState(() => _deactivating = true);
    Object? failure;
    var expired = false;
    try {
      // If it goes well, the session closes and the routes lead to the login.
      await widget.session.deactivate();
      return;
    } on SessionExpired {
      expired = true;
    } on NetworkFailure catch (e) {
      failure = e;
    } finally {
      if (mounted) setState(() => _deactivating = false);
    }
    if (expired && (_hadCutoff || !mounted)) {
      // A 401 after an outage is the deletion that was already done; and if the person
      // left the screen, the session that does not apply is closed anyway. In both cases,
      // to the login.
      try {
        await widget.session.close();
      } on Exception {
        // The next startup finds it expired and closes it.
      }
      return;
    }
    if (!mounted) return;
    _hadCutoff = failure is NoConnection;
    await notifySendFailure(
      context,
      session: widget.session,
      expired: expired,
      error: failure,
      retry: _deactivate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final profile = _profile;
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: const BottomBar(current: Section.profile),
      body: profile == null
          ? (_loading ? const MyProfileSkeleton() : const SizedBox.shrink())
          : MyProfileContent(
              profile: profile,
              session: widget.session,
              appearance: widget.appearance,
              editing: _editing,
              deactivating: _deactivating,
              onEdit: () => setState(() => _editing = true),
              onSave: (updated) {
                if (!mounted) return;
                setState(() {
                  _profile = updated;
                  _editing = false;
                });
              },
              onConfirmDeactivation: _confirmDeactivation,
            ),
    );
  }
}
