import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_superior.dart';
import '../comun/boton.dart';
import '../comun/calendario.dart';
import '../comun/campo_texto.dart';
import '../comun/dialogo_error.dart';
import '../comun/estado_vacio.dart';
import '../comun/formato_fecha.dart';
import '../comun/selector.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../sedes/pantalla_sede.dart';
import '../sedes/sede.dart';
import '../sedes/sedes.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'fechas.dart';
import 'horarios.dart';
import 'reglas_busqueda.dart';

/// «Consultar canchas»: las canchas de una sede y un deporte libres en todo un rango de un
/// día. Consultar no reserva nada; cada cancha lleva a sus horarios con el rango elegido.
class PantallaBuscarCancha extends StatefulWidget {
  const PantallaBuscarCancha({
    super.key,
    required this.sedes,
    required this.espacios,
    required this.horarios,
    required this.sesion,
  });

  final Sedes sedes;
  final Espacios espacios;
  final Horarios horarios;
  final Sesion sesion;

  @override
  State<PantallaBuscarCancha> createState() => _PantallaBuscarCanchaState();
}

/// Lo que se consultó, para el encabezado y para seguir a los horarios.
typedef _Consulta = ({
  Sede sede,
  String deporte,
  String? tipo,
  DateTime fecha,
  int desde,
  int hasta,
});

class _PantallaBuscarCanchaState extends State<PantallaBuscarCancha> {
  (List<Sede>, Catalogo)? _opciones;
  bool _falloAlCargar = false;

  Sede? _sede;
  String? _deporte;
  String? _tipo;
  final _fecha = TextEditingController();

  /// El texto de FECHA la última vez que cambió: el controlador avisa también cuando
  /// cambian el cursor o el foco, y eso no es cambiar el filtro.
  String _textoDeFecha = '';
  int _desde = 18;
  int _hasta = 19;

  /// Errores que devolvió la API para el último rango consultado.
  Map<String, String> _rechazo = const {};

  bool _consultando = false;
  _Consulta? _consulta;
  List<Espacio>? _resultado;
  Object? _falla;
  bool? _techada;

  @override
  void initState() {
    super.initState();
    _fecha.addListener(_alEscribirFecha);
    _cargar();
  }

