import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_superior.dart';
import '../comun/campo_texto.dart';
import '../comun/dialogo_error.dart';
import '../comun/formulario_contrasena.dart';
import '../comun/reglas_contrasena.dart';
import '../comun/reglas_registro.dart';
import '../comun/resultado.dart';
import '../tema/tokens.dart';
import 'fallo_de_carga.dart';
import 'recuperacion.dart';
import 'sesion.dart';
import 'tarjeta_cuenta.dart';

enum _Estado { comprobando, formulario, invalido, listo }

/// La contraseña nueva, adonde abre el enlace del correo de recuperación.
class PantallaNuevaContrasena extends StatefulWidget {
  const PantallaNuevaContrasena({
    super.key,
    required this.recuperacion,
    required this.sesion,
    required this.codigo,
  });

  final Recuperacion recuperacion;

  /// Si el enlace se abre con una sesión iniciada, esa sesión ya no vale al terminar.
  final Sesion sesion;
  final String codigo;

  @override
  State<PantallaNuevaContrasena> createState() =>
      _PantallaNuevaContrasenaState();
}

class _PantallaNuevaContrasenaState extends State<PantallaNuevaContrasena> {
  final _nueva = TextEditingController();
  final _repetida = TextEditingController();
  final _focoRepetida = FocusNode();
  final _visibles = <TextEditingController>{};
  var _estado = _Estado.comprobando;
  bool _enviando = false;
  bool _huboFalloDeRed = false;
  String? _errorDelServidor;

  @override
  void initState() {
    super.initState();
    var anterior = '';
    _nueva.addListener(() {
      if (_nueva.text == anterior) return;
      anterior = _nueva.text;
      setState(() => _errorDelServidor = null);
    });
    _repetida.addListener(() => setState(() {}));
    _focoRepetida.addListener(() => setState(() {}));
    _comprobar();
  }

  @override
  void dispose() {
    _nueva.dispose();
    _repetida.dispose();
    _focoRepetida.dispose();
    super.dispose();
  }

  Future<void> _comprobar() async {
    setState(() => _estado = _Estado.comprobando);
    Object? fallo;
    try {
      final vigente = await widget.recuperacion.vigente(widget.codigo);
      if (mounted) {
        setState(
          () => _estado = vigente ? _Estado.formulario : _Estado.invalido,
        );
      }
    } on FalloDeRed catch (e) {
      fallo = e;
    }
    if (fallo != null && mounted) {
      final resultado = await atenderErrorDeRed(context, fallo);
      if (!mounted) return;
      if (resultado == ResultadoDeError.reintentar) {
        await _comprobar();
      } else if (resultado == ResultadoDeError.cerrado) {
        context.go('/');
      }
    }
  }

  String? get _errorRepetida {
    final repetida = _repetida.text;
    if (repetida.isEmpty || repetida == _nueva.text) return null;
    final termino =
        !_focoRepetida.hasFocus || repetida.length >= _nueva.text.length;
    return termino ? 'Las contraseñas no coinciden' : null;
  }

  bool get _completo =>
      problemasContrasena(_nueva.text).isEmpty &&
      _repetida.text == _nueva.text &&
      _errorDelServidor == null;

  Future<void> _guardar() async {
    if (_enviando || !_completo) return;
    FocusScope.of(context).unfocus();
    setState(() => _enviando = true);
    Object? fallo;
    try {
      await widget.recuperacion.crearContrasena(widget.codigo, _nueva.text);
      if (mounted) setState(() => _estado = _Estado.listo);
    } on EnlaceInvalido {
      if (mounted) setState(() => _estado = _Estado.invalido);
    } on ContrasenaRechazada catch (e) {
      if (mounted) setState(() => _errorDelServidor = e.errores['nueva']);
    } on FalloDeRed catch (e) {
      fallo = e;
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
    if (fallo != null && mounted) {
      // El servidor pudo haber cambiado la contraseña antes de que se cortara la red.
      _huboFalloDeRed = true;
      final reintentar = await preguntarReintento(context, fallo);
      if (reintentar && mounted) await _guardar();
    }
  }

  Future<void> _volverAlLogin() async {
    // La contraseña cambió: si había una sesión abierta en este teléfono, ya venció.
    if (widget.sesion.perfil != null) {
      await cerrarSesion(context, widget.sesion);
    }
    if (mounted) context.go('/');
  }

  CampoTexto _campo(
    TextEditingController controlador, {
    required String etiqueta,
    required String accesible,
    required String placeholder,
    String? error,
    FocusNode? foco,
  }) {
    final visible = _visibles.contains(controlador);
    return campoDeContrasena(
      etiqueta: etiqueta,
      accesible: accesible,
      placeholder: placeholder,
      controlador: controlador,
      foco: foco,
      error: error,
      visible: visible,
      habilitado: !_enviando,
      autocompletar: AutofillHints.newPassword,
      alEnviar: controlador == _repetida ? (_) => _guardar() : null,
      alAlternar: () => setState(
        () => visible
            ? _visibles.remove(controlador)
            : _visibles.add(controlador),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    switch (_estado) {
      case _Estado.comprobando:
        return Scaffold(
          backgroundColor: p.bgBase,
          body: Center(
            child: Semantics(
              label: 'Comprobando el enlace',
              child: CircularProgressIndicator(color: p.accentInk),
            ),
          ),
        );
      case _Estado.invalido:
        return PantallaResultado(
          icono: Icons.warning_amber_rounded,
          tono: TonoResultado.peligro,
          titulo: 'El enlace no es válido',
          texto: _huboFalloDeRed
              ? 'Este enlace ya se usó o venció. Si recién guardaste tu contraseña '
                    'nueva, iniciá sesión con ella.'
              : 'Este enlace ya se usó o venció. Pedí uno nuevo desde la pantalla '
                    'de inicio de sesión.',
          principal: 'PEDIR UN ENLACE NUEVO',
          alTocarPrincipal: () => context.go('/recuperar-contrasena'),
          secundaria: 'Volver al inicio de sesión',
          alTocarSecundaria: () => context.go('/'),
        );
      case _Estado.listo:
        return ContrasenaActualizada(
          principal: 'VOLVER AL INICIO DE SESIÓN',
          alTocarPrincipal: _volverAlLogin,
        );
      case _Estado.formulario:
        break;
    }
    return PlantillaDeContrasena(
      barra: BarraSuperior(
        titulo: 'Nueva contraseña',
        alVolver: () => context.go('/'),
      ),
      titulo: 'Creá una contraseña nueva',
      explicacion:
          'Tiene que tener al menos 8 caracteres, una mayúscula y un número.',
      campos: [
        _campo(
          _nueva,
          etiqueta: 'CONTRASEÑA NUEVA',
          accesible: 'Contraseña nueva',
          placeholder: 'Mínimo 8 caracteres',
          error: _errorDelServidor,
        ),
        ReglasContrasena(contrasena: _nueva.text),
        const SizedBox(height: Medidas.s16),
        _campo(
          _repetida,
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
