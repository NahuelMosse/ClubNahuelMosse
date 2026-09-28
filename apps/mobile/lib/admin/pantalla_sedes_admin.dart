import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_inferior.dart';
import '../comun/boton.dart';
import '../comun/dialogo_error.dart';
import '../sedes/sede.dart';
import '../sedes/sedes.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

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
    // Tapado por otra pantalla no avisa: al volver, el listado ofrece REINTENTAR.
    if (ModalRoute.of(context)?.isCurrent == false) return;
    if (vencida) {
      await mostrarSesionVencida(context);
      if (mounted) await cerrarSesion(context, widget.sesion);
    } else if (error != null) {
      final reintentar = await mostrarErrorDeRed(context, error);
      if (reintentar && mounted) await _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final sedes = _sedes;
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: const BarraAdmin(actual: SeccionAdmin.sedes),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: SingleChildScrollView(
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
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PANEL ADMIN',
                            style: Textos.sobretitulo.copyWith(
                              color: p.accentInk,
                            ),
                          ),
                          const SizedBox(height: Medidas.s4),
                          Semantics(
                            header: true,
                            child: Text(
                              'Sedes',
                              style: Textos.h1.copyWith(color: p.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    BotonCuenta(sesion: widget.sesion),
                  ],
                ),
                const SizedBox(height: Medidas.s16),
                BotonPrimario(
                  texto: 'AGREGAR SEDE',
                  icono: Icons.add_rounded,
                  alTocar: () => context.go('/admin/sedes/nueva'),
                ),
                const SizedBox(height: Medidas.s16),
                if (sedes != null) ..._listado(sedes, p),
                if (sedes == null && !_fallo)
                  const Padding(
                    padding: EdgeInsets.all(Medidas.s40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (sedes == null && _fallo)
                  Center(
                    child: BotonTexto(texto: 'REINTENTAR', alTocar: _cargar),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _listado(List<Sede> sedes, Paleta p) => [
    Text(
      sedes.length == 1 ? '1 SEDE ACTIVA' : '${sedes.length} SEDES ACTIVAS',
      style: Textos.sobretitulo.copyWith(color: p.textMuted),
    ),
    const SizedBox(height: Medidas.s16),
    if (sedes.isEmpty)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: Medidas.s40),
        child: Text(
          'Todavía no hay sedes',
          textAlign: TextAlign.center,
          style: Textos.cuerpo.copyWith(color: p.textSecondary),
        ),
      ),
    for (final sede in sedes) ...[
      TarjetaSedeAdmin(sede: sede),
      const SizedBox(height: Medidas.s16),
    ],
  ];
}

/// `Card-Sede-Admin`: nombre, dirección, cantidad de canchas y días con horario.
class TarjetaSedeAdmin extends StatelessWidget {
  const TarjetaSedeAdmin({super.key, required this.sede});

  final Sede sede;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final canchas = sede.canchas == 1 ? '1 cancha' : '${sede.canchas} canchas';
    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '${sede.nombre}, ${sede.direccion}, $canchas, '
          '${sede.diasLegibles} de ${sede.apertura} a ${sede.cierre}',
      child: Container(
        padding: const EdgeInsets.all(Medidas.s16),
        decoration: BoxDecoration(
          color: p.bgSurfaceRaised,
          borderRadius: BorderRadius.circular(Medidas.radioLg),
          border: Border.all(color: p.borderDefault),
        ),
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
                  child: Icon(
                    Icons.place_outlined,
                    size: 20,
                    color: p.accentInk,
                  ),
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
      ),
    );
  }
}
