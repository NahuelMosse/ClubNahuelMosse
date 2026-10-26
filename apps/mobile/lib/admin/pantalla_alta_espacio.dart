import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_superior.dart';
import '../comun/boton.dart';
import '../comun/campo_texto.dart';
import '../comun/dialogo_error.dart';
import '../comun/formato_precio.dart';
import '../comun/selector.dart';
import '../comun/snackbar.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../sedes/sede.dart';
import '../sedes/sedes.dart';
import '../sesion/fallo_de_carga.dart';
import '../sesion/sesion.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'formulario_espacio.dart';
import 'par_de_campos.dart';
import 'nombre_generado.dart';

enum _Campo {
  sede('sede_id'),
  deporte('deporte'),
  tipo('tipo'),
  condicion('techada'),
  iluminacion('iluminada'),
  precio('precio_por_hora');

  const _Campo(this.clave);

  /// El nombre del campo en la API.
  final String clave;
}

/// Alta de espacio deportivo: sede, deporte, tipo, condición, iluminación y precio, con el
/// nombre compuesto que calcula la API a la vista.
class PantallaAltaEspacio extends StatefulWidget {
  const PantallaAltaEspacio({
    super.key,
    required this.espacios,
    required this.sedes,
    required this.sesion,
  });

  final Espacios espacios;
  final Sedes sedes;
  final Sesion sesion;

  @override
  State<PantallaAltaEspacio> createState() => _PantallaAltaEspacioState();
}

class _PantallaAltaEspacioState extends State<PantallaAltaEspacio> {
  List<Sede>? _opcionesDeSede;
  Catalogo? _catalogo;
  bool _cargando = true;

  Sede? _sede;
  Deporte? _deporte;
  TipoDeCancha? _tipo;
  bool? _techada;
  bool? _iluminada;
  final _precio = TextEditingController();

  /// El nombre compuesto y el número que calculó la API para la sede, el deporte y el tipo
  /// elegidos.
  (String, int)? _sugerido;
  bool _calculando = false;
  int _pedidoDeNombre = 0;

  /// Por qué no se pudo calcular el nombre, para ofrecer reintentar.
  Object? _falloDelNombre;

  final _erroresDelServidor = <_Campo, String>{};
  String? _aviso;
  bool _intentoGuardar = false;
  bool _enviando = false;
  final _claveDelAviso = GlobalKey();

  @override
  void initState() {
    super.initState();
    var anterior = _precio.text;
    _precio.addListener(() {
      if (_precio.text == anterior) return;
      anterior = _precio.text;
      setState(() => _erroresDelServidor.remove(_Campo.precio));
    });
    _cargar();
  }

  @override
  void dispose() {
    _precio.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    Object? fallo;
    var vencida = false;
    try {
      final catalogo = await widget.espacios.catalogo();
      final sedes = await widget.sedes.activas();
      if (!mounted) return;
      setState(() {
        _catalogo = catalogo;
        _opcionesDeSede = sedes;
        _cargando = false;
      });
      return;
    } on SesionVencida {
      vencida = true;
    } on FalloDeRed catch (e) {
      fallo = e;
    }
    if (!mounted) return;
    setState(() => _cargando = false);
    if (vencida) {
      await avisarSesionVencida(context, widget.sesion);
    } else if (fallo != null) {
      final resultado = await atenderErrorDeRed(context, fallo);
      if (!mounted) return;
      if (resultado == ResultadoDeError.reintentar) {
        await _cargar();
      } else if (resultado == ResultadoDeError.cerrado) {
        context.go('/admin/espacios');
      }
    }
  }

