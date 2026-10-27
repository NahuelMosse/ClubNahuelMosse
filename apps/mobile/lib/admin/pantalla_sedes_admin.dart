import 'package:flutter/material.dart';

import '../api/cliente_api.dart';
import '../comun/barra_inferior.dart';
import '../sedes/sede.dart';
import '../sedes/sedes.dart';
import '../sesion/fallo_de_carga.dart';
import '../sesion/sesion.dart';
import '../tema/tokens.dart';
import 'baja_sede.dart';
import 'listado_admin.dart';
import 'tarjeta_sede_admin.dart';

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
  String? _dandoDeBaja;

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
    } on FalloDeRed catch (e) {
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
