import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_inferior.dart';
import '../sesion/fallo_de_carga.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../espacios/iconos.dart';
import '../sesion/sesion.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'baja_espacio.dart';
import 'listado_admin.dart';

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

  /// El espacio que se está dando de baja: mientras tanto no se toca ninguna tarjeta.
  int? _dandoDeBaja;

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
    final datos = _datos;
    return PlantillaListadoAdmin(
      seccion: SeccionAdmin.espacios,
      titulo: 'Espacios',
      sesion: widget.sesion,
      textoAlta: 'ALTA ESPACIO',
      rutaAlta: '/admin/espacios/nuevo',
      alRefrescar: _cargar,
      absorbiendo: _dandoDeBaja != null,
      hayDatos: datos != null,
      fallo: _fallo,
      listado: datos == null ? const [] : _listado(datos.$1, datos.$2, p),
    );
  }

  List<Widget> _listado(List<Espacio> espacios, Catalogo catalogo, Paleta p) {
    final sedes = {for (final e in espacios) e.sedeId}.length;
    final cuantos = espacios.length == 1
        ? '1 ESPACIO ACTIVO'
        : '${espacios.length} ESPACIOS ACTIVOS';
    return [
      ...cabeceraDeListadoAdmin(
        p,
        conteo: '$cuantos · ${sedes == 1 ? '1 SEDE' : '$sedes SEDES'}',
        vacio: espacios.isEmpty,
        textoVacio: 'Todavía no hay espacios',
      ),
      for (final espacio in espacios) ...[
        TarjetaEspacioAdmin(
          espacio: espacio,
          catalogo: catalogo,
          dandoDeBaja: _dandoDeBaja == espacio.id,
          habilitada: _dandoDeBaja == null,
          alDarDeBaja: () => darDeBajaEspacio(
            context,
            espacio: espacio,
            espacios: widget.espacios,
            sesion: widget.sesion,
            enviando: (enCamino) {
              if (!mounted) return;
              setState(() => _dandoDeBaja = enCamino ? espacio.id : null);
            },
          ),
        ),
        const SizedBox(height: Medidas.s12),
      ],
    ];
  }
}

/// `Card-Espacio`: deporte, tipo, condición y precio, con el nombre compuesto debajo,
/// «Editar» y «Baja».
class TarjetaEspacioAdmin extends StatelessWidget {
  const TarjetaEspacioAdmin({
    super.key,
    required this.espacio,
    required this.catalogo,
    this.alDarDeBaja,
    this.dandoDeBaja = false,
    this.habilitada = true,
  });

  final Espacio espacio;
  final Catalogo catalogo;
  final VoidCallback? alDarDeBaja;

  /// La baja de este espacio está en camino.
  final bool dandoDeBaja;

  /// `false` deshabilita sus botones (hay otra baja en camino).
  final bool habilitada;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final descripcion = espacio.descripcion(catalogo);
    // Los datos se leen como uno; los botones quedan afuera, cada uno con su nombre.
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
    return TarjetaAdmin(
      datos: datos,
      nombre: espacio.nombre,
      textoEditar: 'Editar',
      etiquetaEditar: 'Editar ${espacio.nombre}',
      alEditar: habilitada
          ? () => context.go(
              '/admin/espacios/${espacio.id}/editar',
              extra: espacio,
            )
          : null,
      textoBaja: 'Baja',
      etiquetaBaja: 'Baja ${espacio.nombre}',
      alDarDeBaja: habilitada ? alDarDeBaja : null,
      dandoDeBaja: dandoDeBaja,
    );
  }
}
