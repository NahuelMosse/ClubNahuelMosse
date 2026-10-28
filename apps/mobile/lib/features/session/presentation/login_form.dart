// kit-shape: a screen or error family kept with its private parts.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/button.dart';
import '../../../common/motion.dart';
import '../../../common/network_failure.dart';
import '../../../common/pending_booking.dart';
import '../../../theme/tokens.dart';
import '../domain/session_exceptions.dart';
import 'load_failure.dart';
import 'login_background.dart';
import 'login_brand.dart';
import 'login_fields.dart';
import 'login_notice.dart';
import 'register_link.dart';
import 'session.dart';

const invalidCredentialsMessage =
    'No se pudo iniciar sesión. Revisá tus datos e intentá de nuevo.';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key, required this.session, required this.pending});

  final Session session;
  final PendingBooking<Object> pending;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _passwordVisible = false;
  bool _submitting = false;
  String? _emailError;
  String? _passwordError;
  String? _notice;

  /// Sube cada vez que aparece el aviso, para que tiemble aunque sea el mismo.
  int _notices = 0;

  @override
  void initState() {
    super.initState();
    _email.addListener(() {
      if (_emailError != null) setState(() => _emailError = null);
    });
    _password.addListener(() {
      if (_passwordError != null) setState(() => _passwordError = null);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_submitting) return;
    final email = _email.text;
    final password = _password.text;
    setState(() {
      _notice = null;
      _emailError = email.trim().isEmpty
          ? 'Completá tu correo electrónico'
          : null;
      _passwordError = password.isEmpty ? 'Completá tu contraseña' : null;
    });
    if (_emailError != null || _passwordError != null) return;

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    Object? failure;
    try {
      final profile = await widget.session.signIn(email, password);
      if (!mounted) return;
      if (widget.pending.isFor(profile.email)) {
        context.go('/reservar', extra: widget.pending.take());
      } else {
        context.go(profile.home);
      }
      return;
    } on InvalidCredentials {
      if (mounted) {
        setState(() {
          _notice = invalidCredentialsMessage;
          _notices++;
        });
      }
    } on FalloDeRed catch (e) {
      failure = e;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    if (failure != null && mounted) {
      final retry = await askRetry(context, failure);
      if (retry && mounted) await _signIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // El fondo no se redimensiona con el teclado: el formulario lo esquiva solo.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      backgroundColor: p.bgBase,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LoginBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                Spacing.s24,
                56,
                Spacing.s24,
                96 + keyboard,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LoginBrand(),
                  const SizedBox(height: Spacing.s24),
                  FadeIn(
                    delay: const Duration(milliseconds: 460),
                    child: LoginFields(
                      email: _email,
                      password: _password,
                      emailError: _emailError,
                      passwordError: _passwordError,
                      passwordVisible: _passwordVisible,
                      submitting: _submitting,
                      onSubmit: _signIn,
                      onToggleVisibility: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                    ),
                  ),
                  const SizedBox(height: Spacing.s24),
                  FadeIn(
                    delay: const Duration(milliseconds: 540),
                    child: PrimaryButton(
                      label: 'INICIAR SESIÓN',
                      loading: _submitting,
                      onTap: _signIn,
                    ),
                  ),
                  const SizedBox(height: Spacing.s24),
                  FadeIn(
                    delay: const Duration(milliseconds: 620),
                    child: RegisterLink(submitting: _submitting),
                  ),
                ],
              ),
            ),
          ),
          LoginNotice(
            notice: _notice,
            notices: _notices,
            onClose: () => setState(() => _notice = null),
          ),
        ],
      ),
    );
  }
}
