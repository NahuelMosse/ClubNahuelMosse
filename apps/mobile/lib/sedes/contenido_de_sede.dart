import 'package:flutter/material.dart';
import '../comun/carga_de_lista.dart';
import 'package:go_router/go_router.dart';
import '../comun/estado_vacio.dart';
import '../espacios/espacio.dart';
import '../espacios/iconos.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'fotos.dart';
import 'portada_con_titulo.dart';
import 'sede.dart';
import 'etiqueta_clara.dart';
import 'filtro_de_canchas.dart';
import 'tarjeta_cancha.dart';
import 'resumen_de_sede.dart';

class ContenidoDeSede extends StatelessWidget {
  const ContenidoDeSede({
    super.key,
    required this.sede,
    required this.canchas,
    required this.todas,
    required this.catalogo,
    required this.deporte,
    required this.tipo,
    required this.tiposDelDeporte,
    required this.habilitado,
    required this.filtrando,
    required this.alElegirDeporte,
    required this.alElegirTipo,
  });

  final Sede sede;

  /// Las que pasan el filtro; [todas] son las de la sede, de donde salen los deportes.
  final List<Espacio> canchas;
  final List<Espacio> todas;
  final Catalogo catalogo;
  final String? deporte;
  final String? tipo;
  final List<String> tiposDelDeporte;
  final bool habilitado;

  /// Mientras llega la lista filtrada, en su lugar se ve la carga.
  final bool filtrando;
  final ValueChanged<String> alElegirDeporte;
  final ValueChanged<String?> alElegirTipo;

  String _nombreDelTipo(String clave) =>
      catalogo
          .deporte(deporte ?? '')
          ?.tipos
          .where((x) => x.clave == clave)
          .firstOrNull
          ?.nombre ??
      clave;

  /// «4 CANCHAS · FÚTBOL · TODOS LOS TIPOS», como el prototipo.
  String _contador() {
    final cantidad = cantidadDeCanchas(canchas.length);
    final d = deporte;
    final t = tipo;
    if (todas.isEmpty) return cantidad.toUpperCase();
    if (d == null) return '$cantidad · todos los deportes'.toUpperCase();
    if (t != null) return '$cantidad · ${_nombreDelTipo(t)}'.toUpperCase();
    final nombreDeporte = catalogo.deporte(d)?.nombre ?? d;
    if (tiposDelDeporte.length > 1) {
      return '$cantidad · $nombreDeporte · todos los tipos'.toUpperCase();
    }
    return '$cantidad · $nombreDeporte'.toUpperCase();
  }

  Widget _filtros() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FiltroDeCanchas(
        titulo: 'DEPORTE',
        opciones: [
          for (final d in catalogo.deportes)
            if (todas.any((c) => c.deporte == d.clave))
              (d.clave, d.nombre, iconoDeDeporte(d.clave)),
        ],
        elegida: deporte,
        habilitado: habilitado,
        prefijo: 'Deporte',
        alElegir: (clave) {
          if (clave != null) alElegirDeporte(clave);
        },
      ),
      if (deporte != null && tiposDelDeporte.length > 1) ...[
        const SizedBox(height: Medidas.s16),
        FiltroDeCanchas(
          titulo: 'TIPO DE CANCHA',
          opciones: [
            (null, 'Todos', null),
            for (final t in tiposDelDeporte) (t, _nombreDelTipo(t), null),
          ],
          elegida: tipo,
          habilitado: habilitado,
          prefijo: 'Tipo',
          alElegir: alElegirTipo,
        ),
      ],
      const SizedBox(height: Medidas.s24),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final deportes = deportesDe(sede, catalogo);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PortadaConTitulo(
            imagen: portadaDeSede(sede.id),
            volverA: 'Todas las sedes',
            alVolver: () => context.go('/sedes'),
            separacion: Medidas.s40,
            sobretitulo: '${sede.direccion} · ${sede.apertura} a ${sede.cierre}'
                .toUpperCase(),
            nombre: sede.nombre,
            extra: [
              if (deportes.isNotEmpty) ...[
                const SizedBox(height: Medidas.s8),
                Wrap(
                  spacing: Medidas.s4,
                  runSpacing: Medidas.s4,
                  children: [for (final d in deportes) EtiquetaClara(texto: d)],
                ),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Medidas.s24,
              Medidas.s24,
              Medidas.s24,
              Medidas.s40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (todas.isNotEmpty) _filtros(),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _contador(),
                    style: Textos.sobretitulo.copyWith(color: p.accentInk),
                  ),
                ),
                const SizedBox(height: Medidas.s12),
                CambioDeLista(
                  child: filtrando
                      ? const EsperaDeLista(key: ValueKey('carga'))
                      : Column(
                          key: ValueKey((deporte, tipo)),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (todas.isEmpty)
                              const EstadoVacio(
                                titulo: 'Todavía no hay canchas',
                                texto:
                                    'Esta sede no tiene canchas disponibles por el momento.',
                              )
                            else if (canchas.isEmpty)
                              const EstadoVacio(
                                titulo: 'No hay canchas con este filtro',
                                texto:
                                    'Probá con otro deporte o con otro tipo.',
                              ),
                            for (final cancha in canchas) ...[
                              TarjetaCancha(
                                cancha: cancha,
                                catalogo: catalogo,
                                alReservar: () => context.go(
                                  '/sedes/${sede.id}/canchas/${cancha.id}',
                                ),
                              ),
                              const SizedBox(height: Medidas.s16),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
