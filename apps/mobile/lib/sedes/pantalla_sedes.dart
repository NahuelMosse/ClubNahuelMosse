import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_inferior.dart';
import '../comun/dialogo_error.dart';
import '../comun/estado_vacio.dart';
import '../comun/etiqueta.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'fotos.dart';
import 'sede.dart';
import 'sedes.dart';

/// Los nombres de los deportes de la sede, en el orden del catálogo.
List<String> deportesDe(Sede sede, Catalogo catalogo) => [
  for (final d in catalogo.deportes)
    if (sede.deportes.contains(d.clave)) d.nombre,
];

String cantidadDeCanchas(int n) => n == 1 ? '1 cancha' : '$n canchas';

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
    // Tapado por la sede o los horarios no avisa: la pantalla de arriba ya avisa lo suyo.
    if (ModalRoute.of(context)?.isCurrent == false) return;
    if (vencida) {
      await mostrarSesionVencida(context);
      if (mounted) await cerrarSesion(context, widget.sesion);
    } else if (fallo != null) {
      final reintentar = await mostrarErrorDeRed(context, fallo);
      if (reintentar && mounted) await _cargar();
    }
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
                  const Padding(
                    padding: EdgeInsets.all(Medidas.s40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
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

/// `Card-Sede`: portada con nombre, dirección, horario y canchas; abajo, los deportes y
/// «Ver canchas». Se toca entera.
class TarjetaSede extends StatelessWidget {
  const TarjetaSede({
    super.key,
    required this.sede,
    required this.deportes,
    required this.alTocar,
  });

  final Sede sede;
  final List<String> deportes;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final canchas = cantidadDeCanchas(sede.canchas);
    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label:
          '${sede.nombre}, ${sede.direccion}, '
          '${sede.diasLegibles} de ${sede.apertura} a ${sede.cierre}, '
          '$canchas${deportes.isEmpty ? '' : ': ${deportes.join(', ')}'}',
      onTap: alTocar,
      child: Material(
        color: p.bgSurface,
        borderRadius: BorderRadius.circular(Medidas.radioLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: alTocar,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                // Un nombre largo pasa a dos líneas y la portada crece con él.
                constraints: const BoxConstraints(minHeight: 158),
                child: FotoConVelo(
                  imagen: portadaDeSede(sede.id),
                  child: Padding(
                    padding: const EdgeInsets.all(Medidas.s16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sede.nombre.toUpperCase(),
                                style: Textos.h1.copyWith(color: p.textOnMedia),
                              ),
                              const SizedBox(height: Medidas.s4),
                              Text(
                                sede.direccion,
                                style: Textos.leyenda.copyWith(
                                  color: p.textOnMediaMuted,
                                ),
                              ),
                              Text(
                                // El rango no se parte entre líneas.
                                '${sede.diasLegibles} · '
                                '${sede.apertura} a ${sede.cierre}',
                                style: Textos.leyenda.copyWith(
                                  fontSize: 12,
                                  color: p.textOnMediaMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: Medidas.s12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Medidas.s12,
                            vertical: Medidas.s4,
                          ),
                          decoration: BoxDecoration(
                            color: p.accentBase,
                            borderRadius: BorderRadius.circular(
                              Medidas.radioMd,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${sede.canchas}',
                                style: Textos.h2.copyWith(color: p.accentOn),
                              ),
                              Text(
                                sede.canchas == 1 ? 'CANCHA' : 'CANCHAS',
                                style: Textos.sobretitulo.copyWith(
                                  color: p.accentOn,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Medidas.s16),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: Medidas.s4,
                        runSpacing: Medidas.s4,
                        children: [
                          for (final d in deportes) Etiqueta(texto: d),
                        ],
                      ),
                    ),
                    const SizedBox(width: Medidas.s8),
                    Text(
                      'Ver canchas',
                      style: Textos.cuerpoFuerte.copyWith(color: p.accentInk),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: p.accentInk,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
