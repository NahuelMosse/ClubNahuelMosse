import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_inferior.dart';
import '../comun/boton.dart';
import '../comun/dialogo_error.dart';
import '../comun/estado_vacio.dart';
import '../comun/etiqueta.dart';
import '../comun/formato_precio.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'fotos.dart';
import 'pantalla_sedes.dart';
import 'sede.dart';
import 'sedes.dart';

/// Una sede con todas sus canchas, cada una con sus datos y el paso a los horarios.
class PantallaSede extends StatefulWidget {
  const PantallaSede({
    super.key,
    required this.sedeId,
    required this.sedes,
    required this.espacios,
    required this.sesion,
  });

  final int sedeId;
  final Sedes sedes;
  final Espacios espacios;
  final Sesion sesion;

  @override
  State<PantallaSede> createState() => _PantallaSedeState();
}

class _PantallaSedeState extends State<PantallaSede> {
  (Sede, List<Espacio>, Catalogo)? _datos;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    // Los horarios de una cancha pueden avisar que ya no está: se vuelve a leer.
    widget.espacios.addListener(_cargar);
    _cargar();
  }

  @override
  void dispose() {
    widget.espacios.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    Object? fallo;
    var vencida = false;
    try {
      final catalogo = await widget.espacios.catalogo();
      final sedes = await widget.sedes.activas();
      final sede = sedes.where((s) => s.id == widget.sedeId).firstOrNull;
      if (sede == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esta sede ya no está disponible')),
        );
        widget.sedes.avisarCambio();
        context.go('/sedes');
        return;
      }
      final canchas = await widget.espacios.activos(sedeId: sede.id);
      if (!mounted) return;
      setState(() {
        _datos = (sede, canchas, catalogo);
        _cargando = false;
      });
      return;
    } on SesionVencida {
      vencida = true;
    } on SinConexion catch (e) {
      fallo = e;
    } on ErrorDelServidor catch (e) {
      fallo = e;
    }
    if (!mounted) return;
    // Sin datos frescos no se muestra nada: ni parciales ni viejos.
    setState(() {
      _datos = null;
      _cargando = false;
    });
    if (ModalRoute.of(context)?.isCurrent == false) return;
    if (vencida) {
      await mostrarSesionVencida(context);
      if (mounted) await cerrarSesion(context, widget.sesion);
    } else if (fallo != null) {
      final reintentar = await mostrarErrorDeRed(context, fallo);
      if (!mounted) return;
      if (reintentar) {
        await _cargar();
      } else if (_datos == null) {
        context.go('/sedes');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final datos = _datos;
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: const BarraInferior(
        actual: Seccion.sedes,
        enRaiz: false,
      ),
      body: datos == null
          ? Center(
              child: _cargando
                  ? const CircularProgressIndicator()
                  : const SizedBox.shrink(),
            )
          : _Contenido(sede: datos.$1, canchas: datos.$2, catalogo: datos.$3),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.sede,
    required this.canchas,
    required this.catalogo,
  });

  final Sede sede;
  final List<Espacio> canchas;
  final Catalogo catalogo;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    const foto = Paleta.oscura;
    final deportes = deportesDe(sede, catalogo);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FotoConVelo(
            imagen: portadaDeSede(sede.id),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Medidas.s12,
                  Medidas.s8,
                  Medidas.s24,
                  Medidas.s24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: () => context.go('/sedes'),
                      style: TextButton.styleFrom(
                        foregroundColor: foto.textPrimary,
                        minimumSize: const Size(0, Medidas.tactil),
                        textStyle: Textos.leyenda,
                      ),
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      label: const Text('Todas las sedes'),
                    ),
                    const SizedBox(height: Medidas.s40),
                    Padding(
                      padding: const EdgeInsets.only(left: Medidas.s12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${sede.direccion} · ${sede.apertura} a ${sede.cierre}'
                                .toUpperCase(),
                            style: Textos.sobretitulo.copyWith(
                              color: foto.accentBase,
                            ),
                          ),
                          const SizedBox(height: Medidas.s4),
                          Semantics(
                            header: true,
                            child: Text(
                              sede.nombre.toUpperCase(),
                              style: Textos.display.copyWith(
                                color: foto.textPrimary,
                              ),
                            ),
                          ),
                          if (deportes.isNotEmpty) ...[
                            const SizedBox(height: Medidas.s8),
                            Wrap(
                              spacing: Medidas.s4,
                              runSpacing: Medidas.s4,
                              children: [
                                for (final d in deportes)
                                  _EtiquetaClara(texto: d),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Medidas.s24,
              Medidas.s24,
              Medidas.s24,
              Medidas.s40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  cantidadDeCanchas(canchas.length).toUpperCase(),
                  style: Textos.sobretitulo.copyWith(color: p.accentInk),
                ),
                const SizedBox(height: Medidas.s12),
                if (canchas.isEmpty)
                  const EstadoVacio(
                    titulo: 'Todavía no hay canchas',
                    texto:
                        'Esta sede no tiene canchas disponibles por el momento.',
                  ),
                for (final cancha in canchas) ...[
                  TarjetaCancha(
                    cancha: cancha,
                    catalogo: catalogo,
                    alReservar: () =>
                        context.go('/sedes/${sede.id}/canchas/${cancha.id}'),
                  ),
                  const SizedBox(height: Medidas.s16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La etiqueta de deporte sobre la portada: borde claro sobre la foto.
class _EtiquetaClara extends StatelessWidget {
  const _EtiquetaClara({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.symmetric(
        horizontal: Medidas.s8,
        vertical: Medidas.s4,
      ),
      decoration: BoxDecoration(
        color: const Color(0x99000000),
        borderRadius: BorderRadius.circular(Medidas.radioPill),
        border: Border.all(color: const Color(0x66FFFFFF)),
      ),
      child: Text(
        texto,
        style: Textos.leyenda.copyWith(color: Paleta.oscura.textPrimary),
      ),
    );
  }
}

/// `Card-Cancha`: la foto de su deporte con el tipo y el nombre, sus datos, el precio y
/// «VER HORARIOS / RESERVAR».
class TarjetaCancha extends StatelessWidget {
  const TarjetaCancha({
    super.key,
    required this.cancha,
    required this.catalogo,
    required this.alReservar,
  });

  final Espacio cancha;
  final Catalogo catalogo;
  final VoidCallback alReservar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    const foto = Paleta.oscura;
    final tipo = catalogo.tipoCorto(cancha.deporte, cancha.tipo);
    final precio = pesos(cancha.precioPorHora);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        borderRadius: BorderRadius.circular(Medidas.radioLg),
        border: Border.all(color: p.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            excludeSemantics: true,
            label:
                '$tipo, ${cancha.nombre}, ${cancha.condicion}, '
                '${cancha.iluminacion}, '
                '${precio.replaceFirst('\$ ', '')} pesos por hora',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 180,
                  child: FotoConVelo(
                    imagen: fotoDeDeporte(cancha.deporte),
                    child: Padding(
                      padding: const EdgeInsets.all(Medidas.s12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Etiqueta(texto: tipo, sobreFoto: true),
                          Text(
                            cancha.nombre,
                            style: Textos.mono.copyWith(
                              fontSize: 12,
                              color: foto.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Medidas.s16,
                    Medidas.s16,
                    Medidas.s16,
                    0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: Medidas.s4,
                          runSpacing: Medidas.s4,
                          children: [
                            Etiqueta(
                              texto: cancha.condicion,
                              icono: cancha.techada
                                  ? Icons.roofing_rounded
                                  : Icons.wb_sunny_outlined,
                            ),
                            Etiqueta(
                              texto: cancha.iluminacion,
                              icono: cancha.iluminada
                                  ? Icons.lightbulb_outline_rounded
                                  : Icons.nightlight_outlined,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Medidas.s8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            precio,
                            style: Textos.h2.copyWith(color: p.accentInk),
                          ),
                          Text(
                            '/ HORA',
                            style: Textos.sobretitulo.copyWith(
                              color: p.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Medidas.s16,
                    Medidas.s12,
                    Medidas.s16,
                    0,
                  ),
                  child: Text(
                    '${catalogo.tipoLegible(cancha.deporte, cancha.tipo)} · '
                    '${cancha.condicion} · '
                    '${cancha.iluminada ? 'con iluminación' : 'sin iluminación'}',
                    style: Textos.leyenda.copyWith(color: p.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Medidas.s16),
            // Sin esto, el lector de pantalla oye el mismo botón en cada cancha.
            child: Semantics(
              label: '$tipo, cancha ${cancha.numero}',
              child: BotonPrimario(
                texto: 'VER HORARIOS / RESERVAR',
                icono: Icons.bolt_rounded,
                alTocar: alReservar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
