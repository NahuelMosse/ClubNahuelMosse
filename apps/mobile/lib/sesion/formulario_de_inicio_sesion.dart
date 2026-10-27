import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/boton.dart';
import '../comun/movimiento.dart';
import '../comun/reserva_pendiente.dart';
import '../tema/tokens.dart';
import 'aviso_de_inicio_sesion.dart';
import 'campos_de_inicio_sesion.dart';
import 'enlace_a_registro.dart';
import 'fallo_de_carga.dart';
import 'fondo_de_inicio_sesion.dart';
import 'marca_de_inicio_sesion.dart';
import 'sesion.dart';

const mensajeCredencialesInvalidas =
    'No se pudo iniciar sesión. Revisá tus datos e intentá de nuevo.';

class FormularioDeInicioSesion extends StatefulWidget {
  const FormularioDeInicioSesion({
    super.key,
    required this.sesion,
    required this.pendiente,
  });

  final Sesion sesion;
  final ReservaPendiente<Object> pendiente;

  @override
  State<FormularioDeInicioSesion> createState() =>
      _FormularioDeInicioSesionState();
}

class _FormularioDeInicioSesionState extends State<FormularioDeInicioSesion> {
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  bool _contrasenaVisible = false;
  bool _enviando = false;
  String? _errorCorreo;
  String? _errorContrasena;
  String? _aviso;

  /// Sube cada vez que aparece el aviso, para que tiemble aunque sea el mismo.
  int _avisos = 0;

  @override
  void initState() {
    super.initState();
    _correo.addListener(() {
      if (_errorCorreo != null) setState(() => _errorCorreo = null);
    });
    _contrasena.addListener(() {
      if (_errorContrasena != null) setState(() => _errorContrasena = null);
    });
  }

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    if (_enviando) return;
    final correo = _correo.text;
    final contrasena = _contrasena.text;
    setState(() {
      _aviso = null;
      _errorCorreo = correo.trim().isEmpty
          ? 'Completá tu correo electrónico'
          : null;
      _errorContrasena = contrasena.isEmpty ? 'Completá tu contraseña' : null;
    });
    if (_errorCorreo != null || _errorContrasena != null) return;

    FocusScope.of(context).unfocus();
    setState(() => _enviando = true);
    Object? fallo;
    try {
      final perfil = await widget.sesion.iniciar(correo, contrasena);
      if (!mounted) return;
      if (widget.pendiente.esDe(perfil.correo)) {
        context.go('/reservar', extra: widget.pendiente.tomar());
      } else {
        context.go(perfil.inicio);
      }
      return;
    } on CredencialesInvalidas {
      if (mounted) {
        setState(() {
          _aviso = mensajeCredencialesInvalidas;
          _avisos++;
        });
      }
    } on FalloDeRed catch (e) {
      fallo = e;
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
    if (fallo != null && mounted) {
      final reintentar = await preguntarReintento(context, fallo);
      if (reintentar && mounted) await _ingresar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    // El fondo no se redimensiona con el teclado: el formulario lo esquiva solo.
    final teclado = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      backgroundColor: p.bgBase,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FondoDeInicioSesion(),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                Medidas.s24,
                56,
                Medidas.s24,
                96 + teclado,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const MarcaDeInicioSesion(),
                  const SizedBox(height: Medidas.s24),
                  Aparecer(
                    retraso: const Duration(milliseconds: 460),
                    child: CamposDeInicioSesion(
                      correo: _correo,
                      contrasena: _contrasena,
                      errorCorreo: _errorCorreo,
                      errorContrasena: _errorContrasena,
                      contrasenaVisible: _contrasenaVisible,
                      enviando: _enviando,
                      alEnviar: _ingresar,
                      alCambiarVisibilidad: () => setState(
                        () => _contrasenaVisible = !_contrasenaVisible,
                      ),
                    ),
                  ),
                  const SizedBox(height: Medidas.s24),
                  Aparecer(
                    retraso: const Duration(milliseconds: 540),
                    child: BotonPrimario(
                      texto: 'INICIAR SESIÓN',
                      cargando: _enviando,
                      alTocar: _ingresar,
                    ),
                  ),
                  const SizedBox(height: Medidas.s24),
                  Aparecer(
                    retraso: const Duration(milliseconds: 620),
                    child: EnlaceARegistro(enviando: _enviando),
                  ),
                ],
              ),
            ),
          ),
          AvisoDeInicioSesion(
            aviso: _aviso,
            avisos: _avisos,
            alCerrar: () => setState(() => _aviso = null),
          ),
        ],
      ),
    );
  }
}
