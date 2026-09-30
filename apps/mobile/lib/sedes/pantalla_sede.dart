import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_inferior.dart';
import '../comun/boton.dart';
import '../comun/dialogo_error.dart';
import '../comun/estado_vacio.dart';
import '../comun/etiqueta.dart';
import '../comun/formato_precio.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../espacios/iconos.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'fotos.dart';
import 'pantalla_sedes.dart';
import 'sede.dart';
import 'sedes.dart';

/// Una sede con todas sus canchas, cada una con sus datos y el paso a los horarios.
class PantallaSede extends StatefulWidget {
  const PantallaSede({
    super.key,
    required this.sedeId,
    required this.sedes,
    required this.espacios,
    required this.sesion,
  });

  final int sedeId;
  final Sedes sedes;
  final Espacios espacios;
  final Sesion sesion;

  @override
  State<PantallaSede> createState() => _PantallaSedeState();
}

class _PantallaSedeState extends State<PantallaSede> {
  (Sede, List<Espacio>, Catalogo)? _datos;
  bool _cargando = true;

  /// El filtro de CU-20: el deporte y el tipo elegidos, las canchas que quedan y los tipos
  /// que ofrece ese deporte en la sede.
  String? _deporte;
  String? _tipo;
  List<Espacio>? _filtradas;
  List<String> _tiposDelDeporte = const [];
  bool _filtrando = false;

  /// Cada lectura o filtro toma un número; la respuesta de uno que ya no es el último se
  /// descarta, así una recarga vieja no pisa un filtro nuevo.
  int _pedido = 0;

  @override
  void initState() {
    super.initState();
    // Los horarios de una cancha pueden avisar que ya no está: se vuelve a leer.
    widget.espacios.addListener(_cargar);
    _cargar();
  }

