// kit-shape: a screen or error family kept with its private parts.
// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/password_form.dart';
import '../../../common/top_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/request_failure.dart';
import '../../session/presentation/session.dart';
import '../domain/registration_rules.dart';
import 'password_rules.dart';

enum _Field { current, newPassword, repeat }

/// Cambiar la contraseña con la sesión iniciada: pide la actual para confirmar que es la
/// misma persona, y al terminar vuelve al perfil sin cerrar la sesión.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.session});

  final Session session;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _controllers = [for (final _ in _Field.values) TextEditingController()];
  final _repeatFocus = FocusNode();
  final _visible = <_Field>{};
  final _serverErrors = <_Field, String>{};
  bool _submitting = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    for (final field in _Field.values) {
      final controller = _controllers[field.index];
      var previous = controller.text;
      controller.addListener(() {
        // El controlador también avisa cuando se mueve el cursor: sólo cuenta el texto.
        if (controller.text == previous) return;
        previous = controller.text;
        // Lo que dijo el servidor de un campo deja de valer cuando la persona lo cambia.
        setState(() => _serverErrors.remove(field));
      });
    }
    _repeatFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _repeatFocus.dispose();
    super.dispose();
  }

  String _valueOf(_Field field) => _controllers[field.index].text;

  List<FieldProblem> get _missing =>
      passwordProblems(_valueOf(_Field.newPassword));

  bool get _match => _valueOf(_Field.repeat) == _valueOf(_Field.newPassword);

  String? get _repeatError {
    final repeat = _valueOf(_Field.repeat);
    if (repeat.isEmpty || _match) return null;
    final finishedTyping =
        !_repeatFocus.hasFocus ||
        repeat.length >= _valueOf(_Field.newPassword).length;
    return finishedTyping
        ? AppLocalizations.of(context).rulePasswordMismatch
        : null;
  }

  bool get _complete =>
      _valueOf(_Field.current).isNotEmpty &&
      _missing.isEmpty &&
      _match &&
      _serverErrors.isEmpty;

  Future<void> _save() async {
    if (_submitting || !_complete) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final outcome = await captureRequestFailure(() async {
      try {
        await widget.session.changePassword(
          _valueOf(_Field.current),
          _valueOf(_Field.newPassword),
        );
        if (mounted) setState(() => _done = true);
      } on PasswordRejected catch (e) {
        if (mounted) {
          setState(() {
            for (final MapEntry(:key, :value) in e.errors.entries) {
              final field = switch (key) {
                'actual' => _Field.current,
                'nueva' => _Field.newPassword,
                _ => null,
              };
              if (field != null) _serverErrors[field] = value;
            }
          });
        }
      }
    });
    if (mounted) setState(() => _submitting = false);
    if (!mounted) return;
    await avisarFalloDeEnvio(
      context,
      session: widget.session,
      expired: outcome.expired,
      error: outcome.error,
      reintentar: _save,
    );
  }

  Widget _field(
    _Field field, {
    required String label,
    required String accessible,
    required String placeholder,
    String? error,
    FocusNode? focusNode,
  }) {
    final visible = _visible.contains(field);
    return passwordField(
      label: label,
      accessibleLabel: accessible,
      placeholder: placeholder,
      controller: _controllers[field.index],
      focusNode: focusNode,
      error: _serverErrors[field] ?? error,
      visible: visible,
      enabled: !_submitting,
      autofill: field == _Field.current
          ? AutofillHints.password
          : AutofillHints.newPassword,
      onSubmit: field == _Field.repeat ? (_) => _save() : null,
      onToggle: () => setState(
        () => visible ? _visible.remove(field) : _visible.add(field),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_done) {
      return PasswordUpdated(
        primary: l10n.changePasswordBack,
        onPrimaryTap: () => Navigator.of(context).maybePop(),
      );
    }
    final newPassword = _valueOf(_Field.newPassword);
    return PasswordFormTemplate(
      bar: TopBar(title: l10n.changePasswordTitle),
      title: l10n.changePasswordHeading,
      explanation: l10n.changePasswordExplanation,
      fields: [
        _field(
          _Field.current,
          label: l10n.passwordCurrentUpper,
          accessible: l10n.passwordCurrent,
          placeholder: l10n.passwordCurrentPlaceholder,
        ),
        const SizedBox(height: Spacing.s16),
        _field(
          _Field.newPassword,
          label: l10n.passwordNewUpper,
          accessible: l10n.passwordNew,
          placeholder: l10n.passwordNewPlaceholder,
        ),
        PasswordRules(password: newPassword),
        const SizedBox(height: Spacing.s16),
        _field(
          _Field.repeat,
          label: l10n.passwordRepeatUpper,
          accessible: l10n.passwordRepeat,
          placeholder: l10n.passwordRepeatPlaceholder,
          error: _repeatError,
          focusNode: _repeatFocus,
        ),
      ],
      submitting: _submitting,
      onSave: _complete ? _save : null,
    );
  }
}
