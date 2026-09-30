import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_superior.dart';
import '../comun/boton.dart';
import '../comun/campo_texto.dart';
import '../comun/dialogo_error.dart';
import '../comun/formato_precio.dart';
import '../comun/selector.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'baja_espacio.dart';
import 'pantalla_alta_espacio.dart';

const _obligatorio = 'Este campo es obligatorio';
const _precioMaximo = 9999999;

/// «Editar espacio deportivo»: condición, iluminación y precio. La sede, el deporte, el
/// tipo y el nombre compuesto se ven pero no cambian.
class PantallaEditarEspacio extends StatefulWidget {
  const PantallaEditarEspacio({
    super.key,
    required this.espacio,
    required this.espacios,
    required this.sesion,
  });

  final Espacio espacio;
  final Espacios espacios;
  final Sesion sesion;

  @override
  State<PantallaEditarEspacio> createState() => _PantallaEditarEspacioState();
}

class _PantallaEditarEspacioState extends State<PantallaEditarEspacio> {
  late bool _techada = widget.espacio.techada;
  late bool _iluminada = widget.espacio.iluminada;
  late final _precio = TextEditingController(
    text: pesos(widget.espacio.precioPorHora),
  );
  Catalogo? _catalogo;
  String? _errorDelServidor;
  bool _enviando = false;
  bool _dandoDeBaja = false;

  /// Guardando o dando de baja: el formulario no se toca ni se sale.
  bool get _ocupado => _enviando || _dandoDeBaja;

  @override
  void initState() {
    super.initState();
    var anterior = _precio.text;
    _precio.addListener(() {
      if (_precio.text == anterior) return;
      anterior = _precio.text;
      setState(() => _errorDelServidor = null);
    });
    _leerCatalogo();
  }

  @override
  void dispose() {
    _precio.dispose();
    super.dispose();
  }

  /// Sólo para mostrar el deporte y el tipo con su nombre: si no llega, se ven las claves.
  Future<void> _leerCatalogo() async {
    try {
      final catalogo = await widget.espacios.catalogo();
      if (mounted) setState(() => _catalogo = catalogo);
    } on Exception {
      return;
    }
  }

  String? get _errorDePrecio {
    final precio = leerPrecio(_precio.text);
    if (precio == null) return _obligatorio;
    return precio < 1 || precio > _precioMaximo
        ? 'Ingresá un precio entre \$ 1 y \$ 9.999.999'
        : null;
  }

  bool get _cambio {
    final e = widget.espacio;
    return _techada != e.techada ||
        _iluminada != e.iluminada ||
        leerPrecio(_precio.text) != e.precioPorHora;
  }

  bool get _sePuedeGuardar =>
      _cambio && _errorDePrecio == null && _errorDelServidor == null;

  Future<void> _elegirSiNo({required bool condicion}) async {
    final elegido = await elegirOpcion<bool>(
      context,
      titulo: condicion ? 'Condición' : 'Iluminación',
      opciones: condicion
          ? const [(false, 'Al aire libre'), (true, 'Techada')]
          : const [(true, 'Iluminada'), (false, 'Sin iluminación')],
      elegida: condicion ? _techada : _iluminada,
    );
    if (elegido == null || !mounted) return;
    setState(() {
      if (condicion) {
        _techada = elegido;
      } else {
        _iluminada = elegido;
      }
      _errorDelServidor = null;
    });
  }

