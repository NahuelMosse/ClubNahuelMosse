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

/// Mi perfil: todos los datos de la cuenta, pedidos a la API cada vez que se abre, y los
/// accesos a lo que se puede hacer con ella.
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
        // Salió del perfil mientras cargaba: igual se cierra la sesión que ya no vale, y
        // las rutas lo llevan al login.
        try {
          await widget.session.close();
        } on Exception {
          // Si Firebase no la pudo cerrar, el próximo pedido vuelve a encontrarla vencida.
        }
        return;
      }
      setState(() => _loading = false);
      await avisarSesionVencida(context, widget.session);
      return;
    } on FalloDeRed catch (e) {
      failure = e;
    }
    if (!mounted) return;
    // Sin datos frescos no se muestra nada: ni parciales ni viejos.
    setState(() => _loading = false);
    final outcome = await handleNetworkError(context, failure);
    if (!mounted) return;
    if (outcome == ErrorOutcome.retry) {
      await _load();
    } else if (outcome == ErrorOutcome.closed) {
      context.go('/inicio');
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

  /// Si el intento anterior se cortó por la red, el servidor pudo haber terminado la baja.
  bool _hadCutoff = false;

  Future<void> _deactivate() async {
    if (_deactivating) return;
    setState(() => _deactivating = true);
    Object? failure;
    var expired = false;
    try {
      // Si sale bien, la sesión se cierra y las rutas llevan al login.
      await widget.session.deactivate();
      return;
    } on SessionExpired {
      expired = true;
    } on FalloDeRed catch (e) {
      failure = e;
    } finally {
      if (mounted) setState(() => _deactivating = false);
    }
    if (expired && (_hadCutoff || !mounted)) {
      // Un 401 después de un corte es la baja que ya se hizo; y si la persona salió de la
      // pantalla, la sesión que no vale se cierra igual. En los dos casos, al login.
      try {
        await widget.session.close();
      } on Exception {
        // El próximo arranque la encuentra vencida y la cierra.
      }
      return;
    }
    if (!mounted) return;
    _hadCutoff = failure is SinConexion;
    await avisarFalloDeEnvio(
      context,
      session: widget.session,
      expired: expired,
      error: failure,
      reintentar: _deactivate,
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
          ? (_loading
                ? Center(
                    child: Semantics(
                      label: 'Cargando tu perfil',
                      child: CircularProgressIndicator(color: p.accentInk),
                    ),
                  )
                : const SizedBox.shrink())
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