  /// Pide a la API el nombre del próximo espacio; si mientras tanto cambió la elección, la
  /// respuesta vieja se descarta.
  Future<void> _calcularNombre() async {
    final sede = _sede;
    final deporte = _deporte;
    final tipo = _tipo;
    final pedido = ++_pedidoDeNombre;
    setState(() {
      _sugerido = null;
      _falloDelNombre = null;
      _calculando = sede != null && deporte != null && tipo != null;
    });
    if (sede == null || deporte == null || tipo == null) return;
    var vencida = false;
    try {
      final sugerido = await widget.espacios.nombreSugerido(
        sedeId: sede.id,
        deporte: deporte.clave,
        tipo: tipo.clave,
      );
      if (mounted && pedido == _pedidoDeNombre) {
        setState(() => _sugerido = sugerido);
      }
    } on EspacioRechazado catch (e) {
      if (mounted && pedido == _pedidoDeNombre) _mostrarErrores(e.errores);
    } on SesionVencida {
      vencida = true;
    } on SinConexion catch (e) {
      if (mounted && pedido == _pedidoDeNombre) {
        setState(() => _falloDelNombre = e);
      }
    } on ErrorDelServidor catch (e) {
      if (mounted && pedido == _pedidoDeNombre) {
        setState(() => _falloDelNombre = e);
      }
    } finally {
      if (mounted && pedido == _pedidoDeNombre) {
        setState(() => _calculando = false);
      }
    }
    if (vencida && mounted && pedido == _pedidoDeNombre) {
      await avisarSesionVencida(context, widget.sesion);
    }
  }

  void _mostrarErrores(Map<String, String> errores) {
    setState(() {
      for (final MapEntry(:key, :value) in errores.entries) {
        final campo = _Campo.values.where((c) => c.clave == key).firstOrNull;
        if (campo != null) _erroresDelServidor[campo] = value;
      }
    });
  }

  String? _errorDeRegla(_Campo campo) {
    switch (campo) {
      case _Campo.sede:
        return _sede == null ? obligatorio : null;
      case _Campo.deporte:
        return _deporte == null ? obligatorio : null;
      case _Campo.tipo:
        return _tipo == null ? obligatorio : null;
      case _Campo.condicion:
        return _techada == null ? obligatorio : null;
      case _Campo.iluminacion:
        return _iluminada == null ? obligatorio : null;
      case _Campo.precio:
        return errorDePrecio(_precio.text);
    }
  }

  String? _error(_Campo campo) =>
      _erroresDelServidor[campo] ??
      (_intentoGuardar ? _errorDeRegla(campo) : null);

  bool get _completo =>
      _Campo.values.every((c) => _errorDeRegla(c) == null) &&
      _erroresDelServidor.isEmpty &&
      _sugerido != null;

  Future<void> _elegirSede() async {
    final opciones = _opcionesDeSede ?? const <Sede>[];
    final elegida = await elegirOpcion<Sede>(
      context,
      titulo: 'Sede',
      opciones: [for (final s in opciones) (s, s.nombre)],
      elegida: _sede,
    );
    if (elegida == null || !mounted || elegida == _sede) return;
    setState(() {
      _sede = elegida;
      _erroresDelServidor.remove(_Campo.sede);
    });
    await _calcularNombre();
  }

  Future<void> _elegirDeporte() async {
    final catalogo = _catalogo;
    if (catalogo == null) return;
    final elegido = await elegirOpcion<Deporte>(
      context,
      titulo: 'Deporte',
      opciones: [for (final d in catalogo.deportes) (d, d.nombre)],
      elegida: _deporte,
    );
    if (elegido == null || !mounted || elegido == _deporte) return;
    setState(() {
      _deporte = elegido;
      // Los tipos dependen del deporte: el que había elegido ya no corresponde.
      _tipo = null;
      _erroresDelServidor
        ..remove(_Campo.deporte)
        ..remove(_Campo.tipo);
    });
    await _calcularNombre();
  }

  Future<void> _elegirTipo() async {
    final deporte = _deporte;
    if (deporte == null) return;
    final elegido = await elegirOpcion<TipoDeCancha>(
      context,
      titulo: 'Tipo',
      opciones: [for (final t in deporte.tipos) (t, t.nombre)],
      elegida: _tipo,
    );
    if (elegido == null || !mounted || elegido == _tipo) return;
    setState(() {
      _tipo = elegido;
      _erroresDelServidor.remove(_Campo.tipo);
    });
    await _calcularNombre();
  }

