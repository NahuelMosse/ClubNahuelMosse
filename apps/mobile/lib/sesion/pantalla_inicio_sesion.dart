import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/reserva_pendiente.dart';
import '../api/cliente_api.dart';
import '../comun/boton.dart';
import '../comun/campo_texto.dart';
import '../comun/dialogo_error.dart';
import '../comun/snackbar.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'sesion.dart';

const mensajeCredencialesInvalidas =
    'No se pudo iniciar sesión. Revisá tus datos e intentá de nuevo.';

/// Inicio de sesión sobre la foto del club. Va siempre en oscuro: el texto se apoya en la
/// foto oscurecida, no en el fondo del tema.
class PantallaInicioSesion extends StatelessWidget {
  const PantallaInicioSesion({
    super.key,
    required this.sesion,
    required this.pendiente,
  });

  final Sesion sesion;

  /// La reserva que se estaba confirmando cuando venció la sesión.
  final ReservaPendiente pendiente;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: temaOscuro,
      child: _Formulario(sesion: sesion, pendiente: pendiente),
    );
  }
}

class _Formulario extends StatefulWidget {
  const _Formulario({required this.sesion, required this.pendiente});

  final Sesion sesion;
  final ReservaPendiente<Object> pendiente;

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  bool _contrasenaVisible = false;
  bool _enviando = false;
  String? _errorCorreo;
  String? _errorContrasena;
  String? _aviso;

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
      if (mounted) setState(() => _aviso = mensajeCredencialesInvalidas);
    } on SinConexion catch (e) {
      fallo = e;
    } on ErrorDelServidor catch (e) {
      fallo = e;
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
    if (fallo != null && mounted) {
      final reintentar = await mostrarErrorDeRed(context, fallo);
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
          const _Fondo(),
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
                  const _Marca(),
                  const SizedBox(height: Medidas.s24),
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
                  const SizedBox(height: Medidas.s24),
                  BotonPrimario(
                    texto: 'INICIAR SESIÓN',
                    cargando: _enviando,
                    alTocar: _ingresar,
                  ),
                  const SizedBox(height: Medidas.s24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '¿No tenés cuenta?',
                        style: Textos.leyenda.copyWith(
                          color: _Fondo.textoSecundario,
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
                ],
              ),
            ),
          ),
          if (aviso != null)
            Positioned(
              left: Medidas.s24,
              right: Medidas.s24,
              bottom: Medidas.s24,
              child: SafeArea(
                top: false,
                child: SnackbarError(
                  texto: aviso,
                  alCerrar: () => setState(() => _aviso = null),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Marca extends StatelessWidget {
  const _Marca();

  @override
  Widget build(BuildContext context) {
    final lima = Paleta.oscura.accentBase;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('BIENVENIDO A', style: Textos.sobretitulo.copyWith(color: lima)),
        const SizedBox(height: Medidas.s8),
        Semantics(
          header: true,
          label: 'Club Nahuel Mosse',
          child: ExcludeSemantics(
            // En el teléfono chico la marca se achica antes que partirse en dos líneas.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'CLUB ',
                      style: TextStyle(color: Colors.white),
                    ),
                    TextSpan(
                      text: 'NAHUELMOSSE',
                      style: TextStyle(color: lima),
                    ),
                  ],
                ),
                style: Textos.display,
              ),
            ),
          ),
        ),
        const SizedBox(height: Medidas.s8),
        Text(
          'Gestión de espacios deportivos',
          style: Textos.cuerpo.copyWith(color: _Fondo.textoSecundario),
        ),
      ],
    );
  }
}

/// La foto del club con el degradé del prototipo, que asegura el contraste del texto.
class _Fondo extends StatelessWidget {
  const _Fondo();

  /// `text/on-media-muted`: el gris claro que se lee sobre la foto oscurecida.
  static const textoSecundario = Color(0xFFD4D4D8);

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.42, 0.72, 1],
            colors: [
              Color(0x94000000),
              Color(0xB3000000),
              Color(0xCC000000),
              Color(0xF0000000),
            ],
          ),
        ),
        child: Image(
          image: AssetImage('assets/imagenes/login.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
