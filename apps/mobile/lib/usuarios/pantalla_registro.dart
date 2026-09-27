import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_superior.dart';
import '../comun/boton.dart';
import '../comun/campo_texto.dart';
import '../comun/dialogo_error.dart';
import '../comun/formato_fecha.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'reglas_registro.dart';

enum _Campo { nombre, apellido, dni, fechaNacimiento, correo, contrasena }

const _campoDeLaApi = {
  'nombre': _Campo.nombre,
  'apellido': _Campo.apellido,
  'dni': _Campo.dni,
  'fecha_nacimiento': _Campo.fechaNacimiento,
  'correo': _Campo.correo,
  'contrasena': _Campo.contrasena,
};

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key, required this.api, this.hoy});

  final ClienteApi api;

  /// Para fijar el día en los tests de widgets; en la app es el día de hoy.
  final DateTime Function()? hoy;

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _controladores = [
    for (final _ in _Campo.values) TextEditingController(),
  ];
  final _focos = [for (final _ in _Campo.values) FocusNode()];
  final _tocados = <_Campo>{};
  final _erroresDelServidor = <_Campo, String>{};
  String? _aviso;
  bool _enviando = false;
  bool _contrasenaVisible = false;

  @override
  void initState() {
    super.initState();
    for (final campo in _Campo.values) {
      _focos[campo.index].addListener(() {
        if (!_focos[campo.index].hasFocus) setState(() => _tocados.add(campo));
      });
      _controladores[campo.index].addListener(() {
        _erroresDelServidor.remove(campo);
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controladores) {
      c.dispose();
    }
    for (final f in _focos) {
      f.dispose();
    }
    super.dispose();
  }

  String _valor(_Campo c) => _controladores[c.index].text;

  String? _errorDeRegla(_Campo campo) {
    final hoy = (widget.hoy ?? DateTime.now)();
    return switch (campo) {
      _Campo.nombre => validarNombre(
        _valor(campo),
        obligatorio: 'El nombre es obligatorio',
      ),
      _Campo.apellido => validarNombre(
        _valor(campo),
        obligatorio: 'El apellido es obligatorio',
      ),
      _Campo.dni => validarDni(_valor(campo)),
      _Campo.fechaNacimiento => validarFechaNacimiento(_valor(campo), hoy),
      _Campo.correo => validarCorreo(_valor(campo)),
      _Campo.contrasena => validarContrasena(_valor(campo)),
    };
  }

  String? _errorVisible(_Campo campo) =>
      _erroresDelServidor[campo] ??
      (_tocados.contains(campo) ? _errorDeRegla(campo) : null);

  bool get _completo => _Campo.values.every((c) => _errorDeRegla(c) == null);

  Future<void> _crearCuenta() async {
    final fecha = leerFecha(_valor(_Campo.fechaNacimiento));
    if (!_completo || fecha == null) return;
    setState(() {
      _enviando = true;
      _aviso = null;
    });
    try {
      final r = await widget.api.post('/registro', {
        'nombre': _valor(_Campo.nombre),
        'apellido': _valor(_Campo.apellido),
        'dni': _valor(_Campo.dni),
        'fecha_nacimiento': fechaIso(fecha),
        'correo': _valor(_Campo.correo),
        'contrasena': _valor(_Campo.contrasena),
      });
      if (!mounted) return;
      if (r.codigo == 201) {
        context.go('/registro/exitoso');
        return;
      }
      final errores = r.cuerpo['errores'];
      setState(() {
        if (errores is Map<String, Object?>) {
          for (final MapEntry(:key, :value) in errores.entries) {
            final campo = _campoDeLaApi[key];
            if (campo != null && value is String) {
              _erroresDelServidor[campo] = value;
            }
          }
        }
        final mensaje = r.cuerpo['mensaje'];
        _aviso = r.codigo == 409 && mensaje is String ? mensaje : null;
      });
    } on SinConexion catch (e) {
      if (mounted) {
        await mostrarErrorDeRed(context, e, reintentar: _crearCuenta);
      }
    } on ErrorDelServidor catch (e) {
      if (mounted) await mostrarErrorDeRed(context, e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _elegirFecha() async {
    final hoy = (widget.hoy ?? DateTime.now)();
    final elegida = await showDatePicker(
      context: context,
      initialDate:
          leerFecha(_valor(_Campo.fechaNacimiento)) ?? DateTime(hoy.year - 20),
      firstDate: DateTime(1900),
      lastDate: hoy.subtract(const Duration(days: 1)),
    );
    if (elegida == null) return;
    final dd = elegida.day.toString().padLeft(2, '0');
    final mm = elegida.month.toString().padLeft(2, '0');
    _controladores[_Campo.fechaNacimiento.index].text =
        '$dd / $mm / ${elegida.year}';
    setState(() => _tocados.add(_Campo.fechaNacimiento));
  }

  CampoTexto _campo(
    _Campo campo, {
    required String etiqueta,
    required String accesible,
    required String placeholder,
    TextInputType? teclado,
    Widget? accionFinal,
    bool oculto = false,
    Iterable<String>? autocompletar,
  }) {
    return CampoTexto(
      etiqueta: etiqueta,
      etiquetaAccesible: accesible,
      controlador: _controladores[campo.index],
      foco: _focos[campo.index],
      placeholder: placeholder,
      error: _errorVisible(campo),
      teclado: teclado,
      oculto: oculto,
      accionFinal: accionFinal,
      autocompletar: autocompletar,
      accion: campo == _Campo.contrasena
          ? TextInputAction.done
          : TextInputAction.next,
      formateadores: switch (campo) {
        _Campo.dni => [formatoDni],
        _Campo.fechaNacimiento => const [FormatoFecha()],
        _ => null,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final aviso = _aviso;
    return Scaffold(
      appBar: BarraSuperior(
        titulo: 'Registro',
        alVolver: () => context.go('/'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Medidas.s24,
            Medidas.s8,
            Medidas.s24,
            Medidas.s40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (aviso != null) ...[
                _Aviso(texto: aviso),
                const SizedBox(height: Medidas.s16),
              ],
              Text(
                'Creá tu cuenta',
                style: Textos.h1.copyWith(color: p.textPrimary),
              ),
              const SizedBox(height: Medidas.s4),
              Text(
                'Todos los campos son obligatorios.',
                style: Textos.leyenda.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: Medidas.s16),
              _campo(
                _Campo.nombre,
                etiqueta: 'NOMBRE',
                accesible: 'Nombre',
                placeholder: 'Tu nombre',
                teclado: TextInputType.name,
                autocompletar: const [AutofillHints.givenName],
              ),
              const SizedBox(height: Medidas.s16),
              _campo(
                _Campo.apellido,
                etiqueta: 'APELLIDO',
                accesible: 'Apellido',
                placeholder: 'Tu apellido',
                teclado: TextInputType.name,
                autocompletar: const [AutofillHints.familyName],
              ),
              const SizedBox(height: Medidas.s16),
              _campo(
                _Campo.dni,
                etiqueta: 'DNI',
                accesible: 'DNI',
                placeholder: '00.000.000',
                teclado: TextInputType.number,
              ),
              const SizedBox(height: Medidas.s16),
              _campo(
                _Campo.fechaNacimiento,
                etiqueta: 'FECHA DE NACIMIENTO',
                accesible: 'Fecha de nacimiento',
                placeholder: 'DD / MM / AAAA',
                teclado: TextInputType.number,
                accionFinal: IconButton(
                  tooltip: 'Elegir fecha',
                  onPressed: _elegirFecha,
                  icon: Icon(
                    Icons.calendar_today_outlined,
                    color: p.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: Medidas.s16),
              _campo(
                _Campo.correo,
                etiqueta: 'CORREO ELECTRÓNICO',
                accesible: 'Correo electrónico',
                placeholder: 'tu@correo.com',
                teclado: TextInputType.emailAddress,
                autocompletar: const [AutofillHints.email],
              ),
              const SizedBox(height: Medidas.s16),
              _campo(
                _Campo.contrasena,
                etiqueta: 'CONTRASEÑA',
                accesible: 'Contraseña',
                placeholder: '8+ caracteres, mayúscula y número',
                oculto: !_contrasenaVisible,
                autocompletar: const [AutofillHints.newPassword],
                accionFinal: IconButton(
                  tooltip: _contrasenaVisible
                      ? 'Ocultar contraseña'
                      : 'Mostrar contraseña',
                  onPressed: () =>
                      setState(() => _contrasenaVisible = !_contrasenaVisible),
                  icon: Icon(
                    _contrasenaVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: p.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: Medidas.s16),
              BotonPrimario(
                texto: 'CREAR CUENTA',
                cargando: _enviando,
                alTocar: _completo ? _crearCuenta : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(Medidas.s16),
        decoration: BoxDecoration(
          color: p.stateDangerMuted,
          borderRadius: BorderRadius.circular(Medidas.radioMd),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: p.stateDangerInk,
            ),
            const SizedBox(width: Medidas.s12),
            Expanded(
              child: Text(
                texto,
                style: Textos.cuerpoFuerte.copyWith(color: p.stateDangerInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
