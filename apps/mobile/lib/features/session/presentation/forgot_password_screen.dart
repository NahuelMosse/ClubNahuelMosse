// kit-shape: a screen or error family kept with its private parts.
// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/button.dart';
import '../../../common/error_dialog.dart';
import '../../../common/network_failure.dart';
import '../../../common/result.dart';
import '../../../common/text_field.dart';
import '../../../common/top_bar.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../users/domain/registration_rules.dart';
import '../data/password_recovery.dart';
import '../domain/recovery_exceptions.dart';

const linkSentNotice =
    'Si el correo está registrado, te enviamos un enlace para crear una contraseña '
    'nueva. El enlace vence en 30 minutos.';

/// Recuperar contraseña: se llega desde «¿Olvidaste tu contraseña?» del login, pide el
/// correo y muestra lo mismo tenga o no cuenta.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.recovery});

  final PasswordRecovery recovery;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _focus = FocusNode();
  bool _touched = false;
  bool _submitting = false;
  bool _sent = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() => _serverError = null));
    _focus.addListener(() {
      if (!_focus.hasFocus && _email.text.isNotEmpty) {
        setState(() => _touched = true);
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _valid => validateEmail(_email.text) == null;

  Future<void> _send() async {
    if (_submitting || !_valid) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    Object? failure;
    try {
      await widget.recovery.requestLink(_email.text.trim().toLowerCase());
      if (mounted) setState(() => _sent = true);
    } on EmailRejected catch (e) {
      if (mounted) setState(() => _serverError = e.message);
    } on FalloDeRed catch (e) {
      failure = e;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    if (failure != null && mounted) {
      final retry = await showNetworkError(context, failure);
      if (retry && mounted) await _send();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return ResultScreen(
        icon: Icons.mail_outline_rounded,
        tone: ResultTone.warning,
        title: 'Revisá tu correo',
        text: linkSentNotice,
        primary: 'VOLVER AL INICIO DE SESIÓN',
        onPrimaryTap: () => context.go('/'),
        secondary: 'Reenviar el correo',
        secondaryLoading: _submitting,
        onSecondaryTap: _send,
      );
    }
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bgBase,
      appBar: TopBar(
        title: 'Recuperar contraseña',
        onBack: () => context.go('/'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.s24,
            Spacing.s8,
            Spacing.s24,
            Spacing.s40,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: Texts.h1.copyWith(color: p.textPrimary),
              ),
            ),
            const SizedBox(height: Spacing.s8),
            Text(
              'Ingresá el correo con el que te registraste y te enviamos un '
              'enlace para crear una nueva.',
              style: Texts.body.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: Spacing.s24),
            FormTextField(
              label: 'CORREO ELECTRÓNICO',
              semanticLabel: 'Correo electrónico',
              placeholder: 'tu@correo.com',
              controller: _email,
              focusNode: _focus,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              enabled: !_submitting,
              error:
                  _serverError ??
                  (_touched ? validateEmail(_email.text) : null),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ActionBar(
        child: PrimaryButton(
          label: 'ENVIAR ENLACE',
          loading: _submitting,
          onTap: _valid ? _send : null,
        ),
      ),
    );
  }
}
