import 'package:flutter/material.dart';

import '../api/cliente_api.dart';
import '../comun/barra_superior.dart';
import '../comun/formulario_contrasena.dart';
import '../sesion/fallo_de_carga.dart';
import '../sesion/sesion.dart';
import '../tema/tokens.dart';
import '../comun/reglas_contrasena.dart';
import '../comun/reglas_registro.dart';

enum _Campo { actual, nueva, repetida }

/// Cambiar la contraseña con la sesión iniciada: pide la actual para confirmar que es la
/// misma persona, y al terminar vuelve al perfil sin cerrar la sesión.
class PantallaCambiarContrasena extends StatefulWidget {
  const PantallaCambiarContrasena({super.key, required this.sesion});

  final Sesion sesion;

  @override
  State<PantallaCambiarContrasena> createState() =>
      _PantallaCambiarContrasenaState();
}

class _PantallaCambiarContrasenaState extends State<PantallaCambiarContrasena> {
  final _controladores = [
    for (final _ in _Campo.values) TextEditingController(),
  ];
  final _focoRepetida = FocusNode();
  final _visibles = <_Campo>{};
  final _erroresDelServidor = <_Campo, String>{};
  bool _enviando = false;
  bool _listo = false;

  @override
  void initState() {
    super.initState();
    for (final campo in _Campo.values) {
      final controlador = _controladores[campo.index];
      var anterior = controlador.text;
      controlador.addListener(() {
        // El controlador también avisa cuando se mueve el cursor: sólo cuenta el texto.
        if (controlador.text == anterior) return;
        anterior = controlador.text;
        // Lo que dijo el servidor de un campo deja de valer cuando la persona lo cambia.
        setState(() => _erroresDelServidor.remove(campo));
      });
    }
    _focoRepetida.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final controlador in _controladores) {
      controlador.dispose();
    }
    _focoRepetida.dispose();
    super.dispose();
  }

  String _valor(_Campo campo) => _controladores[campo.index].text;

  List<String> get _faltan => problemasContrasena(_valor(_Campo.nueva));

  bool get _coinciden => _valor(_Campo.repetida) == _valor(_Campo.nueva);

  String? get _errorRepetida {
    final repetida = _valor(_Campo.repetida);
    if (repetida.isEmpty || _coinciden) return null;
    final terminoDeEscribir =
        !_focoRepetida.hasFocus ||
        repetida.length >= _valor(_Campo.nueva).length;
    return terminoDeEscribir ? 'Las contraseñas no coinciden' : null;
  }

  bool get _completo =>
      _valor(_Campo.actual).isNotEmpty &&
      _faltan.isEmpty &&
      _coinciden &&
      _erroresDelServidor.isEmpty;

  Future<void> _guardar() async {
    if (_enviando || !_completo) return;
    FocusScope.of(context).unfocus();
    setState(() => _enviando = true);
    Object? fallo;
    var vencida = false;
    try {
      await widget.sesion.cambiarContrasena(
        _valor(_Campo.actual),
        _valor(_Campo.nueva),
      );
      if (mounted) setState(() => _listo = true);
    } on ContrasenaRechazada catch (e) {
      if (mounted) {
        setState(() {
          for (final MapEntry(:key, :value) in e.errores.entries) {
            final campo = switch (key) {
              'actual' => _Campo.actual,
              'nueva' => _Campo.nueva,
              _ => null,
            };
            if (campo != null) _erroresDelServidor[campo] = value;
          }
        });
      }
    } on SesionVencida {
      vencida = true;
    } on FalloDeRed catch (e) {
      fallo = e;
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
    if (!mounted) return;
    await avisarFalloDeEnvio(
      context,
      sesion: widget.sesion,
      vencida: vencida,
      error: fallo,
      reintentar: _guardar,
    );
  }

  Widget _campo(
    _Campo campo, {
    required String etiqueta,
    required String accesible,
    required String placeholder,
    String? error,
    FocusNode? foco,
  }) {
    final visible = _visibles.contains(campo);
    return campoDeContrasena(
      etiqueta: etiqueta,
      accesible: accesible,
      placeholder: placeholder,
      controlador: _controladores[campo.index],
      foco: foco,
      error: _erroresDelServidor[campo] ?? error,
      visible: visible,
      habilitado: !_enviando,
      autocompletar: campo == _Campo.actual
          ? AutofillHints.password
          : AutofillHints.newPassword,
      alEnviar: campo == _Campo.repetida ? (_) => _guardar() : null,
      alAlternar: () => setState(
        () => visible ? _visibles.remove(campo) : _visibles.add(campo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_listo) {
      return ContrasenaActualizada(
        principal: 'VOLVER AL PERFIL',
        alTocarPrincipal: () => Navigator.of(context).maybePop(),
      );
    }
    final nueva = _valor(_Campo.nueva);
    return PlantillaDeContrasena(
      barra: const BarraSuperior(titulo: 'Cambiar contraseña'),
      titulo: 'Cambiá tu contraseña',
      explicacion:
          'Necesitamos tu contraseña actual para confirmar que sos vos.',
      campos: [
        _campo(
          _Campo.actual,
          etiqueta: 'CONTRASEÑA ACTUAL',
          accesible: 'Contraseña actual',
          placeholder: 'Tu contraseña de hoy',
        ),
        const SizedBox(height: Medidas.s16),
        _campo(
          _Campo.nueva,
          etiqueta: 'CONTRASEÑA NUEVA',
          accesible: 'Contraseña nueva',
          placeholder: 'Mínimo 8 caracteres',
        ),
        ReglasContrasena(contrasena: nueva),
        const SizedBox(height: Medidas.s16),
        _campo(
          _Campo.repetida,
          etiqueta: 'REPETIR CONTRASEÑA',
          accesible: 'Repetir contraseña',
          placeholder: 'Volvé a escribirla',
          error: _errorRepetida,
          foco: _focoRepetida,
        ),
      ],
      enviando: _enviando,
      alGuardar: _completo ? _guardar : null,
    );
  }
}
