import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_inferior.dart';
import '../comun/esqueleto.dart';
import '../comun/estado_vacio.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../sesion/fallo_de_carga.dart';
import '../sesion/sesion.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'resumen_de_sede.dart';
import 'sede.dart';
import 'sedes.dart';
import 'tarjeta_sede.dart';

export 'tarjeta_sede.dart' show TarjetaSede;

/// «Todas las sedes»: el catálogo del club, desde la pestaña SEDES.
class PantallaSedes extends StatefulWidget {
  const PantallaSedes({
    super.key,
    required this.sedes,
    required this.espacios,
    required this.sesion,
  });

  final Sedes sedes;
  final Espacios espacios;
  final Sesion sesion;

  @override
  State<PantallaSedes> createState() => _PantallaSedesState();
}

class _PantallaSedesState extends State<PantallaSedes> {
  (List<Sede>, Catalogo)? _datos;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    // La sede o la cancha que se abrió puede avisar que ya no está: se vuelve a leer.
    widget.sedes.addListener(_cargar);
    widget.espacios.addListener(_cargar);
    _cargar();
  }

  @override
  void dispose() {
    widget.sedes.removeListener(_cargar);
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
      if (!mounted) return;
      setState(() {
        _datos = (sedes, catalogo);
        _cargando = false;
      });
      return;
    } on SesionVencida {
      vencida = true;
    } on FalloDeRed catch (e) {
      fallo = e;
    }
    if (!mounted) return;
    // Sin datos frescos no se muestra nada: ni parciales ni viejos.
    setState(() {
      _datos = null;
      _cargando = false;
    });
    // Tapado por la sede o los horarios no avisa: la pantalla de arriba ya avisa lo suyo.
    await avisarFalloDeCarga(
      context,
      sesion: widget.sesion,
      vencida: vencida,
      error: fallo,
      reintentar: _cargar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final datos = _datos;
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: const BarraInferior(actual: Seccion.sedes),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: SingleChildScrollView(
            key: const PageStorageKey('sedes'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              Medidas.s24,
              Medidas.s24,
              Medidas.s24,
              Medidas.s40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Sedes',
                    style: Textos.h1.copyWith(color: p.textPrimary),
                  ),
                ),
                if (datos != null) ...[
                  const SizedBox(height: Medidas.s4),
                  Text(
                    '${datos.$1.length == 1 ? '1 sede' : '${datos.$1.length} sedes'} · '
                    '${cantidadDeCanchas(datos.$1.fold(0, (n, s) => n + s.canchas))} · '
                    'cada una con su horario',
                    style: Textos.leyenda.copyWith(color: p.textSecondary),
                  ),
                  const SizedBox(height: Medidas.s16),
                  if (datos.$1.isEmpty)
                    const EstadoVacio(
                      titulo: 'Todavía no hay sedes',
                      texto: 'El club todavía no cargó sus sedes.',
                    ),
                  for (final sede in datos.$1) ...[
                    TarjetaSede(
                      sede: sede,
                      deportes: deportesDe(sede, datos.$2),
                      alTocar: () => context.go('/sedes/${sede.id}'),
                    ),
                    const SizedBox(height: Medidas.s16),
                  ],
                ],
                if (datos == null && _cargando)
                  const EsqueletoDeLista(forma: FormaDeEsqueleto.sede),
                if (datos == null && !_cargando)
                  EstadoVacio(
                    titulo: 'No pudimos mostrar las sedes',
                    texto: 'Revisá tu conexión y volvé a intentar.',
                    accion: 'REINTENTAR',
                    alTocar: _cargar,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
