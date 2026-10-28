// kit-shape: a screen or error family kept with its private parts.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/button.dart';
import '../../../common/calendar.dart';
import '../../../common/clock.dart';
import '../../../common/error_dialog.dart';
import '../../../common/field_errors.dart';
import '../../../common/missing_fields.dart';
import '../../../common/network_failure.dart';
import '../../../common/top_bar.dart';
import '../../../theme/tokens.dart';
import '../data/registration_service.dart';
import '../domain/registration_data.dart';
import '../domain/registration_field.dart';
import '../domain/registration_rules.dart';
import 'registration_form.dart';
import 'registration_header.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, required this.registration, this.today});

  final RegistrationService registration;

  /// Para fijar el día en los tests de widgets; en la app es el día de hoy.
  final DateTime Function()? today;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _controllers = [
    for (final _ in RegistrationField.values) TextEditingController(),
  ];
  final _focusNodes = [for (final _ in RegistrationField.values) FocusNode()];
  final _texts = [for (final _ in RegistrationField.values) ''];
  final _touched = <RegistrationField>{};
  final _serverErrors = <RegistrationField, String>{};
  bool _createAttempted = false;
  String? _notice;

  /// Un pedido anterior se cortó sin respuesta: la API pudo haber creado la cuenta igual.
  bool _hadCutoff = false;

  /// El 409 llegó después de un corte: la cuenta que se mandó crear ya existe.
  bool _alreadyExists = false;
  bool _submitting = false;
  bool _passwordVisible = false;

  DateTime get _today => (widget.today ?? clubNow)();

  @override
  void initState() {
    super.initState();
    for (final field in RegistrationField.values) {
      _focusNodes[field.index].addListener(() {
        // Salir de un campo vacío no marca nada: eso lo hace el intento de crear la cuenta.
        if (!_focusNodes[field.index].hasFocus && _valueOf(field).isNotEmpty) {
          setState(() => _touched.add(field));
        }
      });
      _controllers[field.index].addListener(() => _onChanged(field));
    }
  }

  /// Sólo un cambio de texto invalida lo que dijo la API; mover el cursor, no.
  void _onChanged(RegistrationField field) {
    final text = _controllers[field.index].text;
    if (text == _texts[field.index]) return;
    setState(() {
      _texts[field.index] = text;
      _serverErrors.remove(field);
      if (field == RegistrationField.email || field == RegistrationField.dni) {
        _notice = null;
        _hadCutoff = false;
        _alreadyExists = false;
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _valueOf(RegistrationField c) => _controllers[c.index].text;

  String? _ruleError(RegistrationField field) => switch (field) {
    RegistrationField.firstName => validateName(
      _valueOf(field),
      requiredMessage: 'El nombre es obligatorio',
    ),
    RegistrationField.lastName => validateName(
      _valueOf(field),
      requiredMessage: 'El apellido es obligatorio',
    ),
    RegistrationField.dni => validateDni(_valueOf(field)),
    RegistrationField.birthDate => validateBirthDate(_valueOf(field), _today),
    RegistrationField.email => validateEmail(_valueOf(field)),
    RegistrationField.password => validatePassword(_valueOf(field)),
  };

  String? _visibleError(RegistrationField field) => errorToShow(
    serverError: _serverErrors[field],
    ruleError: _ruleError(field),
    attempted: _createAttempted,
    touched: _touched.contains(field),
  );

  bool get _complete =>
      RegistrationField.values.every((c) => _ruleError(c) == null);

  Future<void> _createAccount() async {
    if (_submitting) return;
    final date = readDate(_valueOf(RegistrationField.birthDate));
    if (!_complete || date == null) {
      setState(() => _createAttempted = true);
      focusFirstMissing([
        for (final c in RegistrationField.values)
          (_focusNodes[c.index], _ruleError(c)),
      ]);
      return;
    }
    setState(() {
      _submitting = true;
      _notice = null;
    });
    Object? failure;
    try {
      final r = await widget.registration.register(
        RegistrationData(
          firstName: _valueOf(RegistrationField.firstName),
          lastName: _valueOf(RegistrationField.lastName),
          dni: _valueOf(RegistrationField.dni),
          birthDate: date,
          email: _valueOf(RegistrationField.email),
          password: _valueOf(RegistrationField.password),
        ),
      );
      if (!mounted) return;
      if (r.codigo == 201) {
        context.go('/registro/exitoso');
        return;
      }
      if (r.codigo == 409 && _hadCutoff) {
        setState(() => _alreadyExists = true);
        return;
      }
      final errors = fieldErrors(r.cuerpo);
      final message = r.cuerpo['mensaje'];
      if (errors.isEmpty) {
        failure = ErrorDelServidor(r.codigo);
      } else {
        setState(() {
          for (final MapEntry(:key, :value) in errors.entries) {
            final field = RegistrationField.fromApi(key);
            if (field != null) _serverErrors[field] = value;
          }
          _notice = r.codigo == 409 && message is String ? message : null;
        });
      }
    } on SinConexion catch (e) {
      _hadCutoff = true;
      failure = e;
    } on ErrorDelServidor catch (e) {
      failure = e;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    if (failure != null && mounted) {
      final retry = await showNetworkError(context, failure);
      if (retry && mounted) await _createAccount();
    }
  }

  Future<void> _pickDate() async {
    final picked = await pickBirthDate(
      context,
      readDate(_valueOf(RegistrationField.birthDate)) ??
          DateTime(_today.year - 20),
    );
    if (picked == null || !mounted) return;
    _controllers[RegistrationField.birthDate.index].text = formatDate(picked);
    setState(() => _touched.add(RegistrationField.birthDate));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(title: 'Registro', onBack: () => context.go('/')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.s24,
            Spacing.s8,
            Spacing.s24,
            Spacing.s40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RegistrationHeader(
                alreadyExists: _alreadyExists,
                notice: _notice,
              ),
              RegistrationForm(
                controllers: _controllers,
                focusNodes: _focusNodes,
                errorOf: _visibleError,
                submitting: _submitting,
                passwordVisible: _passwordVisible,
                onPickDate: _pickDate,
                onToggleVisibility: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
              ),
              const SizedBox(height: Spacing.s16),
              PrimaryButton(
                label: 'CREAR CUENTA',
                loading: _submitting,
                dimmed: !_complete,
                onTap: _createAccount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