  Future<void> _guardar() async {
    final precio = leerPrecio(_precio.text);
    if (_ocupado || !_sePuedeGuardar || precio == null) return;
    FocusScope.of(context).unfocus();
    setState(() => _enviando = true);
    Object? fallo;
    var vencida = false;
    var yaNoEsta = false;
    try {
      final e = widget.espacio;
      await widget.espacios.editar(
        e.id,
        techada: _techada == e.techada ? null : _techada,
        iluminada: _iluminada == e.iluminada ? null : _iluminada,
        precioPorHora: precio == e.precioPorHora ? null : precio,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Los cambios se guardaron correctamente')),
      );
      context.go('/admin/espacios');
      return;
    } on EspacioNoDisponible {
      yaNoEsta = true;
    } on EspacioRechazado catch (e) {
      if (mounted) {
        setState(
          () => _errorDelServidor =
              e.errores['precio_por_hora'] ?? e.errores.values.firstOrNull,
        );
      }
    } on SesionVencida {
      vencida = true;
    } on SinConexion catch (e) {
      fallo = e;
    } on ErrorDelServidor catch (e) {
      fallo = e;
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
    if (!mounted) return;
    if (yaNoEsta) {
      await mostrarCambioMientrasTanto(context);
      widget.espacios.avisarCambio();
      if (mounted) context.go('/admin/espacios');
    } else if (vencida) {
      await mostrarSesionVencida(context);
      if (mounted) await cerrarSesion(context, widget.sesion);
    } else if (fallo != null) {
      final reintentar = await mostrarErrorDeRed(context, fallo);
      if (reintentar && mounted) await _guardar();
    }
  }

  Future<void> _darDeBaja() async {
    await darDeBajaEspacio(
      context,
      espacio: widget.espacio,
      espacios: widget.espacios,
      sesion: widget.sesion,
      volverAlListado: true,
      enviando: (enCamino) {
        if (mounted) setState(() => _dandoDeBaja = enCamino);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final e = widget.espacio;
    final catalogo = _catalogo;
    final deporte = catalogo?.deporte(e.deporte)?.nombre ?? e.deporte;
    final tipo = catalogo?.tipoCorto(e.deporte, e.tipo) ?? e.tipo;
    // El precio cargado vale: el error se ve recién cuando se lo cambia.
    final errorDePrecio =
        _errorDelServidor ??
        (leerPrecio(_precio.text) == e.precioPorHora ? null : _errorDePrecio);
    return PopScope(
      // Mientras se guarda no se sale: el cambio quedaría hecho sin que se viera.
      canPop: !_ocupado,
      child: Scaffold(
        backgroundColor: p.bgBase,
        appBar: const BarraSuperior(titulo: 'Editar espacio'),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              Medidas.s24,
              Medidas.s12,
              Medidas.s24,
              Medidas.s40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Editar espacio deportivo',
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
                  valor: e.sede,
                  placeholder: '',
                  icono: Icons.expand_more_rounded,
                  alTocar: null,
                  soloLectura: true,
                ),
                const SizedBox(height: Medidas.s12),
                CampoSelector(
                  etiqueta: 'DEPORTE',
                  etiquetaAccesible: 'Deporte',
                  valor: deporte,
                  placeholder: '',
                  icono: Icons.expand_more_rounded,
                  alTocar: null,
                  soloLectura: true,
                ),
                const SizedBox(height: Medidas.s12),
                CampoSelector(
                  etiqueta: 'TIPO',
                  etiquetaAccesible: 'Tipo',
                  valor: tipo,
                  placeholder: '',
                  icono: Icons.expand_more_rounded,
                  alTocar: null,
                  soloLectura: true,
                ),
                const SizedBox(height: Medidas.s12),
                ParDeCampos(
                  izquierda: CampoSelector(
                    etiqueta: 'CONDICIÓN',
                    etiquetaAccesible: 'Condición',
                    valor: _techada ? 'Techada' : 'Al aire libre',
                    placeholder: '',
                    icono: Icons.expand_more_rounded,
                    alTocar: _ocupado
                        ? null
                        : () => _elegirSiNo(condicion: true),
                  ),
                  derecha: CampoSelector(
                    etiqueta: 'ILUMINACIÓN',
                    etiquetaAccesible: 'Iluminación',
                    valor: _iluminada ? 'Iluminada' : 'Sin iluminación',
                    placeholder: '',
                    icono: Icons.expand_more_rounded,
                    alTocar: _ocupado
                        ? null
                        : () => _elegirSiNo(condicion: false),
                  ),
                ),
                const SizedBox(height: Medidas.s12),
                CampoTexto(
                  etiqueta: 'PRECIO POR HORA',
                  etiquetaAccesible: 'Precio por hora',
                  controlador: _precio,
                  placeholder: '\$ 0',
                  error: errorDePrecio,
                  habilitado: !_ocupado,
                  teclado: TextInputType.number,
                  accion: TextInputAction.done,
                  formateadores: const [FormatoPrecio()],
                ),
                const SizedBox(height: Medidas.s16),
                NombreGenerado(nombre: e.nombre),
                const SizedBox(height: Medidas.s16),
                BotonPrimario(
                  texto: 'GUARDAR ESPACIO',
                  cargando: _enviando,
                  alTocar: _sePuedeGuardar && !_dandoDeBaja ? _guardar : null,
                ),
                const SizedBox(height: Medidas.s12),
                BotonContorno(
                  texto: 'CANCELAR',
                  alTocar: _ocupado
                      ? null
                      : () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(height: Medidas.s12),
                if (_dandoDeBaja)
                  Semantics(
                    label: 'Dando de baja el espacio',
                    excludeSemantics: true,
                    child: const SizedBox(
                      height: Medidas.altoControl,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else
                  BotonContorno(
                    texto: 'DAR DE BAJA EL ESPACIO',
                    peligro: true,
                    alTocar: _ocupado ? null : _darDeBaja,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
