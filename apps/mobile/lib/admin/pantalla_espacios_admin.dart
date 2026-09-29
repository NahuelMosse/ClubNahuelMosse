import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_inferior.dart';
import '../comun/boton.dart';
import '../comun/dialogo_error.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../espacios/iconos.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// «Gestionar espacios» del panel: los espacios activos y el acceso al alta.
class PantallaEspaciosAdmin extends StatefulWidget {
  const PantallaEspaciosAdmin({
    super.key,
    required this.espacios,
    required this.sesion,
  });

  final Espacios espacios;
  final Sesion sesion;

  @override
  State<PantallaEspaciosAdmin> createState() => _PantallaEspaciosAdminState();
}

class _PantallaEspaciosAdminState extends State<PantallaEspaciosAdmin> {
  (List<Espacio>, Catalogo)? _datos;
  bool _fallo = false;

  @override
  void initState() {
    super.initState();
    // El listado queda debajo del alta: cuando se guarda un espacio, se vuelve a leer.
    widget.espacios.addListener(_cargar);
    _cargar();
  }

  @override
  void dispose() {
    widget.espacios.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _fallo = false);
    Object? error;
    var vencida = false;
    try {
      final catalogo = await widget.espacios.catalogo();
      final espacios = await widget.espacios.activos();
      if (mounted) setState(() => _datos = (espacios, catalogo));
      return;
    } on SesionVencida {
      vencida = true;
    } on SinConexion catch (e) {
      error = e;
    } on ErrorDelServidor catch (e) {
      error = e;
    }
    if (!mounted) return;
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
    final datos = _datos;
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: const BarraAdmin(actual: SeccionAdmin.espacios),
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
                              'Espacios',
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
                  texto: 'ALTA ESPACIO',
                  icono: Icons.add_rounded,
                  alTocar: () => context.go('/admin/espacios/nuevo'),
                ),
                const SizedBox(height: Medidas.s16),
                if (datos != null) ..._listado(datos.$1, datos.$2, p),
                if (datos == null && !_fallo)
                  const Padding(
                    padding: EdgeInsets.all(Medidas.s40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (datos == null && _fallo)
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

  List<Widget> _listado(List<Espacio> espacios, Catalogo catalogo, Paleta p) {
    final sedes = {for (final e in espacios) e.sedeId}.length;
    final cuantos = espacios.length == 1
        ? '1 ESPACIO ACTIVO'
        : '${espacios.length} ESPACIOS ACTIVOS';
    return [
      Text(
        '$cuantos · ${sedes == 1 ? '1 SEDE' : '$sedes SEDES'}',
        style: Textos.sobretitulo.copyWith(color: p.textMuted),
      ),
      const SizedBox(height: Medidas.s16),
      if (espacios.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Medidas.s40),
          child: Text(
            'Todavía no hay espacios',
            textAlign: TextAlign.center,
            style: Textos.cuerpo.copyWith(color: p.textSecondary),
          ),
        ),
      for (final espacio in espacios) ...[
        TarjetaEspacioAdmin(espacio: espacio, catalogo: catalogo),
        const SizedBox(height: Medidas.s12),
      ],
    ];
  }
}

/// `Card-Espacio`: deporte, tipo, condición y precio, con el nombre compuesto debajo y
/// «Editar».
class TarjetaEspacioAdmin extends StatelessWidget {
  const TarjetaEspacioAdmin({
    super.key,
    required this.espacio,
    required this.catalogo,
  });

  final Espacio espacio;
  final Catalogo catalogo;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final descripcion = espacio.descripcion(catalogo);
    // Los datos se leen como uno; «Editar» queda afuera, como botón propio.
    final datos = Semantics(
      container: true,
      excludeSemantics: true,
      label: '$descripcion, ${espacio.sede}, ${espacio.nombre}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: Medidas.tactil,
            height: Medidas.tactil,
            decoration: BoxDecoration(
              color: p.accentMuted,
              borderRadius: BorderRadius.circular(Medidas.radioMd),
            ),
            child: Icon(
              iconoDeDeporte(espacio.deporte),
              size: 22,
              color: p.accentInk,
            ),
          ),
          const SizedBox(width: Medidas.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  descripcion,
                  style: Textos.titulo.copyWith(color: p.textPrimary),
                ),
                const SizedBox(height: Medidas.s4),
                Text(
                  espacio.nombre,
                  style: Textos.mono.copyWith(color: p.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(Medidas.s16),
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        borderRadius: BorderRadius.circular(Medidas.radioLg),
        border: Border.all(color: p.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          datos,
          const SizedBox(height: Medidas.s12),
          BotonContorno(
            texto: 'Editar',
            icono: Icons.edit_outlined,
            compacto: true,
            etiquetaAccesible: 'Editar ${espacio.nombre}',
            alTocar: () => context.go(
              '/admin/espacios/${espacio.id}/editar',
              extra: espacio,
            ),
          ),
        ],
      ),
    );
  }
}
