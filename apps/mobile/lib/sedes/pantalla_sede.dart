import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_inferior.dart';
import '../comun/dialogo_error.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../sesion/fallo_de_carga.dart';
import '../sesion/sesion.dart';
import '../tema/tokens.dart';
import 'sede.dart';
import 'sedes.dart';
import 'contenido_de_sede.dart';

/// Una sede con todas sus canchas, cada una con sus datos y el paso a los horarios.
class PantallaSede extends StatefulWidget {
  const PantallaSede({
    super.key,
    required this.sedeId,
    required this.sedes,
    required this.espacios,
    required this.sesion,
  });

  final String sedeId;
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
    } on FalloDeRed catch (e) {
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
      await avisarSesionVencida(context, widget.sesion);
    } else if (fallo != null) {
      final resultado = await atenderErrorDeRed(context, fallo);
      if (!mounted) return;
      if (resultado == ResultadoDeError.reintentar) {
        await _cargar();
      } else if (resultado == ResultadoDeError.cerrado && _datos == null) {
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
    } on FalloDeRed catch (e) {
      fallo = e;
    } finally {
      if (mounted) setState(() => _filtrando = false);
    }
    if (!mounted || pedido != _pedido) return;
    await avisarFalloDeEnvio(
      context,
      sesion: widget.sesion,
      vencida: vencida,
      error: fallo,
      reintentar: () => _filtrar(deporte: deporte, tipo: tipo),
    );
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
          : ContenidoDeSede(
              sede: datos.$1,
              canchas: _filtradas ?? datos.$2,
              todas: datos.$2,
              catalogo: datos.$3,
              deporte: _deporte,
              tipo: _tipo,
              tiposDelDeporte: _tiposDelDeporte,
              habilitado: !_filtrando && !_cargando,
              filtrando: _filtrando,
              // Tocar el deporte elegido lo quita; «Todos» quita el tipo.
              alElegirDeporte: (d) =>
                  _filtrar(deporte: d == _deporte ? null : d, tipo: null),
              alElegirTipo: (t) => _filtrar(deporte: _deporte, tipo: t),
            ),
    );
  }
}
