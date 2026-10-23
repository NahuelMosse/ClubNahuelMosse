import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_inferior.dart';
import '../sesion/fallo_de_carga.dart';
import '../sedes/sede.dart';
import '../sedes/sedes.dart';
import '../sesion/sesion.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'baja_sede.dart';
import 'listado_admin.dart';

/// «Gestionar sedes» del panel: las sedes activas y el acceso a dar de alta una nueva.
class PantallaSedesAdmin extends StatefulWidget {
  const PantallaSedesAdmin({
    super.key,
    required this.sedes,
    required this.sesion,
  });

  final Sedes sedes;
  final Sesion sesion;

  @override
  State<PantallaSedesAdmin> createState() => _PantallaSedesAdminState();
}

class _PantallaSedesAdminState extends State<PantallaSedesAdmin> {
  List<Sede>? _sedes;
  bool _fallo = false;

  /// La sede que se está dando de baja: mientras tanto no se toca ninguna tarjeta.
  int? _dandoDeBaja;

  @override
  void initState() {
    super.initState();
    // El listado queda debajo del alta: cuando se guarda una sede, se vuelve a leer.
    widget.sedes.addListener(_cargar);
    _cargar();
  }

  @override
  void dispose() {
    widget.sedes.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _fallo = false);
    Object? error;
    var vencida = false;
    try {
      final sedes = await widget.sedes.activas();
      if (mounted) setState(() => _sedes = sedes);
      return;
    } on SesionVencida {
      vencida = true;
    } on SinConexion catch (e) {
      error = e;
    } on ErrorDelServidor catch (e) {
      error = e;
    }
    if (!mounted) return;
    // Sin datos que mostrar, la pantalla deja de esperar antes del aviso.
    setState(() => _fallo = true);
    await avisarFalloDeCarga(
      context,
      sesion: widget.sesion,
      vencida: vencida,
      error: error,
      reintentar: _cargar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final sedes = _sedes;
    return PlantillaListadoAdmin(
      seccion: SeccionAdmin.sedes,
      titulo: 'Sedes',
      sesion: widget.sesion,
      textoAlta: 'AGREGAR SEDE',
      rutaAlta: '/admin/sedes/nueva',
      alRefrescar: _cargar,
      absorbiendo: _dandoDeBaja != null,
      hayDatos: sedes != null,
      fallo: _fallo,
      listado: sedes == null ? const [] : _listado(sedes, p),
    );
  }

  List<Widget> _listado(List<Sede> sedes, Paleta p) => [
    ...cabeceraDeListadoAdmin(
      p,
      conteo: sedes.length == 1
          ? '1 SEDE ACTIVA'
          : '${sedes.length} SEDES ACTIVAS',
      vacio: sedes.isEmpty,
      textoVacio: 'Todavía no hay sedes',
    ),
    for (final sede in sedes) ...[
      TarjetaSedeAdmin(
        sede: sede,
        dandoDeBaja: _dandoDeBaja == sede.id,
        habilitada: _dandoDeBaja == null,
        alDarDeBaja: () => darDeBajaSede(
          context,
          sede: sede,
          sedes: widget.sedes,
          sesion: widget.sesion,
          enviando: (enCamino) {
            if (!mounted) return;
            setState(() => _dandoDeBaja = enCamino ? sede.id : null);
          },
        ),
      ),
      const SizedBox(height: Medidas.s16),
    ],
  ];
}

/// `Card-Sede-Admin`: nombre, dirección, cantidad de canchas y días con horario, con
/// «Editar sede» y «Dar de baja».
class TarjetaSedeAdmin extends StatelessWidget {
  const TarjetaSedeAdmin({
    super.key,
    required this.sede,
    this.alDarDeBaja,
    this.dandoDeBaja = false,
    this.habilitada = true,
  });

  final Sede sede;
  final VoidCallback? alDarDeBaja;

  /// La baja de esta sede está en camino.
  final bool dandoDeBaja;

  /// `false` deshabilita sus botones (hay otra baja en camino).
  final bool habilitada;

  void _editar(BuildContext context) =>
      context.go('/admin/sedes/${sede.id}/editar', extra: sede);

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final canchas = sede.canchas == 1 ? '1 cancha' : '${sede.canchas} canchas';
    // Los datos se leen como uno; los botones quedan afuera, cada uno con su nombre.
    final datos = Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '${sede.nombre}, ${sede.direccion}, $canchas, '
          '${sede.diasLegibles} de ${sede.apertura} a ${sede.cierre}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: Medidas.tactil,
                height: Medidas.tactil,
                decoration: BoxDecoration(
                  color: p.accentMuted,
                  borderRadius: BorderRadius.circular(Medidas.radioMd),
                ),
                child: Icon(Icons.place_outlined, size: 20, color: p.accentInk),
              ),
              const SizedBox(width: Medidas.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sede.nombre,
                      style: Textos.titulo.copyWith(color: p.textPrimary),
                    ),
                    const SizedBox(height: Medidas.s4),
                    Text(
                      sede.direccion,
                      style: Textos.leyenda.copyWith(color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Medidas.s12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${sede.canchas}',
                    style: Textos.h2.copyWith(color: p.accentInk),
                  ),
                  Text(
                    sede.canchas == 1 ? 'CANCHA' : 'CANCHAS',
                    style: Textos.sobretitulo.copyWith(color: p.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Medidas.s12),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 16, color: p.textMuted),
              const SizedBox(width: Medidas.s8),
              Expanded(
                child: Text(
                  '${sede.diasLegibles} · ${sede.apertura} a ${sede.cierre}',
                  style: Textos.leyenda.copyWith(color: p.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return TarjetaAdmin(
      datos: datos,
      nombre: sede.nombre,
      textoEditar: 'Editar sede',
      etiquetaEditar: 'Editar sede ${sede.nombre}',
      alEditar: habilitada ? () => _editar(context) : null,
      textoBaja: 'Dar de baja',
      etiquetaBaja: 'Dar de baja ${sede.nombre}',
      alDarDeBaja: habilitada ? alDarDeBaja : null,
      dandoDeBaja: dandoDeBaja,
    );
  }
}