  @override
  void dispose() {
    widget.espacios.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    final pedido = ++_pedido;
    // El filtro que se vuelve a pedir es el que había al empezar.
    final deporteAntes = _deporte;
    final tipoAntes = _tipo;
    setState(() => _cargando = true);
    Object? fallo;
    var vencida = false;
    try {
      final catalogo = await widget.espacios.catalogo();
      final sedes = await widget.sedes.activas();
      final sede = sedes.where((s) => s.id == widget.sedeId).firstOrNull;
      if (sede == null) {
        if (!mounted) return;
        setState(() => _cargando = false);
        await mostrarCambioMientrasTanto(context);
        if (!mounted) return;
        widget.sedes.avisarCambio();
        context.go('/sedes');
        return;
      }
      final canchas = await widget.espacios.activos(sedeId: sede.id);
      // El filtro elegido sigue, salvo que su deporte o su tipo ya no tengan canchas.
      final deporte = canchas.any((c) => c.deporte == deporteAntes)
          ? deporteAntes
          : null;
      final porDeporte = deporte == null
          ? null
          : await widget.espacios.activos(sedeId: sede.id, deporte: deporte);
      final tipos = porDeporte == null
          ? const <String>[]
          : _tiposEnOrden(porDeporte, catalogo, deporte);
      final tipo = tipos.contains(tipoAntes) ? tipoAntes : null;
      final porTipo = deporte == null || tipo == null
          ? porDeporte
          : await widget.espacios.activos(
              sedeId: sede.id,
              deporte: deporte,
              tipo: tipo,
            );
      if (!mounted || pedido != _pedido) return;
      setState(() {
        _datos = (sede, canchas, catalogo);
        _deporte = deporte;
        _tipo = tipo;
        _filtradas = porTipo;
        _tiposDelDeporte = tipos;
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
    if (!mounted || pedido != _pedido) return;
    // Sin datos frescos no se muestra nada: ni parciales ni viejos.
    setState(() {
      _datos = null;
      _cargando = false;
    });
    if (ModalRoute.of(context)?.isCurrent == false) return;
    if (vencida) {
      await mostrarSesionVencida(context);
      if (mounted) await cerrarSesion(context, widget.sesion);
    } else if (fallo != null) {
      final reintentar = await mostrarErrorDeRed(context, fallo);
      if (!mounted) return;
      if (reintentar) {
        await _cargar();
      } else if (_datos == null) {
        context.go('/sedes');
      }
    }
  }

  /// Los tipos de [deporte] que tienen canchas, en el orden del catálogo.
  static List<String> _tiposEnOrden(
    List<Espacio> canchas,
    Catalogo catalogo,
    String? deporte,
  ) {
    final presentes = {for (final c in canchas) c.tipo};
    return [
      for (final t
          in catalogo.deporte(deporte ?? '')?.tipos ?? const <TipoDeCancha>[])
        if (presentes.contains(t.clave)) t.clave,
    ];
  }

  /// Pide a la API las canchas con ese [deporte] y [tipo]; si falla, avisa y todo queda
  /// como estaba.
  Future<void> _filtrar({
    required String? deporte,
    required String? tipo,
  }) async {
    final datos = _datos;
    if (datos == null || _filtrando || _cargando) return;
    final pedido = ++_pedido;
    setState(() => _filtrando = true);
    Object? fallo;
    var vencida = false;
    try {
      // Sin deporte también se pregunta: la sede pudo sumar canchas o deportes.
      final canchas = await widget.espacios.activos(
        sedeId: datos.$1.id,
        deporte: deporte,
        tipo: tipo,
      );
      if (!mounted || pedido != _pedido) return;
      setState(() {
        _deporte = deporte;
        _tipo = tipo;
        if (deporte == null) {
          _datos = (datos.$1, canchas, datos.$3);
          _filtradas = null;
          _tiposDelDeporte = const [];
        } else {
          _filtradas = canchas;
          // Sin tipo elegido la respuesta trae todos los del deporte, nuevos incluidos.
          if (tipo == null) {
            _tiposDelDeporte = _tiposEnOrden(canchas, datos.$3, deporte);
          }
        }
      });
    } on SesionVencida {
      vencida = true;
    } on SinConexion catch (e) {
      fallo = e;
    } on ErrorDelServidor catch (e) {
      fallo = e;
    } finally {
      if (mounted) setState(() => _filtrando = false);
    }
    if (!mounted || pedido != _pedido) return;
    if (vencida) {
      await mostrarSesionVencida(context);
      if (mounted) await cerrarSesion(context, widget.sesion);
    } else if (fallo != null) {
      final reintentar = await mostrarErrorDeRed(context, fallo);
      if (reintentar && mounted) await _filtrar(deporte: deporte, tipo: tipo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final datos = _datos;
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: const BarraInferior(
        actual: Seccion.sedes,
        enRaiz: false,
      ),
      body: datos == null
          ? Center(
              child: _cargando
                  ? const CircularProgressIndicator()
                  : const SizedBox.shrink(),
            )
          : _Contenido(
              sede: datos.$1,
              canchas: _filtradas ?? datos.$2,
              todas: datos.$2,
              catalogo: datos.$3,
              deporte: _deporte,
              tipo: _tipo,
              tiposDelDeporte: _tiposDelDeporte,
              habilitado: !_filtrando && !_cargando,
              // Tocar el deporte elegido lo quita; «Todos» quita el tipo.
              alElegirDeporte: (d) =>
                  _filtrar(deporte: d == _deporte ? null : d, tipo: null),
              alElegirTipo: (t) => _filtrar(deporte: _deporte, tipo: t),
            ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.sede,
    required this.canchas,
    required this.todas,
    required this.catalogo,
    required this.deporte,
    required this.tipo,
    required this.tiposDelDeporte,
    required this.habilitado,
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
      _Filtro(
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
        _Filtro(
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
    const foto = Paleta.oscura;
    final deportes = deportesDe(sede, catalogo);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FotoConVelo(
            imagen: portadaDeSede(sede.id),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Medidas.s12,
                  Medidas.s8,
                  Medidas.s24,
                  Medidas.s24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: () => context.go('/sedes'),
                      style: TextButton.styleFrom(
                        foregroundColor: foto.textPrimary,
                        minimumSize: const Size(0, Medidas.tactil),
                        textStyle: Textos.leyenda,
                      ),
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      label: const Text('Todas las sedes'),
                    ),
                    const SizedBox(height: Medidas.s40),
                    Padding(
                      padding: const EdgeInsets.only(left: Medidas.s12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${sede.direccion} · ${sede.apertura} a ${sede.cierre}'
                                .toUpperCase(),
                            style: Textos.sobretitulo.copyWith(
                              color: foto.accentBase,
                            ),
                          ),
                          const SizedBox(height: Medidas.s4),
                          Semantics(
                            header: true,
                            child: Text(
                              sede.nombre.toUpperCase(),
                              style: Textos.display.copyWith(
                                color: foto.textPrimary,
                              ),
                            ),
                          ),
                          if (deportes.isNotEmpty) ...[
                            const SizedBox(height: Medidas.s8),
                            Wrap(
                              spacing: Medidas.s4,
                              runSpacing: Medidas.s4,
                              children: [
                                for (final d in deportes)
                                  _EtiquetaClara(texto: d),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                if (todas.isEmpty)
                  const EstadoVacio(
                    titulo: 'Todavía no hay canchas',
                    texto:
                        'Esta sede no tiene canchas disponibles por el momento.',
                  )
                else if (canchas.isEmpty)
                  const EstadoVacio(
                    titulo: 'No hay canchas con este filtro',
                    texto: 'Probá con otro deporte o con otro tipo.',
                  ),
                for (final cancha in canchas) ...[
                  TarjetaCancha(
                    cancha: cancha,
                    catalogo: catalogo,
                    alReservar: () =>
                        context.go('/sedes/${sede.id}/canchas/${cancha.id}'),
                  ),
                  const SizedBox(height: Medidas.s16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Una fila de chips para elegir una opción: la elegida en lima. [prefijo] va en la
/// etiqueta accesible de cada chip («Deporte Fútbol»), porque el mismo nombre aparece en
/// la portada y en las tarjetas.
class _Filtro extends StatelessWidget {
  const _Filtro({
    required this.titulo,
    required this.opciones,
    required this.elegida,
    required this.habilitado,
    required this.prefijo,
    required this.alElegir,
  });

  final String titulo;
  final List<(String?, String, IconData?)> opciones;
  final String? elegida;
  final bool habilitado;
  final String prefijo;
  final ValueChanged<String?> alElegir;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            titulo,
            style: Textos.sobretitulo.copyWith(color: p.textMuted),
          ),
        ),
        const SizedBox(height: Medidas.s8),
        Wrap(
          spacing: Medidas.s8,
          runSpacing: Medidas.s8,
          children: [
            for (final (clave, texto, icono) in opciones)
              _Chip(
                texto: texto,
                icono: icono,
                etiqueta: '$prefijo $texto',
                elegido: clave == elegida,
                alTocar: habilitado ? () => alElegir(clave) : null,
              ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.texto,
    required this.icono,
    required this.etiqueta,
    required this.elegido,
    required this.alTocar,
  });

  final String texto;
  final IconData? icono;
  final String etiqueta;
  final bool elegido;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final tinta = elegido ? p.accentOn : p.textPrimary;
    final simbolo = icono;
    return Semantics(
      container: true,
      button: true,
      selected: elegido,
      enabled: alTocar != null,
      label: etiqueta,
      excludeSemantics: true,
      onTap: alTocar,
      child: Material(
        color: elegido ? p.accentBase : p.bgSurfaceRaised,
        shape: StadiumBorder(
          side: BorderSide(color: elegido ? p.accentEdge : p.borderControl),
        ),
        child: InkWell(
          onTap: alTocar,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Medidas.tactil + 4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Medidas.s16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (simbolo != null) ...[
                    Icon(simbolo, size: 18, color: tinta),
                    const SizedBox(width: Medidas.s8),
                  ],
                  Text(
                    texto,
                    style: Textos.cuerpoFuerte.copyWith(color: tinta),
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

/// La etiqueta de deporte sobre la portada: borde claro sobre la foto.
class _EtiquetaClara extends StatelessWidget {
  const _EtiquetaClara({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.symmetric(
        horizontal: Medidas.s8,
        vertical: Medidas.s4,
      ),
      decoration: BoxDecoration(
        color: const Color(0x99000000),
        borderRadius: BorderRadius.circular(Medidas.radioPill),
        border: Border.all(color: const Color(0x66FFFFFF)),
      ),
      child: Text(
        texto,
        style: Textos.leyenda.copyWith(color: Paleta.oscura.textPrimary),
      ),
    );
  }
}

/// `Card-Cancha`: la foto de su deporte con el tipo y el nombre, sus datos, el precio y
/// «VER HORARIOS / RESERVAR».
class TarjetaCancha extends StatelessWidget {
  const TarjetaCancha({
    super.key,
    required this.cancha,
    required this.catalogo,
    required this.alReservar,
  });

  final Espacio cancha;
  final Catalogo catalogo;
  final VoidCallback alReservar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    const foto = Paleta.oscura;
    final tipo = catalogo.tipoCorto(cancha.deporte, cancha.tipo);
    final precio = pesos(cancha.precioPorHora);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        borderRadius: BorderRadius.circular(Medidas.radioLg),
        border: Border.all(color: p.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            excludeSemantics: true,
            label:
                '$tipo, ${cancha.nombre}, ${cancha.condicion}, '
                '${cancha.iluminacion}, '
                '${precio.replaceFirst('\$ ', '')} pesos por hora',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 180,
                  child: FotoConVelo(
                    imagen: fotoDeDeporte(cancha.deporte),
                    child: Padding(
                      padding: const EdgeInsets.all(Medidas.s12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Etiqueta(texto: tipo, sobreFoto: true),
                          Text(
                            cancha.nombre,
                            style: Textos.mono.copyWith(
                              fontSize: 12,
                              color: foto.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Medidas.s16,
                    Medidas.s16,
                    Medidas.s16,
                    0,
                  ),
                  child: _EtiquetasYPrecio(cancha: cancha, precio: precio),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Medidas.s16,
                    Medidas.s12,
                    Medidas.s16,
                    0,
                  ),
                  child: Text(
                    '${catalogo.tipoLegible(cancha.deporte, cancha.tipo)} · '
                    '${cancha.condicion} · '
                    '${cancha.iluminada ? 'con iluminación' : 'sin iluminación'}',
                    style: Textos.leyenda.copyWith(color: p.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Medidas.s16),
            // Sin esto, el lector de pantalla oye el mismo botón en cada cancha.
            child: Semantics(
              label: '$tipo, cancha ${cancha.numero}',
              child: BotonPrimario(
                texto: 'VER HORARIOS / RESERVAR',
                icono: Icons.bolt_rounded,
                alTocar: alReservar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Condición e iluminación a la izquierda y el precio a la derecha; con el texto grande el
/// precio baja debajo de las etiquetas en vez de cortarse.
class _EtiquetasYPrecio extends StatelessWidget {
  const _EtiquetasYPrecio({required this.cancha, required this.precio});

  final Espacio cancha;
  final String precio;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final etiquetas = Wrap(
      spacing: Medidas.s4,
      runSpacing: Medidas.s4,
      children: [
        Etiqueta(
          texto: cancha.condicion,
          icono: cancha.techada
              ? Icons.roofing_rounded
              : Icons.wb_sunny_outlined,
        ),
        Etiqueta(
          texto: cancha.iluminacion,
          icono: cancha.iluminada
              ? Icons.lightbulb_outline_rounded
              : Icons.nightlight_outlined,
        ),
      ],
    );
    final monto = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(precio, style: Textos.h2.copyWith(color: p.accentInk)),
        Text('/ HORA', style: Textos.sobretitulo.copyWith(color: p.textMuted)),
      ],
    );
    if (MediaQuery.textScalerOf(context).scale(10) > 13) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          etiquetas,
          const SizedBox(height: Medidas.s8),
          Align(alignment: Alignment.centerRight, child: monto),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: etiquetas),
        const SizedBox(width: Medidas.s8),
        monto,
      ],
    );
  }
}