  Future<void> _elegirSiNo(_Campo campo) async {
    final condicion = campo == _Campo.condicion;
    final elegido = await elegirSiNo(
      context,
      condicion: condicion,
      elegida: condicion ? _techada : _iluminada,
    );
    if (elegido == null || !mounted) return;
    setState(() {
      if (condicion) {
        _techada = elegido;
      } else {
        _iluminada = elegido;
      }
      _erroresDelServidor.remove(campo);
    });
  }

  Future<void> _guardar() async {
    if (_enviando || _calculando) return;
    if (_sugerido == null &&
        _sede != null &&
        _deporte != null &&
        _tipo != null) {
      await _calcularNombre();
      if (!mounted) return;
      final fallo = _falloDelNombre;
      if (fallo != null) {
        await avisarFalloDeEnvio(
          context,
          sesion: widget.sesion,
          vencida: false,
          error: fallo,
          reintentar: _guardar,
        );
        return;
      }
    }
    // Lo que se manda es lo que se ve ahora, aunque haya cambiado mientras se calculaba.
    final sede = _sede;
    final deporte = _deporte;
    final tipo = _tipo;
    final techada = _techada;
    final iluminada = _iluminada;
    final precio = leerPrecio(_precio.text);
    final sugerido = _sugerido;
    if (!_completo ||
        sede == null ||
        deporte == null ||
        tipo == null ||
        techada == null ||
        iluminada == null ||
        precio == null ||
        sugerido == null) {
      setState(() => _intentoGuardar = true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _enviando = true;
      _aviso = null;
    });
    Object? fallo;
    var vencida = false;
    try {
      final espacio = await widget.espacios.darDeAlta(
        sedeId: sede.id,
        deporte: deporte.clave,
        tipo: tipo.clave,
        techada: techada,
        iluminada: iluminada,
        precioPorHora: precio,
        numero: sugerido.$2,
      );
      if (mounted) context.go('/admin/espacios/creado', extra: espacio);
      return;
    } on NombreOcupado catch (e) {
      if (mounted) {
        setState(() {
          _aviso = e.mensaje;
          _sugerido = (e.nombre, e.numero);
        });
        // El aviso está arriba del formulario: se lo trae a la vista.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final aviso = _claveDelAviso.currentContext;
          if (aviso != null && aviso.mounted) Scrollable.ensureVisible(aviso);
        });
      }
    } on EspacioRechazado catch (e) {
      if (mounted) _mostrarErrores(e.errores);
    } on SesionVencida {
      vencida = true;
    } on FalloDeRed catch (e) {
      fallo = e;
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
    if (!mounted) return;
    await avisarFalloDeEnvio(
      context,
      sesion: widget.sesion,
      vencida: vencida,
      error: fallo,
      reintentar: _guardar,
    );
  }

  String get _faltaParaElNombre {
    if (_sede == null && _deporte == null && _tipo == null) {
      return 'Completá sede, deporte y tipo';
    }
    if (_sede == null) return 'Falta la sede';
    if (_deporte == null) return 'Falta el deporte';
    return 'Falta el tipo de cancha';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final aviso = _aviso;
    final sedes = _opcionesDeSede;
    final habilitado = !_enviando && !_cargando;
    return PopScope(
      // Mientras se guarda no se sale: el espacio se crearía sin que se viera el éxito.
      canPop: !_enviando,
      child: Scaffold(
        backgroundColor: p.bgBase,
        appBar: const BarraSuperior(titulo: 'Nuevo espacio'),
        body: SafeArea(
          top: false,
          child: _cargando && sedes == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    Medidas.s24,
                    Medidas.s12,
                    Medidas.s24,
                    Medidas.s40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (aviso != null) ...[
                        SnackbarError(
                          key: _claveDelAviso,
                          texto: aviso,
                          alCerrar: () => setState(() => _aviso = null),
                        ),
                        const SizedBox(height: Medidas.s16),
                      ],
                      Semantics(
                        header: true,
                        child: Text(
                          'Nuevo espacio deportivo',
                          style: Textos.h1.copyWith(color: p.textPrimary),
                        ),
                      ),
                      const SizedBox(height: Medidas.s4),
                      Text(
                        'El nombre se arma solo con la sede, la dirección, el deporte, '
                        'el tipo y el número.',
                        style: Textos.cuerpo.copyWith(color: p.textSecondary),
                      ),
                      const SizedBox(height: Medidas.s16),
                      CampoSelector(
                        etiqueta: 'SEDE',
                        etiquetaAccesible: 'Sede',
                        valor: _sede?.nombre,
                        placeholder: sedes == null || sedes.isNotEmpty
                            ? 'Seleccioná una sede'
                            : 'Todavía no hay sedes',
                        icono: Icons.expand_more_rounded,
                        error: _error(_Campo.sede),
                        alTocar: habilitado && (sedes?.isNotEmpty ?? false)
                            ? _elegirSede
                            : null,
                      ),
                      const SizedBox(height: Medidas.s12),
                      CampoSelector(
                        etiqueta: 'DEPORTE',
                        etiquetaAccesible: 'Deporte',
                        valor: _deporte?.nombre,
                        placeholder: 'Seleccioná un deporte',
                        icono: Icons.expand_more_rounded,
                        error: _error(_Campo.deporte),
                        alTocar: habilitado ? _elegirDeporte : null,
                      ),
                      const SizedBox(height: Medidas.s12),
                      CampoSelector(
                        etiqueta: 'TIPO',
                        etiquetaAccesible: 'Tipo',
                        valor: _tipo?.nombre,
                        placeholder: 'Seleccioná el tipo',
                        icono: Icons.expand_more_rounded,
                        error: _error(_Campo.tipo),
                        alTocar: habilitado && _deporte != null
                            ? _elegirTipo
                            : null,
                      ),
                      const SizedBox(height: Medidas.s12),
                      ParDeCampos(
                        izquierda: CampoSelector(
                          etiqueta: 'CONDICIÓN',
                          etiquetaAccesible: 'Condición',
                          valor: switch (_techada) {
                            true => 'Techada',
                            false => 'Al aire libre',
                            null => null,
                          },
                          placeholder: 'Seleccioná',
                          icono: Icons.expand_more_rounded,
                          error: _error(_Campo.condicion),
                          alTocar: habilitado
                              ? () => _elegirSiNo(_Campo.condicion)
                              : null,
                        ),
                        derecha: CampoSelector(
                          etiqueta: 'ILUMINACIÓN',
                          etiquetaAccesible: 'Iluminación',
                          valor: switch (_iluminada) {
                            true => 'Iluminada',
                            false => 'Sin iluminación',
                            null => null,
                          },
                          placeholder: 'Seleccioná',
                          icono: Icons.expand_more_rounded,
                          error: _error(_Campo.iluminacion),
                          alTocar: habilitado
                              ? () => _elegirSiNo(_Campo.iluminacion)
                              : null,
                        ),
                      ),
                      const SizedBox(height: Medidas.s12),
                      CampoTexto(
                        etiqueta: 'PRECIO POR HORA',
                        etiquetaAccesible: 'Precio por hora',
                        controlador: _precio,
                        placeholder: '\$ 0',
                        error: _error(_Campo.precio),
                        habilitado: habilitado,
                        teclado: TextInputType.number,
                        accion: TextInputAction.done,
                        formateadores: const [FormatoPrecio()],
                      ),
                      const SizedBox(height: Medidas.s16),
                      NombreGenerado(
                        nombre: _sugerido?.$1,
                        calculando: _calculando,
                        falta: _faltaParaElNombre,
                        alReintentar: _falloDelNombre == null || _enviando
                            ? null
                            : _calcularNombre,
                      ),
                      const SizedBox(height: Medidas.s16),
                      BotonPrimario(
                        texto: 'GUARDAR ESPACIO',
                        cargando: _enviando,
                        atenuado: !_completo,
                        alTocar: _guardar,
                      ),
                      const SizedBox(height: Medidas.s12),
                      BotonContorno(
                        texto: 'CANCELAR',
                        alTocar: _enviando
                            ? null
                            : () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