  @override
  void dispose() {
    _fecha.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _falloAlCargar = false);
    Object? fallo;
    var vencida = false;
    try {
      final sedes = await widget.sedes.activas();
      final catalogo = await widget.espacios.catalogo();
      if (mounted) setState(() => _opciones = (sedes, catalogo));
      return;
    } on SesionVencida {
      vencida = true;
    } on SinConexion catch (e) {
      fallo = e;
    } on ErrorDelServidor catch (e) {
      fallo = e;
    }
    if (!mounted) return;
    setState(() => _falloAlCargar = true);
    if (vencida) {
      await mostrarSesionVencida(context);
      if (mounted) await cerrarSesion(context, widget.sesion);
    } else if (fallo != null) {
      final reintentar = await mostrarErrorDeRed(context, fallo);
      if (reintentar && mounted) await _cargar();
    }
  }

  void _alEscribirFecha() {
    if (_fecha.text == _textoDeFecha) return;
    _textoDeFecha = _fecha.text;
    _alCambiarFiltro();
  }

  DateTime? get _dia => switch (leerFecha(_fecha.text)) {
    final d? => DateTime.utc(d.year, d.month, d.day),
    null => null,
  };

  /// Los errores de los filtros que ya se pueden juzgar: una fecha completa que no existe,
  /// la fecha fuera de los próximos días, y las reglas del rango cuando hay sede.
  Map<String, String> get _errores {
    final errores = <String, String>{};
    final dia = _dia;
    if (_fecha.text.length >= 'DD / MM / AAAA'.length && dia == null) {
      errores['fecha'] = 'Escribí la fecha como DD / MM / AAAA';
    }
    final sede = _sede;
    if (dia != null && sede == null) {
      errores.addAll(erroresDeLaFecha(dia: dia, ahora: ahoraEnElClub()));
    }
    if (sede != null && dia != null) {
      errores.addAll(
        erroresDelRango(
          sede: sede,
          dia: dia,
          desde: _desde,
          hasta: _hasta,
          ahora: ahoraEnElClub(),
        ),
      );
    }
    return {...errores, ..._rechazo};
  }

  bool get _completo =>
      _sede != null && _deporte != null && _dia != null && _errores.isEmpty;

  /// Otro filtro ya no es la búsqueda que se ve: el resultado se quita hasta consultar de
  /// nuevo, para no mostrar canchas de otra consulta como si fueran de ésta.
  void _alCambiarFiltro() {
    setState(() {
      _rechazo = const {};
      _consulta = null;
      _resultado = null;
      _falla = null;
      _techada = null;
    });
  }

  void _cambiar(VoidCallback cambio) {
    cambio();
    _alCambiarFiltro();
  }

  Future<void> _consultar() async {
    final sede = _sede;
    final deporte = _deporte;
    final dia = _dia;
    if (sede == null || deporte == null || dia == null) return;
    if (!_completo || _consultando) return;
    final consulta = (
      sede: sede,
      deporte: deporte,
      tipo: _tipo,
      fecha: dia,
      desde: _desde,
      hasta: _hasta,
    );
    setState(() {
      _consultando = true;
      _resultado = null;
      _falla = null;
      _techada = null;
    });
    var vencida = false;
    try {
      final libres = await widget.horarios.libres(
        sedeId: sede.id,
        deporte: deporte,
        tipo: _tipo,
        fecha: dia,
        desde: hhmm(_desde),
        hasta: hhmm(_hasta),
      );
      if (!mounted) return;
      setState(() {
        _consultando = false;
        _consulta = consulta;
        _resultado = libres;
      });
      return;
    } on RangoRechazado catch (e) {
      if (!mounted) return;
      setState(() {
        _consultando = false;
        _rechazo = e.errores;
      });
      if (e.errores.containsKey('sede_id')) {
        widget.sedes.avisarCambio();
        await _cargar();
      }
      return;
    } on SesionVencida {
      vencida = true;
    } on SinConexion catch (e) {
      _falla = e;
    } on ErrorDelServidor catch (e) {
      _falla = e;
    }
    if (!mounted) return;
    setState(() {
      _consultando = false;
      _consulta = consulta;
    });
    if (vencida) {
      await mostrarSesionVencida(context);
      if (mounted) await cerrarSesion(context, widget.sesion);
    }
  }

  void _limpiar() {
    _fecha.clear();
    _cambiar(() {
      _sede = null;
      _deporte = null;
      _tipo = null;
      _desde = 18;
      _hasta = 19;
    });
  }

  Future<void> _elegirSede(List<Sede> sedes) async {
    final elegida = await elegirOpcion<Sede>(
      context,
      titulo: 'Sede',
      opciones: [
        for (final s in sedes)
          if (s.canchas > 0) (s, s.nombre),
      ],
      elegida: _sede,
    );
    if (elegida == null || !mounted || elegida.id == _sede?.id) return;
    _cambiar(() {
      _sede = elegida;
      // La sede nueva puede no tener ese deporte.
      if (!elegida.deportes.contains(_deporte)) {
        _deporte = null;
        _tipo = null;
      }
    });
  }

  Future<void> _elegirDeporte(Catalogo catalogo) async {
    final elegido = await elegirOpcion<String>(
      context,
      titulo: 'Deporte',
      opciones: [
        for (final d in catalogo.deportes)
          if (_sede?.deportes.contains(d.clave) ?? true) (d.clave, d.nombre),
      ],
      elegida: _deporte,
    );
    if (elegido != null && mounted && elegido != _deporte) {
      _cambiar(() {
        _deporte = elegido;
        _tipo = null;
      });
    }
  }

  Future<void> _elegirTipo(Catalogo catalogo) async {
    final deporte = catalogo.deporte(_deporte ?? '');
    if (deporte == null) return;
    const todos = '';
    final elegido = await elegirOpcion<String>(
      context,
      titulo: 'Tipo de cancha',
      opciones: [
        (todos, 'Todos los tipos'),
        for (final t in deporte.tipos) (t.clave, t.nombre),
      ],
      elegida: _tipo ?? todos,
    );
    final tipo = elegido == todos ? null : elegido;
    if (elegido != null && mounted && tipo != _tipo) {
      _cambiar(() => _tipo = tipo);
    }
  }

  Future<void> _elegirHora({required bool inicio}) async {
    final horas = inicio
        ? [for (var h = 0; h < 24; h++) h]
        : [for (var h = 1; h < 24; h++) h, 0];
    final elegida = await elegirOpcion<int>(
      context,
      titulo: inicio ? 'Desde' : 'Hasta',
      opciones: [for (final h in horas) (h, hhmm(h))],
      elegida: inicio ? _desde : _hasta,
      columnas: 3,
    );
    if (elegida == null || !mounted) return;
    if (elegida == (inicio ? _desde : _hasta)) return;
    _cambiar(() {
      if (inicio) {
        _desde = elegida;
      } else {
        _hasta = elegida;
      }
    });
  }

  Future<void> _elegirFecha() async {
    final ahora = ahoraEnElClub();
    final elegida = await elegirDiaProximo(
      context,
      hoy: DateTime(ahora.year, ahora.month, ahora.day),
      dias: diasALaVista,
      propuesta: _dia,
    );
    if (elegida != null && mounted) _fecha.text = formatearFecha(elegida);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final opciones = _opciones;
    return Scaffold(
      backgroundColor: p.bgBase,
      appBar: BarraSuperior(
        titulo: 'Buscar cancha',
        alVolver: () => context.go('/inicio'),
      ),
      bottomNavigationBar: opciones == null
          ? null
          : _BarraAccion(
              alLimpiar: _consultando ? null : _limpiar,
              alConsultar: _completo && !_consultando ? _consultar : null,
              consultando: _consultando,
            ),
      body: opciones == null
          ? Center(
              child: _falloAlCargar
                  ? BotonTexto(texto: 'REINTENTAR', alTocar: _cargar)
                  : const CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                Medidas.s24,
                Medidas.s8,
                Medidas.s24,
                Medidas.s40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Consultar canchas',
                      style: Textos.h1.copyWith(color: p.textPrimary),
                    ),
                  ),
                  const SizedBox(height: Medidas.s4),
                  Text(
                    _subtitulo(opciones.$2),
                    style: Textos.cuerpo.copyWith(color: p.textSecondary),
                  ),
                  if (_falla case final falla?) ...[
                    const SizedBox(height: Medidas.s16),
                    _TarjetaError(
                      sinConexion: falla is SinConexion,
                      alVolver: () => setState(() {
                        _falla = null;
                        _consulta = null;
                      }),
                      alReintentar: _consultar,
                    ),
                  ],
                  const SizedBox(height: Medidas.s16),
                  ..._filtros(opciones.$1, opciones.$2),
                  if (_consultando)
                    const Padding(
                      padding: EdgeInsets.all(Medidas.s24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if ((_consulta, _resultado) case (
                    final consulta?,
                    final resultado?,
                  ))
                    ..._resultados(consulta, resultado, opciones.$2, p),
                ],
              ),
            ),
    );
  }

  String _subtitulo(Catalogo catalogo) {
    final c = _consulta;
    if (c == null) {
      return 'Elegí sede, deporte y rango horario. Solo horas completas, de '
          '$minHoras a $maxHoras horas.';
    }
    final dia = fechaLarga(c.fecha).split(' de ');
    final mes = dia.length > 1 ? ' ${dia[1].substring(0, 3)}' : '';
    return '${c.sede.nombre} · ${_queSeBusco(c, catalogo)} · ${dia.first}$mes · '
        '${hhmm(c.desde)} a ${hhmm(c.hasta)}';
  }

  String _queSeBusco(_Consulta c, Catalogo catalogo) {
    final tipo = c.tipo;
    return tipo == null
        ? catalogo.deporte(c.deporte)?.nombre ?? c.deporte
        : catalogo.tipoCorto(c.deporte, tipo);
  }

  List<Widget> _filtros(List<Sede> sedes, Catalogo catalogo) {
    final errores = _errores;
    final deporte = catalogo.deporte(_deporte ?? '');
    final tipo = _tipo;
    return [
      CampoSelector(
        etiqueta: 'SEDE',
        etiquetaAccesible: 'Sede',
        valor: _sede?.nombre,
        placeholder: 'Seleccioná una sede',
        icono: Icons.expand_more_rounded,
        alTocar: _consultando ? null : () => _elegirSede(sedes),
        error: errores['sede_id'],
      ),
      const SizedBox(height: Medidas.s12),
      CampoSelector(
        etiqueta: 'DEPORTE',
        etiquetaAccesible: 'Deporte',
        valor: deporte?.nombre,
        placeholder: 'Seleccioná un deporte',
        icono: Icons.expand_more_rounded,
        alTocar: _consultando ? null : () => _elegirDeporte(catalogo),
      ),
      const SizedBox(height: Medidas.s12),
      CampoSelector(
        etiqueta: 'TIPO DE CANCHA',
        etiquetaAccesible: 'Tipo de cancha',
        valor: deporte == null
            ? null
            : tipo == null
            ? 'Todos los tipos'
            : catalogo.tipoCorto(deporte.clave, tipo),
        placeholder: 'Todos los tipos',
        icono: Icons.expand_more_rounded,
        alTocar: deporte == null || _consultando
            ? null
            : () => _elegirTipo(catalogo),
      ),
      const SizedBox(height: Medidas.s12),
      CampoTexto(
        etiqueta: 'FECHA',
        etiquetaAccesible: 'Fecha',
        controlador: _fecha,
        placeholder: 'DD / MM / AAAA',
        error: errores['fecha'],
        teclado: TextInputType.number,
        formateadores: const [FormatoFecha()],
        habilitado: !_consultando,
        accionFinal: IconButton(
          tooltip: 'Elegir la fecha en el calendario',
          onPressed: _consultando ? null : _elegirFecha,
          icon: Icon(
            Icons.calendar_today_outlined,
            color: context.paleta.textSecondary,
          ),
        ),
      ),
      const SizedBox(height: Medidas.s12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CampoSelector(
              etiqueta: 'DESDE',
              etiquetaAccesible: 'Desde',
              valor: hhmm(_desde),
              placeholder: '',
              icono: Icons.expand_more_rounded,
              alTocar: _consultando ? null : () => _elegirHora(inicio: true),
              error: errores['desde'],
            ),
          ),
          const SizedBox(width: Medidas.s12),
          Expanded(
            child: CampoSelector(
              etiqueta: 'HASTA',
              etiquetaAccesible: 'Hasta',
              valor: hhmm(_hasta),
              placeholder: '',
              icono: Icons.expand_more_rounded,
              alTocar: _consultando ? null : () => _elegirHora(inicio: false),
              error: errores['hasta'],
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _resultados(
    _Consulta consulta,
    List<Espacio> resultado,
    Catalogo catalogo,
    Paleta p,
  ) {
    final techada = _techada;
    final vistas = [
      for (final c in resultado)
        if (techada == null || c.techada == techada) c,
    ];
    final rango = '${hhmm(consulta.desde)} – ${hhmm(consulta.hasta)}';
    final que = _queSeBusco(consulta, catalogo).toUpperCase();
    final encabezado = resultado.isEmpty
        ? 'SIN DISPONIBILIDAD · $que · $rango'
        : resultado.length == 1
        ? '1 CANCHA DISPONIBLE · $que · $rango'
        : '${resultado.length} CANCHAS DISPONIBLES · $que · $rango';
    final aireLibre = resultado.where((c) => !c.techada).length;
    return [
      const SizedBox(height: Medidas.s24),
      if (resultado.isNotEmpty) ...[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (final (valor, cuantas) in [
                (null, resultado.length),
                (false, aireLibre),
                (true, resultado.length - aireLibre),
              ]) ...[
                _ChipCondicion(
                  texto:
                      '${switch (valor) {
                        null => 'Todas',
                        false => 'Al aire libre',
                        true => 'Techada',
                      }} ($cuantas)',
                  elegido: techada == valor,
                  alTocar: cuantas == 0
                      ? null
                      : () => setState(() => _techada = valor),
                ),
                const SizedBox(width: Medidas.s8),
              ],
            ],
          ),
        ),
        const SizedBox(height: Medidas.s12),
      ],
      Semantics(
        liveRegion: true,
        child: Text(
          encabezado,
          style: Textos.sobretitulo.copyWith(color: p.accentInk),
        ),
      ),
      const SizedBox(height: Medidas.s12),
      if (resultado.isEmpty)
        EstadoVacio(
          titulo: 'No hay canchas disponibles',
          texto:
              'Ninguna cancha coincide con ese horario. Probá con otro rango o '
              'otra sede.',
          accion: 'LIMPIAR FILTROS',
          alTocar: _limpiar,
        ),
      for (final cancha in vistas) ...[
        TarjetaCancha(
          cancha: cancha,
          catalogo: catalogo,
          alReservar: () => _aLosHorarios(consulta, cancha),
        ),
        const SizedBox(height: Medidas.s16),
      ],
    ];
  }

  void _aLosHorarios(_Consulta consulta, Espacio cancha) {
    final f = consulta.fecha;
    final fin = consulta.hasta == 0 ? 24 : consulta.hasta;
    final ruta = Uri(
      path: '/sedes/${consulta.sede.id}/canchas/${cancha.id}',
      queryParameters: {
        'fecha':
            '${f.year}-${f.month.toString().padLeft(2, '0')}-'
            '${f.day.toString().padLeft(2, '0')}',
        'horas': '${fin - consulta.desde}',
        'inicio': hhmm(consulta.desde),
      },
    );
    // Encima de la búsqueda: al volver, los filtros y el resultado siguen ahí.
    context.push(ruta.toString());
  }
}

