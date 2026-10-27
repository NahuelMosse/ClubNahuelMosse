import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/apariencia.dart';
import '../comun/barra_inferior.dart';
import '../comun/dialogo_error.dart';
import '../sesion/fallo_de_carga.dart';
import '../sesion/sesion.dart';
import '../tema/tokens.dart';
import 'confirmar_baja.dart';
import 'contenido_de_mi_perfil.dart';

/// Mi perfil: todos los datos de la cuenta, pedidos a la API cada vez que se abre, y los
/// accesos a lo que se puede hacer con ella.
class PantallaMiPerfil extends StatefulWidget {
  const PantallaMiPerfil({
    super.key,
    required this.sesion,
    required this.apariencia,
  });

  final Sesion sesion;
  final Apariencia apariencia;

  @override
  State<PantallaMiPerfil> createState() => _PantallaMiPerfilState();
}

class _PantallaMiPerfilState extends State<PantallaMiPerfil> {
  Perfil? _perfil;
  bool _editando = false;
  bool _cargando = true;
  bool _dandoDeBaja = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!_cargando) setState(() => _cargando = true);
    Object? fallo;
    try {
      final perfil = await widget.sesion.refrescar();
      if (mounted) {
        setState(() {
          _perfil = perfil;
          _cargando = false;
        });
      }
      return;
    } on SesionVencida {
      if (!mounted) {
        // Salió del perfil mientras cargaba: igual se cierra la sesión que ya no vale, y
        // las rutas lo llevan al login.
        try {
          await widget.sesion.cerrar();
        } on Exception {
          // Si Firebase no la pudo cerrar, el próximo pedido vuelve a encontrarla vencida.
        }
        return;
      }
      setState(() => _cargando = false);
      await avisarSesionVencida(context, widget.sesion);
      return;
    } on FalloDeRed catch (e) {
      fallo = e;
    }
    if (!mounted) return;
    // Sin datos frescos no se muestra nada: ni parciales ni viejos.
    setState(() => _cargando = false);
    final resultado = await atenderErrorDeRed(context, fallo);
    if (!mounted) return;
    if (resultado == ResultadoDeError.reintentar) {
      await _cargar();
    } else if (resultado == ResultadoDeError.cerrado) {
      context.go('/inicio');
    }
  }

  Future<void> _confirmarBaja() async {
    final confirmada = await showDialog<bool>(
      context: context,
      barrierColor: context.paleta.bgScrim,
      builder: (context) => const ConfirmarBaja(),
    );
    if (confirmada == true && mounted) await _darDeBaja();
  }

  /// Si el intento anterior se cortó por la red, el servidor pudo haber terminado la baja.
  bool _huboCorte = false;

  Future<void> _darDeBaja() async {
    if (_dandoDeBaja) return;
    setState(() => _dandoDeBaja = true);
    Object? fallo;
    var vencida = false;
    try {
      // Si sale bien, la sesión se cierra y las rutas llevan al login.
      await widget.sesion.darDeBaja();
      return;
    } on SesionVencida {
      vencida = true;
    } on FalloDeRed catch (e) {
      fallo = e;
    } finally {
      if (mounted) setState(() => _dandoDeBaja = false);
    }
    if (vencida && (_huboCorte || !mounted)) {
      // Un 401 después de un corte es la baja que ya se hizo; y si la persona salió de la
      // pantalla, la sesión que no vale se cierra igual. En los dos casos, al login.
      try {
        await widget.sesion.cerrar();
      } on Exception {
        // El próximo arranque la encuentra vencida y la cierra.
      }
      return;
    }
    if (!mounted) return;
    _huboCorte = fallo is SinConexion;
    await avisarFalloDeEnvio(
      context,
      sesion: widget.sesion,
      vencida: vencida,
      error: fallo,
      reintentar: _darDeBaja,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final perfil = _perfil;
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: const BarraInferior(actual: Seccion.perfil),
      body: perfil == null
          ? (_cargando
                ? Center(
                    child: Semantics(
                      label: 'Cargando tu perfil',
                      child: CircularProgressIndicator(color: p.accentInk),
                    ),
                  )
                : const SizedBox.shrink())
          : ContenidoDeMiPerfil(
              perfil: perfil,
              sesion: widget.sesion,
              apariencia: widget.apariencia,
              editando: _editando,
              dandoDeBaja: _dandoDeBaja,
              alEditar: () => setState(() => _editando = true),
              alGuardar: (nuevo) {
                if (!mounted) return;
                setState(() {
                  _perfil = nuevo;
                  _editando = false;
                });
              },
              alConfirmarBaja: _confirmarBaja,
            ),
    );
  }
}
