import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../espacios/espacio.dart';
import '../espacios/iconos.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'listado_admin.dart';

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
