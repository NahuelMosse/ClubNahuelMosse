// kit-shape: a screen or error family kept with its private parts.
// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/button.dart';
import '../../../common/calendar.dart';
import '../../../common/clock.dart';
import '../../../common/date_format.dart';
import '../../../common/network_failure.dart';
import '../../../common/text_field.dart';
import '../../../theme/tokens.dart';
import '../../session/domain/profile.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../domain/registration_rules.dart';

enum _Field {
  firstName('nombre'),
  lastName('apellido'),
  dni('dni'),
  birthDate('fecha_nacimiento');

  const _Field(this.key);

  /// El nombre del campo en la API.
  final String key;
}

/// Los datos personales en modo edición. Todo se puede cambiar menos el correo (RF 2).
class ProfileEditor extends StatefulWidget {
  const ProfileEditor({
    super.key,
    required this.profile,
    required this.session,
    required this.onSave,
  });

  final Profile profile;
  final Session session;
  final ValueChanged<Profile> onSave;

  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  static const _invalidMessage = 'El formato de los datos no es válido';

  late final _controllers = [
    for (final field in _Field.values)
      TextEditingController(
        text: switch (field) {
          _Field.firstName => widget.profile.firstName,
          _Field.lastName => widget.profile.lastName,
          _Field.dni => readableDni(widget.profile.dni),
          _Field.birthDate => formatDate(widget.profile.birthDate),
        },
      ),
  ];
  late final _email = TextEditingController(text: widget.profile.email);
  final _errors = <_Field, String>{};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    for (final field in _Field.values) {
      final controller = _controllers[field.index];
      var previous = controller.text;
      controller.addListener(() {
        if (controller.text == previous) return;
        previous = controller.text;
        if (_errors.containsKey(field)) setState(() => _errors.remove(field));
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _email.dispose();
    super.dispose();
  }

  String _valueOf(_Field field) => _controllers[field.index].text;

  /// Los campos que no pasan las reglas del registro. El prototipo los marca todos con el
  /// mismo mensaje.
  Set<_Field> _invalidFields() {
    final today = clubNow();
    return {
      for (final field in [_Field.firstName, _Field.lastName])
        if (validateName(_valueOf(field), requiredMessage: _invalidMessage) !=
            null)
          field,
      if (validateDni(_valueOf(_Field.dni)) != null) _Field.dni,
      if (validateBirthDate(_valueOf(_Field.birthDate), today) != null)
        _Field.birthDate,
    };
  }

  Future<void> _save() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    final invalidFields = _invalidFields();
    final date = readDate(_valueOf(_Field.birthDate));
    if (invalidFields.isNotEmpty || date == null) {
      setState(() {
        _errors
          ..clear()
          ..addEntries(invalidFields.map((c) => MapEntry(c, _invalidMessage)));
      });
      return;
    }
    setState(() => _submitting = true);
    Object? failure;
    var expired = false;
    try {
      final profile = await widget.session.updateProfile(
        firstName: _valueOf(_Field.firstName).trim(),
        lastName: _valueOf(_Field.lastName).trim(),
        dni: normalizeDni(_valueOf(_Field.dni)),
        birthDate: isoDate(date),
      );
      if (mounted) widget.onSave(profile);
      return;
    } on DataRejected catch (e) {
      if (mounted) {
        setState(() {
          for (final field in _Field.values) {
            final message = e.errors[field.key];
            if (message == null) continue;
            // El dato de otra cuenta tiene su propio mensaje; lo demás es de formato.
            _errors[field] = e.duplicate ? message : _invalidMessage;
          }
        });
      }
    } on SessionExpired {
      expired = true;
    } on FalloDeRed catch (e) {
      failure = e;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    if (!mounted) {
      // Salió de la pantalla mientras guardaba: la sesión vencida se cierra igual.
      if (expired) {
        try {
          await widget.session.close();
        } on Exception {
          // El próximo pedido la vuelve a encontrar vencida.
        }
      }
      return;
    }
    await avisarFalloDeEnvio(
      context,
      session: widget.session,
      expired: expired,
      error: failure,
      reintentar: _save,
    );
  }

  Future<void> _pickDate() async {
    final picked = await pickBirthDate(
      context,
      readDate(_valueOf(_Field.birthDate)) ?? widget.profile.birthDate,
    );
    if (picked == null || !mounted) return;
    _controllers[_Field.birthDate.index].text = formatDate(picked);
  }

  FormTextField _field(
    _Field field, {
    required String label,
    required String accessible,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    Widget? trailingAction,
  }) => FormTextField(
    label: label,
    semanticLabel: accessible,
    controller: _controllers[field.index],
    error: _errors[field],
    keyboardType: keyboard,
    inputFormatters: formatters,
    enabled: !_submitting,
    trailing: trailingAction,
    textInputAction: TextInputAction.next,
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(_Field.firstName, label: 'NOMBRE', accessible: 'Nombre'),
        const SizedBox(height: Spacing.s12),
        _field(_Field.lastName, label: 'APELLIDO', accessible: 'Apellido'),
        const SizedBox(height: Spacing.s12),
        _field(
          _Field.dni,
          label: 'DNI',
          accessible: 'DNI',
          keyboard: TextInputType.number,
          formatters: [dniInputFormatter],
        ),
        const SizedBox(height: Spacing.s12),
        _field(
          _Field.birthDate,
          label: 'FECHA DE NACIMIENTO',
          accessible: 'Fecha de nacimiento',
          keyboard: TextInputType.number,
          formatters: const [DateInputFormatter()],
          trailingAction: IconButton(
            tooltip: 'Elegir la fecha en el calendario',
            onPressed: _submitting ? null : _pickDate,
            icon: Icon(Icons.calendar_today_outlined, color: p.textSecondary),
          ),
        ),
        const SizedBox(height: Spacing.s12),
        // El correo se ve pero no se edita.
        Opacity(
          opacity: 0.4,
          child: FormTextField(
            label: 'CORREO ELECTRÓNICO',
            semanticLabel: 'Correo electrónico',
            controller: _email,
            enabled: false,
            trailing: Padding(
              padding: const EdgeInsets.only(right: Spacing.s12),
              child: Icon(Icons.lock_outline_rounded, color: p.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: Spacing.s16),
        PrimaryButton(label: 'GUARDAR', loading: _submitting, onTap: _save),
      ],
    );
  }
}
