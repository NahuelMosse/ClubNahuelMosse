import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../comun/reserva_pendiente.dart';
import '../api/cliente_api.dart';
import '../comun/boton.dart';
import '../comun/campo_texto.dart';
import '../comun/movimiento.dart';
import '../comun/snackbar.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'fallo_de_carga.dart';
import 'sesion.dart';
import 'fondo_de_inicio_sesion.dart';
import 'marca_de_inicio_sesion.dart';

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
    final aviso = _aviso;
    return Scaffold(
      backgroundColor: p.bgBase,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FondoDeInicioSesion(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                Medidas.s24,
                56,
                Medidas.s24,
                96,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const MarcaDeInicioSesion(),
                  const SizedBox(height: Medidas.s24),
                  Aparecer(
                    retraso: const Duration(milliseconds: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CampoTexto(
                          etiquetaAccesible: 'Correo',
                          placeholder: 'Correo',
                          controlador: _correo,
                          error: _errorCorreo,
                          teclado: TextInputType.emailAddress,
                          autocompletar: const [AutofillHints.email],
                          accion: TextInputAction.next,
                          habilitado: !_enviando,
                        ),
                        const SizedBox(height: Medidas.s12),
                        CampoTexto(
                          etiquetaAccesible: 'Contraseña',
                          placeholder: 'Contraseña',
                          controlador: _contrasena,
                          error: _errorContrasena,
                          oculto: !_contrasenaVisible,
                          autocompletar: const [AutofillHints.password],
                          accion: TextInputAction.done,
                          alEnviar: (_) => _ingresar(),
                          habilitado: !_enviando,
                          accionFinal: VerContrasena(
                            visible: _contrasenaVisible,
                            alCambiar: () => setState(
                              () => _contrasenaVisible = !_contrasenaVisible,
                            ),
                          ),
                        ),
                        const SizedBox(height: Medidas.s12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: BotonTexto(
                            texto: '¿Olvidaste tu contraseña?',
                            sobreFoto: true,
                            alTocar: _enviando
                                ? null
                                : () => context.go('/recuperar-contrasena'),
                          ),
                        ),
                      ],
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
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '¿No tenés cuenta?',
                          style: Textos.leyenda.copyWith(
                            color: p.textOnMediaMuted,
                          ),
                        ),
                        BotonTexto(
                          texto: 'COMENZAR',
                          icono: Icons.arrow_forward_rounded,
                          sobreFoto: true,
                          alTocar: _enviando
                              ? null
                              : () => context.go('/registro'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: Medidas.s24,
            right: Medidas.s24,
            bottom: Medidas.s24,
            child: SafeArea(
              top: false,
              child: Temblor(
                disparador: _avisos,
                child: aviso == null
                    ? const SizedBox.shrink()
                    : SnackbarError(
                        texto: aviso,
                        alCerrar: () => setState(() => _aviso = null),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
