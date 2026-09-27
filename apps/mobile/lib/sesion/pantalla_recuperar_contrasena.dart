import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_superior.dart';
import '../comun/boton.dart';
import '../comun/campo_texto.dart';
import '../comun/dialogo_error.dart';
import '../comun/resultado.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import '../usuarios/reglas_registro.dart';
import 'recuperacion.dart';

const avisoEnlaceEnviado =
    'Si el correo está registrado, te enviamos un enlace para crear una contraseña '
    'nueva. El enlace vence en 30 minutos.';

/// Recuperar contraseña: se llega desde «¿Olvidaste tu contraseña?» del login, pide el
/// correo y muestra lo mismo tenga o no cuenta.
class PantallaRecuperarContrasena extends StatefulWidget {
  const PantallaRecuperarContrasena({super.key, required this.recuperacion});

  final Recuperacion recuperacion;

  @override
  State<PantallaRecuperarContrasena> createState() =>
      _PantallaRecuperarContrasenaState();
}

class _PantallaRecuperarContrasenaState
    extends State<PantallaRecuperarContrasena> {
  final _correo = TextEditingController();
  final _foco = FocusNode();
  bool _tocado = false;
  bool _enviando = false;
  bool _enviado = false;
  String? _errorDelServidor;

  @override
  void initState() {
    super.initState();
    _correo.addListener(() => setState(() => _errorDelServidor = null));
    _foco.addListener(() {
      if (!_foco.hasFocus && _correo.text.isNotEmpty) {
        setState(() => _tocado = true);
      }
    });
  }

  @override
  void dispose() {
    _correo.dispose();
    _foco.dispose();
    super.dispose();
  }

  bool get _valido => validarCorreo(_correo.text) == null;

  Future<void> _enviar() async {
    if (_enviando || !_valido) return;
    FocusScope.of(context).unfocus();
    setState(() => _enviando = true);
    Object? fallo;
    try {
      await widget.recuperacion.pedirEnlace(_correo.text.trim().toLowerCase());
      if (mounted) setState(() => _enviado = true);
    } on CorreoRechazado catch (e) {
      if (mounted) setState(() => _errorDelServidor = e.mensaje);
    } on SinConexion catch (e) {
      fallo = e;
    } on ErrorDelServidor catch (e) {
      fallo = e;
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
    if (fallo != null && mounted) {
      final reintentar = await mostrarErrorDeRed(context, fallo);
      if (reintentar && mounted) await _enviar();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_enviado) {
      return PantallaResultado(
        icono: Icons.mail_outline_rounded,
        tono: TonoResultado.aviso,
        titulo: 'Revisá tu correo',
        texto: avisoEnlaceEnviado,
        principal: 'VOLVER AL INICIO DE SESIÓN',
        alTocarPrincipal: () => context.go('/'),
        secundaria: 'Reenviar el correo',
        cargandoSecundaria: _enviando,
        alTocarSecundaria: _enviar,
      );
    }
    final p = context.paleta;
    return Scaffold(
      backgroundColor: p.bgBase,
      appBar: BarraSuperior(
        titulo: 'Recuperar contraseña',
        alVolver: () => context.go('/'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Medidas.s24,
            Medidas.s8,
            Medidas.s24,
            Medidas.s40,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: Textos.h1.copyWith(color: p.textPrimary),
              ),
            ),
            const SizedBox(height: Medidas.s8),
            Text(
              'Ingresá el correo con el que te registraste y te enviamos un '
              'enlace para crear una nueva.',
              style: Textos.cuerpo.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: Medidas.s24),
            CampoTexto(
              etiqueta: 'CORREO ELECTRÓNICO',
              etiquetaAccesible: 'Correo electrónico',
              placeholder: 'tu@correo.com',
              controlador: _correo,
              foco: _foco,
              teclado: TextInputType.emailAddress,
              autocompletar: const [AutofillHints.email],
              accion: TextInputAction.send,
              alEnviar: (_) => _enviar(),
              habilitado: !_enviando,
              error:
                  _errorDelServidor ??
                  (_tocado ? validarCorreo(_correo.text) : null),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BarraDeAccion(
        child: BotonPrimario(
          texto: 'ENVIAR ENLACE',
          cargando: _enviando,
          alTocar: _valido ? _enviar : null,
        ),
      ),
    );
  }
}
