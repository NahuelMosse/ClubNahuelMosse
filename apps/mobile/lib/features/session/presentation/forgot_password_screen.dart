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
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../users/domain/registration_rules.dart';
import '../../users/presentation/field_problem_text.dart';
import '../data/password_recovery.dart';
import '../domain/recovery_exceptions.dart';

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

  String? _emailError(AppLocalizations l10n) {
    final problem = validateEmail(_email.text);
    return problem == null ? null : fieldProblemText(l10n, problem);
  }

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
    final l10n = AppLocalizations.of(context);
    if (_sent) {
      return ResultScreen(
        icon: Icons.mail_outline_rounded,
        tone: ResultTone.warning,
        title: l10n.recoveryCheckEmail,
        text: l10n.recoveryLinkSent,
        primary: l10n.accountBackToSignIn,
        onPrimaryTap: () => context.go('/'),
        secondary: l10n.recoveryResend,
        secondaryLoading: _submitting,
        onSecondaryTap: _send,
      );
    }
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bgBase,
      appBar: TopBar(title: l10n.recoveryTitle, onBack: () => context.go('/')),
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
                l10n.loginForgotPassword,
                style: Texts.h1.copyWith(color: p.textPrimary),
              ),
            ),
            const SizedBox(height: Spacing.s8),
            Text(
              l10n.recoveryIntro,
              style: Texts.body.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: Spacing.s24),
            FormTextField(
              label: l10n.profileEmailUpper,
              semanticLabel: l10n.profileEmail,
              placeholder: l10n.profileEmailPlaceholder,
              controller: _email,
              focusNode: _focus,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              enabled: !_submitting,
              error: _serverError ?? (_touched ? _emailError(l10n) : null),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ActionBar(
        child: PrimaryButton(
          label: l10n.recoverySend,
          loading: _submitting,
          onTap: _valid ? _send : null,
        ),
      ),
    );
  }
}
