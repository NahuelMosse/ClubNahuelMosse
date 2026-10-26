import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_superior.dart';
import '../comun/boton.dart';
import '../comun/estado_vacio.dart';
import '../comun/reloj.dart';
import '../sesion/fallo_de_carga.dart';
import '../sesion/sesion.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'centro.dart';
import 'notificacion.dart';
import 'tarjeta_aviso.dart';
import 'notificaciones_desactivadas.dart';

/// `Centro de notificaciones`: las notificaciones agrupadas por día, con las sin leer
/// marcadas. Sin permiso del sistema, dice «Notificaciones desactivadas» y ofrece activarlas.
class PantallaNotificaciones extends StatefulWidget {
  const PantallaNotificaciones({
    super.key,
    required this.centro,
    required this.sesion,
    required this.alAbrir,
    this.ahora = ahoraEnElClub,
  });

  final CentroDeNotificaciones centro;
  final Sesion sesion;

  /// Lo que pasa al tocar una notificación: llevarla a lo que avisa.
  final void Function(BuildContext, Notificacion) alAbrir;
  final DateTime Function() ahora;

  @override
  State<PantallaNotificaciones> createState() => _PantallaNotificacionesState();
}

class _PantallaNotificacionesState extends State<PantallaNotificaciones> {
  bool _cargando = true;

  /// La lectura de esta visita salió bien: hasta entonces un centro vacío sería un dato viejo.
  bool _leido = false;

  /// La lectura falló y ya se avisó: queda REINTENTAR en lugar de la lista.
  bool _fallo = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _fallo = false;
    });
    Object? fallo;
    var vencida = false;
    try {
      await widget.centro.cargar();
      if (mounted) {
        setState(() {
          _cargando = false;
          _leido = true;
        });
      }
      return;
    } on SesionVencida {
      vencida = true;
    } on SinConexion catch (e) {
      fallo = e;
    } on ErrorDelServidor catch (e) {
      fallo = e;
    }
    if (!mounted) return;
    setState(() => _cargando = false);
    await avisarFalloDeEnvio(
      context,
      sesion: widget.sesion,
      vencida: vencida,
      error: fallo,
      reintentar: _cargar,
      alNoReintentar: () => setState(() => _fallo = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return ListenableBuilder(
      listenable: widget.centro,
      builder: (context, _) {
        final centro = widget.centro;
        final sinAvisos = _leido && centro.lista.isEmpty;
        final desactivadas = !centro.permitido;
        return Scaffold(
          backgroundColor: p.bgBase,
          appBar: BarraSuperior(
            titulo: 'Notificaciones',
            alVolver: () =>
                context.canPop() ? context.pop() : context.go('/inicio'),
          ),
          bottomNavigationBar: desactivadas && sinAvisos
              ? BarraDeAccion(
                  child: BotonPrimario(
                    texto: 'ACTIVAR NOTIFICACIONES',
                    alTocar: centro.activar,
                  ),
                )
              : null,
          body: SafeArea(child: _cuerpo(context, centro, sinAvisos)),
        );
      },
    );
  }

  Widget _cuerpo(
    BuildContext context,
    CentroDeNotificaciones centro,
    bool sinAvisos,
  ) {
    if (!_leido && centro.lista.isEmpty) {
      if (_cargando) return const Center(child: CircularProgressIndicator());
      // Con el aviso de error abierto no hay nada más que mostrar: el reintento es el del aviso.
      return _fallo
          ? Center(
              child: BotonTexto(texto: 'REINTENTAR', alTocar: _cargar),
            )
          : const SizedBox.shrink();
    }
    if (sinAvisos) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(Medidas.s24),
        child: centro.permitido
            ? const EstadoVacio(
                icono: Icons.notifications_none_rounded,
                titulo: 'Todavía no tenés notificaciones',
                texto: 'Acá vas a ver los recordatorios de tus reservas.',
              )
            : const EstadoVacio(
                icono: Icons.notifications_none_rounded,
                titulo: tituloDesactivadas,
                texto: textoDesactivadas,
              ),
      );
    }
    final ahora = widget.ahora();
    final grupos = agruparPorDia(centro.lista, ahora);
    final p = context.paleta;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Medidas.s24,
        Medidas.s8,
        Medidas.s24,
        Medidas.s40,
      ),
      children: [
        if (!centro.permitido) ...[
          NotificacionesDesactivadas(alActivar: centro.activar),
          const SizedBox(height: Medidas.s16),
        ],
        for (final grupo in grupos) ...[
          Semantics(
            header: true,
            child: Padding(
              padding: const EdgeInsets.only(
                top: Medidas.s8,
                bottom: Medidas.s12,
              ),
              child: Text(
                grupo.rotulo,
                style: Textos.sobretitulo.copyWith(color: p.textMuted),
              ),
            ),
          ),
          for (final n in grupo.notificaciones) ...[
            TarjetaAviso(
              notificacion: n,
              ahora: ahora,
              alTocar: () {
                centro.marcarLeida(n);
                widget.alAbrir(context, n);
              },
            ),
            const SizedBox(height: Medidas.s12),
          ],
        ],
      ],
    );
  }
}
