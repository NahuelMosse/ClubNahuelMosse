import 'package:flutter/material.dart';
import '../comun/carga_de_lista.dart';
import 'package:go_router/go_router.dart';

import '../comun/barra_inferior.dart';
import '../comun/boton.dart';
import '../comun/en_curso.dart';
import '../comun/marco_de_tarjeta.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// «PANEL ADMIN» y el título de la sección, con el botón de la cuenta a la derecha.
class EncabezadoAdmin extends StatelessWidget {
  const EncabezadoAdmin({
    super.key,
    required this.titulo,
    required this.sesion,
  });

  final String titulo;
  final Sesion sesion;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PANEL ADMIN',
                style: Textos.sobretitulo.copyWith(color: p.accentInk),
              ),
              const SizedBox(height: Medidas.s4),
              Semantics(
                header: true,
                child: Text(
                  titulo,
                  style: Textos.h1.copyWith(color: p.textPrimary),
                ),
              ),
            ],
          ),
        ),
        BotonCuenta(sesion: sesion),
      ],
    );
  }
}

/// El esqueleto de «Gestionar espacios» y «Gestionar sedes»: encabezado, botón de alta y
/// el [listado] (vacío mientras no hay datos), con la espera y el REINTENTAR.
class PlantillaListadoAdmin extends StatelessWidget {
  const PlantillaListadoAdmin({
    super.key,
    required this.seccion,
    required this.titulo,
    required this.sesion,
    required this.textoAlta,
    required this.rutaAlta,
    required this.alRefrescar,
    required this.absorbiendo,
    required this.hayDatos,
    required this.fallo,
    required this.listado,
  });

  final SeccionAdmin seccion;
  final String titulo;
  final Sesion sesion;
  final String textoAlta;
  final String rutaAlta;
  final Future<void> Function() alRefrescar;

  /// Mientras una baja está en camino no se sale del listado: el resultado se perdería.
  final bool absorbiendo;
  final bool hayDatos;
  final bool fallo;
  final List<Widget> listado;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return AbsorbPointer(
      absorbing: absorbiendo,
      child: Scaffold(
        backgroundColor: p.bgBase,
        bottomNavigationBar: BarraAdmin(actual: seccion),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: alRefrescar,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: Medidas.paginaDeLista,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EncabezadoAdmin(titulo: titulo, sesion: sesion),
                  const SizedBox(height: Medidas.s16),
                  BotonPrimario(
                    texto: textoAlta,
                    icono: Icons.add_rounded,
                    alTocar: () => context.go(rutaAlta),
                  ),
                  const SizedBox(height: Medidas.s16),
                  ...listado,
                  if (!hayDatos && !fallo) const EsperaDeLista(),
                  if (!hayDatos && fallo)
                    Center(
                      child: BotonTexto(
                        texto: 'REINTENTAR',
                        alTocar: alRefrescar,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cabecera del listado: el conteo y, si no hay nada, [vacio].
List<Widget> cabeceraDeListadoAdmin(
  Paleta p, {
  required String conteo,
  required bool vacio,
  required String textoVacio,
}) => [
  Text(conteo, style: Textos.sobretitulo.copyWith(color: p.textMuted)),
  const SizedBox(height: Medidas.s16),
  if (vacio)
    Padding(
      padding: const EdgeInsets.symmetric(vertical: Medidas.s40),
      child: Text(
        textoVacio,
        textAlign: TextAlign.center,
        style: Textos.cuerpo.copyWith(color: p.textSecondary),
      ),
    ),
];

/// La tarjeta de un elemento del listado: sus [datos] y los botones de editar y dar de
/// baja, que bajo un texto agrandado pasan a ir uno debajo del otro.
class TarjetaAdmin extends StatelessWidget {
  const TarjetaAdmin({
    super.key,
    required this.datos,
    required this.nombre,
    required this.textoEditar,
    required this.etiquetaEditar,
    required this.alEditar,
    required this.textoBaja,
    required this.etiquetaBaja,
    required this.alDarDeBaja,
    required this.dandoDeBaja,
  });

  final Widget datos;
  final String nombre;
  final String textoEditar;
  final String etiquetaEditar;

  /// `null` deshabilita el botón (hay otra baja en camino).
  final VoidCallback? alEditar;
  final String textoBaja;
  final String etiquetaBaja;
  final VoidCallback? alDarDeBaja;

  /// La baja de este elemento está en camino.
  final bool dandoDeBaja;

  @override
  Widget build(BuildContext context) {
    // Con cualquier agrandado del texto, los botones lado a lado ya no entran en 360.
    final grande = MediaQuery.textScalerOf(context).scale(10) > 10.5;
    final editar = BotonContorno(
      texto: textoEditar,
      icono: Icons.edit_outlined,
      compacto: true,
      etiquetaAccesible: etiquetaEditar,
      alTocar: alEditar,
    );
    final Widget baja = dandoDeBaja
        ? EnCurso('Dando de baja $nombre')
        : BotonContorno(
            texto: textoBaja,
            icono: Icons.delete_outline_rounded,
            compacto: true,
            peligro: true,
            etiquetaAccesible: etiquetaBaja,
            alTocar: alDarDeBaja,
          );
    return MarcoDeTarjeta(
      recorte: Clip.none,
      padding: const EdgeInsets.all(Medidas.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          datos,
          const SizedBox(height: Medidas.s12),
          if (grande) ...[
            editar,
            const SizedBox(height: Medidas.s8),
            baja,
          ] else
            Row(
              children: [
                Expanded(child: editar),
                const SizedBox(width: Medidas.s8),
                Expanded(child: baja),
              ],
            ),
        ],
      ),
    );
  }
}