class _ChipCondicion extends StatelessWidget {
  const _ChipCondicion({
    required this.texto,
    required this.elegido,
    required this.alTocar,
  });

  final String texto;
  final bool elegido;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      container: true,
      button: true,
      selected: elegido,
      enabled: alTocar != null,
      label: texto,
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
            constraints: const BoxConstraints(minHeight: Medidas.s48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Medidas.s16),
              child: Center(
                widthFactor: 1,
                child: Text(
                  texto,
                  style: Textos.cuerpoFuerte.copyWith(
                    color: elegido
                        ? p.accentOn
                        : alTocar == null
                        ? p.textMuted
                        : p.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `Card-Error` del prototipo: la consulta falló y los filtros siguen cargados.
class _TarjetaError extends StatelessWidget {
  const _TarjetaError({
    required this.sinConexion,
    required this.alVolver,
    required this.alReintentar,
  });

  final bool sinConexion;
  final VoidCallback alVolver;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(Medidas.s16),
        decoration: BoxDecoration(
          color: p.stateDangerMuted,
          borderRadius: BorderRadius.circular(Medidas.radioLg),
          border: Border.all(color: p.stateDanger),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'NO SE PUDO CONSULTAR',
              style: Textos.sobretitulo.copyWith(color: p.stateDangerInk),
            ),
            const SizedBox(height: Medidas.s4),
            Text(
              'No se pudo consultar la disponibilidad',
              style: Textos.titulo.copyWith(color: p.textPrimary),
            ),
            const SizedBox(height: Medidas.s4),
            Text(
              '${sinConexion ? 'Revisá tu conexión e intentá nuevamente.' : 'El servidor no respondió. Intentá más tarde.'}'
              ' Los filtros que cargaste se mantienen.',
              style: Textos.cuerpo.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: Medidas.s12),
            Row(
              children: [
                BotonTexto(texto: 'VOLVER', alTocar: alVolver),
                const SizedBox(width: Medidas.s8),
                Expanded(
                  child: BotonContorno(
                    texto: 'REINTENTAR',
                    alTocar: alReintentar,
                    peligro: true,
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

class _BarraAccion extends StatelessWidget {
  const _BarraAccion({
    required this.alLimpiar,
    required this.alConsultar,
    required this.consultando,
  });

  final VoidCallback? alLimpiar;
  final VoidCallback? alConsultar;
  final bool consultando;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.bgSurface,
        border: Border(top: BorderSide(color: p.borderDefault)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Medidas.s24,
            Medidas.s16,
            Medidas.s24,
            Medidas.s16,
          ),
          child: Row(
            children: [
              BotonTexto(texto: 'LIMPIAR', alTocar: alLimpiar),
              const SizedBox(width: Medidas.s12),
              Expanded(
                child: BotonPrimario(
                  texto: 'CONSULTAR',
                  alTocar: alConsultar,
                  cargando: consultando,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
