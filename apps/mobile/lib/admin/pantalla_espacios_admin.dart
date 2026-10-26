import 'package:flutter/material.dart';

import '../api/cliente_api.dart';
import '../comun/barra_inferior.dart';
import '../sesion/fallo_de_carga.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../sesion/sesion.dart';
import '../tema/tokens.dart';
import 'baja_espacio.dart';
import 'listado_admin.dart';
import 'tarjeta_espacio_admin.dart';

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
    } on FalloDeRed catch (e) {
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
