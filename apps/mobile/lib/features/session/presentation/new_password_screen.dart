// kit-shape: a screen or error family kept with its private parts.
// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/error_dialog.dart';
import '../../../common/network_failure.dart';
import '../../../common/password_form.dart';
import '../../../common/result.dart';
import '../../../common/text_field.dart';
import '../../../common/top_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../users/domain/registration_rules.dart';
import '../../users/presentation/password_rules.dart';
import '../data/password_recovery.dart';
import '../domain/recovery_exceptions.dart';
import '../domain/session_exceptions.dart';
import 'account_card.dart';
import 'load_failure.dart';
import 'session.dart';

enum _Stage { checking, form, invalid, done }

/// La contraseña nueva, adonde abre el enlace del correo de recuperación.
class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({
    super.key,
    required this.recovery,
    required this.session,
    required this.code,
  });

  final PasswordRecovery recovery;

  /// Si el enlace se abre con una sesión iniciada, esa sesión ya no vale al terminar.
  final Session session;
  final String code;

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _newPassword = TextEditingController();
  final _repeated = TextEditingController();
  final _repeatedFocus = FocusNode();
  final _visible = <TextEditingController>{};
  var _stage = _Stage.checking;
  bool _submitting = false;
  bool _hadNetworkFailure = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    var previous = '';
    _newPassword.addListener(() {
      if (_newPassword.text == previous) return;
      previous = _newPassword.text;
      setState(() => _serverError = null);
    });
    _repeated.addListener(() => setState(() {}));
    _repeatedFocus.addListener(() => setState(() {}));
    _check();
  }

  @override
  void dispose() {
    _newPassword.dispose();
    _repeated.dispose();
    _repeatedFocus.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() => _stage = _Stage.checking);
    Object? failure;
    try {
      final valid = await widget.recovery.isValid(widget.code);
      if (mounted) {
        setState(() => _stage = valid ? _Stage.form : _Stage.invalid);
      }
    } on FalloDeRed catch (e) {
      failure = e;
    }
    if (failure != null && mounted) {
      final result = await handleNetworkError(context, failure);
      if (!mounted) return;
      if (result == ErrorOutcome.retry) {
        await _check();
      } else if (result == ErrorOutcome.closed) {
        context.go('/');
      }
    }
  }

  String? get _repeatedError {
    final repeated = _repeated.text;
    if (repeated.isEmpty || repeated == _newPassword.text) return null;
    final finished =
        !_repeatedFocus.hasFocus || repeated.length >= _newPassword.text.length;
    return finished ? AppLocalizations.of(context).rulePasswordMismatch : null;
  }

  bool get _complete =>
      passwordProblems(_newPassword.text).isEmpty &&
      _repeated.text == _newPassword.text &&
      _serverError == null;

  Future<void> _save() async {
    if (_submitting || !_complete) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    Object? failure;
    try {
      await widget.recovery.createPassword(widget.code, _newPassword.text);
      if (mounted) setState(() => _stage = _Stage.done);
    } on InvalidLink {
      if (mounted) setState(() => _stage = _Stage.invalid);
    } on PasswordRejected catch (e) {
      if (mounted) setState(() => _serverError = e.errors['nueva']);
    } on FalloDeRed catch (e) {
      failure = e;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    if (failure != null && mounted) {
      // El servidor pudo haber cambiado la contraseña antes de que se cortara la red.
      _hadNetworkFailure = true;
      final retry = await askRetry(context, failure);
      if (retry && mounted) await _save();
    }
  }

  Future<void> _backToLogin() async {
    // La contraseña cambió: si había una sesión abierta en este teléfono, ya venció.
    if (widget.session.profile != null) {
      await signOut(context, widget.session);
    }
    if (mounted) context.go('/');
  }

  FormTextField _field(
    TextEditingController controller, {
    required String label,
    required String accessible,
    required String placeholder,
    String? error,
    FocusNode? focus,
  }) {
    final visible = _visible.contains(controller);
    return passwordField(
      label: label,
      accessibleLabel: accessible,
      placeholder: placeholder,
      controller: controller,
      focusNode: focus,
      error: error,
      visible: visible,
      enabled: !_submitting,
      autofill: AutofillHints.newPassword,
      onSubmit: controller == _repeated ? (_) => _save() : null,
      onToggle: () => setState(
        () => visible ? _visible.remove(controller) : _visible.add(controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    switch (_stage) {
      case _Stage.checking:
        return Scaffold(
          backgroundColor: p.bgBase,
          body: Center(
            child: Semantics(
              label: l10n.newPasswordChecking,
              child: CircularProgressIndicator(color: p.accentInk),
            ),
          ),
        );
      case _Stage.invalid:
        return ResultScreen(
          icon: Icons.warning_amber_rounded,
          tone: ResultTone.danger,
          title: l10n.newPasswordInvalidTitle,
          text: _hadNetworkFailure
              ? l10n.newPasswordInvalidAfterCutoff
              : l10n.newPasswordInvalid,
          primary: l10n.newPasswordRequestNew,
          onPrimaryTap: () => context.go('/recuperar-contrasena'),
          secondary: l10n.newPasswordBackToSignIn,
          onSecondaryTap: () => context.go('/'),
        );
      case _Stage.done:
        return PasswordUpdated(
          primary: l10n.accountBackToSignIn,
          onPrimaryTap: _backToLogin,
        );
      case _Stage.form:
        break;
    }
    return PasswordFormTemplate(
      bar: TopBar(
        title: l10n.newPasswordBarTitle,
        onBack: () => context.go('/'),
      ),
      title: l10n.newPasswordHeading,
      explanation: l10n.newPasswordExplanation,
      fields: [
        _field(
          _newPassword,
          label: l10n.passwordNewUpper,
          accessible: l10n.passwordNew,
          placeholder: l10n.passwordNewPlaceholder,
          error: _serverError,
        ),
        PasswordRules(password: _newPassword.text),
        const SizedBox(height: Spacing.s16),
        _field(
          _repeated,
          label: l10n.passwordRepeatUpper,
          accessible: l10n.passwordRepeat,
          placeholder: l10n.passwordRepeatPlaceholder,
          error: _repeatedError,
          focus: _repeatedFocus,
        ),
      ],
      submitting: _submitting,
      onSave: _complete ? _save : null,
    );
  }
}
