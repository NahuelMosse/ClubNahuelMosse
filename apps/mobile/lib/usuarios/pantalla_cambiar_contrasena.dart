import 'package:flutter/material.dart';

import '../api/cliente_api.dart';
import '../comun/barra_superior.dart';
import '../comun/boton.dart';
import '../comun/campo_texto.dart';
import '../comun/dialogo_error.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'reglas_registro.dart';

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
    } on SinConexion catch (e) {
      fallo = e;
    } on ErrorDelServidor catch (e) {
      fallo = e;
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
    if (!mounted) return;
    if (vencida) {
      await mostrarSesionVencida(context);
      if (mounted) await cerrarSesion(context, widget.sesion);
    } else if (fallo != null) {
      final reintentar = await mostrarErrorDeRed(context, fallo);
      if (reintentar && mounted) await _guardar();
    }
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
    return CampoTexto(
      etiqueta: etiqueta,
      etiquetaAccesible: accesible,
      controlador: _controladores[campo.index],
      foco: foco,
      placeholder: placeholder,
      error: _erroresDelServidor[campo] ?? error,
      oculto: !visible,
      habilitado: !_enviando,
      autocompletar: [
        campo == _Campo.actual
            ? AutofillHints.password
            : AutofillHints.newPassword,
      ],
      accion: campo == _Campo.repetida
          ? TextInputAction.done
          : TextInputAction.next,
      alEnviar: campo == _Campo.repetida ? (_) => _guardar() : null,
      accionFinal: VerContrasena(
        visible: visible,
        alCambiar: () => setState(
          () => visible ? _visibles.remove(campo) : _visibles.add(campo),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_listo) return const _Actualizada();
    final p = context.paleta;
    final nueva = _valor(_Campo.nueva);
    return Scaffold(
      backgroundColor: p.bgBase,
      appBar: const BarraSuperior(titulo: 'Cambiar contraseña'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Medidas.s24,
            Medidas.s12,
            Medidas.s24,
            Medidas.s40,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(
                'Cambiá tu contraseña',
                style: Textos.h1.copyWith(color: p.textPrimary),
              ),
            ),
            const SizedBox(height: Medidas.s4),
            Text(
              'Necesitamos tu contraseña actual para confirmar que sos vos.',
              style: Textos.cuerpo.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: Medidas.s16),
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
            if (nueva.isNotEmpty && _faltan.isNotEmpty) ...[
              const SizedBox(height: Medidas.s16),
              _Reglas(faltan: _faltan),
            ],
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
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: p.bgSurfaceRaised,
          border: Border(top: BorderSide(color: p.borderDefault)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Medidas.s24,
              Medidas.s16,
              Medidas.s24,
              Medidas.s24,
            ),
            child: BotonPrimario(
              texto: 'GUARDAR CONTRASEÑA',
              cargando: _enviando,
              alTocar: _completo ? _guardar : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Las tres reglas de la contraseña, cada una en verde si se cumple y en rojo si falta.
class _Reglas extends StatelessWidget {
  const _Reglas({required this.faltan});

  final List<String> faltan;

  static const _todas = [
    'Al menos 8 caracteres',
    'Una letra mayúscula',
    'Al menos un número',
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(Medidas.s16),
        decoration: BoxDecoration(
          color: p.bgSurface,
          borderRadius: BorderRadius.circular(Medidas.radioMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, regla) in _todas.indexed) ...[
              if (i > 0) const SizedBox(height: Medidas.s8),
              _Regla(texto: regla, cumplida: !faltan.contains(regla)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Regla extends StatelessWidget {
  const _Regla({required this.texto, required this.cumplida});

  final String texto;
  final bool cumplida;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      container: true,
      label: '$texto: ${cumplida ? 'cumplida' : 'falta'}',
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(
            cumplida
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
            size: 17,
            color: cumplida ? p.stateSuccessInk : p.stateDangerInk,
          ),
          const SizedBox(width: Medidas.s8),
          Expanded(
            child: Text(
              texto,
              style: Textos.leyenda.copyWith(
                color: cumplida ? p.textSecondary : p.stateDangerInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Actualizada extends StatelessWidget {
  const _Actualizada();

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Scaffold(
      backgroundColor: p.bgBase,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Medidas.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: p.stateSuccessMuted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 40,
                      color: p.stateSuccessInk,
                    ),
                  ),
                ),
                const SizedBox(height: Medidas.s24),
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(
                    'Contraseña actualizada',
                    textAlign: TextAlign.center,
                    style: Textos.h1.copyWith(color: p.textPrimary),
                  ),
                ),
                const SizedBox(height: Medidas.s12),
                Text(
                  'Tu contraseña se cambió correctamente. Usala la próxima vez '
                  'que inicies sesión.',
                  textAlign: TextAlign.center,
                  style: Textos.cuerpo.copyWith(color: p.textSecondary),
                ),
                const SizedBox(height: Medidas.s32),
                BotonPrimario(
                  texto: 'VOLVER AL PERFIL',
                  alTocar: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
