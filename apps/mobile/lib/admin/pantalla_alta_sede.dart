import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_superior.dart';
import '../comun/boton.dart';
import '../comun/campo_texto.dart';
import '../comun/dialogo_error.dart';
import '../comun/selector.dart';
import '../sedes/sede.dart';
import '../sedes/sedes.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

enum _Campo { nombre, direccion, apertura, cierre, dias }

const _largoNombre = 60;
const _largoDireccion = 80;
final _calleYAltura = RegExp(r'^.*\S\s+(\d{1,6})$');

String _hora(int h) => '${h.toString().padLeft(2, '0')}:00';

/// Alta de sede: nombre, dirección, apertura, cierre y días que abre.
class PantallaAltaSede extends StatefulWidget {
  const PantallaAltaSede({
    super.key,
    required this.sedes,
    required this.sesion,
  });

  final Sedes sedes;
  final Sesion sesion;

  @override
  State<PantallaAltaSede> createState() => _PantallaAltaSedeState();
}

class _PantallaAltaSedeState extends State<PantallaAltaSede> {
  final _nombre = TextEditingController();
  final _direccion = TextEditingController();
  final _focoNombre = FocusNode();
  final _focoDireccion = FocusNode();
  int? _apertura;
  int? _cierre;
  var _dias = DiasQueAbre.lunesADomingo;
  final _tocados = <_Campo>{};
  final _erroresDelServidor = <_Campo, String>{};
  bool _intentoGuardar = false;
  bool _enviando = false;

  /// Un envío anterior se cortó: la API pudo haber guardado la sede sin que llegara la
  /// respuesta.
  bool _huboCorte = false;

  @override
  void initState() {
    super.initState();
    for (final (foco, campo) in [
      (_focoNombre, _Campo.nombre),
      (_focoDireccion, _Campo.direccion),
    ]) {
      foco.addListener(() {
        if (!foco.hasFocus) setState(() => _tocados.add(campo));
      });
    }
    for (final (controlador, campo) in [
      (_nombre, _Campo.nombre),
      (_direccion, _Campo.direccion),
    ]) {
      var anterior = controlador.text;
      controlador.addListener(() {
        // El controlador también avisa cuando se mueve el cursor: sólo cuenta el texto.
        if (controlador.text == anterior) return;
        anterior = controlador.text;
        setState(() => _erroresDelServidor.remove(campo));
      });
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _direccion.dispose();
    _focoNombre.dispose();
    _focoDireccion.dispose();
    super.dispose();
  }

  String? _errorDeRegla(_Campo campo) {
    switch (campo) {
      case _Campo.nombre:
        return _nombre.text.trim().isEmpty ? 'El nombre es obligatorio' : null;
      case _Campo.direccion:
        final direccion = _direccion.text.trim();
        if (direccion.isEmpty) return 'La dirección es obligatoria';
        final altura = _calleYAltura.firstMatch(direccion)?.group(1);
        return altura != null && int.parse(altura) > 0
            ? null
            : 'Escribí la calle y la altura';
      case _Campo.apertura:
        return _apertura == null
            ? 'El horario de apertura es obligatorio'
            : null;
      case _Campo.cierre:
        final cierre = _cierre;
        final apertura = _apertura;
        if (cierre == null) return 'El horario de cierre es obligatorio';
        // Cerrar a las 00:00 es cerrar a la medianoche.
        if (apertura != null && cierre != 0 && cierre <= apertura) {
          return 'El cierre tiene que ser después de la apertura';
        }
        return null;
      case _Campo.dias:
        return null;
    }
  }

  String? _error(_Campo campo) =>
      _erroresDelServidor[campo] ??
      (_intentoGuardar || _tocados.contains(campo)
          ? _errorDeRegla(campo)
          : null);

  bool get _completo =>
      _Campo.values.every((c) => _errorDeRegla(c) == null) &&
      _erroresDelServidor.isEmpty;

  Future<void> _elegirHora(_Campo campo) async {
    final esCierre = campo == _Campo.cierre;
    // El cierre a la medianoche va al final: es el último horario del día.
    final horas = esCierre
        ? [for (var h = 1; h < 24; h++) h, 0]
        : [for (var h = 0; h < 24; h++) h];
    final elegida = await elegirOpcion<int>(
      context,
      titulo: esCierre ? 'Horario de cierre' : 'Horario de apertura',
      opciones: [for (final h in horas) (h, _hora(h))],
      columnas: 4,
      elegida: esCierre ? _cierre : _apertura,
    );
    if (!mounted) return;
    setState(() {
      _tocados.add(campo);
      if (elegida == null) return;
      if (esCierre) {
        _cierre = elegida;
      } else {
        _apertura = elegida;
      }
      _erroresDelServidor
        ..remove(_Campo.apertura)
        ..remove(_Campo.cierre);
    });
  }

  Future<void> _elegirDias() async {
    final elegidos = await elegirOpcion<DiasQueAbre>(
      context,
      titulo: 'Días que abre',
      opciones: [for (final d in DiasQueAbre.values) (d, d.texto)],
      elegida: _dias,
    );
    if (elegidos == null || !mounted) return;
    setState(() {
      _dias = elegidos;
      _erroresDelServidor.remove(_Campo.dias);
    });
  }

  Future<void> _guardar() async {
    final apertura = _apertura;
    final cierre = _cierre;
    if (_enviando) return;
    if (!_completo || apertura == null || cierre == null) {
      setState(() => _intentoGuardar = true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _enviando = true);
    Object? fallo;
    var vencida = false;
    try {
      final sede = await widget.sedes.darDeAlta(
        nombre: _nombre.text.trim(),
        direccion: _direccion.text.trim(),
        apertura: _hora(apertura),
        cierre: _hora(cierre),
        dias: _dias.dias,
      );
      if (mounted) context.go('/admin/sedes/creada', extra: sede);
      return;
    } on SedeRechazada catch (e) {
      final guardada = e.repetido && _huboCorte
          ? await _laQueSeGuardo(apertura, cierre)
          : null;
      if (guardada != null) {
        if (mounted) context.go('/admin/sedes/creada', extra: guardada);
        return;
      }
      if (mounted) {
        setState(() {
          for (final MapEntry(:key, :value) in e.errores.entries) {
            final campo = _Campo.values.asNameMap()[key];
            if (campo != null) _erroresDelServidor[campo] = value;
          }
        });
      }
    } on SesionVencida {
      vencida = true;
    } on SinConexion catch (e) {
      _huboCorte = true;
      fallo = e;
    } on ErrorDelServidor catch (e) {
      fallo = e;
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
    if (!mounted) return;
    if (vencida) {
      await mostrarSesionVencida(context);
      if (mounted) await cerrarSesion(context, widget.sesion);
    } else if (fallo != null) {
      final reintentar = await mostrarErrorDeRed(context, fallo);
      if (reintentar && mounted) await _guardar();
    }
  }

  /// La sede que guardó el envío cortado, si es esta misma: así el reintento no la
  /// confunde con otra que ya tenía el nombre.
  Future<Sede?> _laQueSeGuardo(int apertura, int cierre) async {
    String normal(String texto) =>
        texto.trim().split(RegExp(r'\s+')).join(' ').toLowerCase();
    try {
      final sedes = await widget.sedes.activas();
      return sedes
          .where(
            (s) =>
                normal(s.nombre) == normal(_nombre.text) &&
                normal(s.direccion) == normal(_direccion.text) &&
                s.apertura == _hora(apertura) &&
                s.cierre == _hora(cierre) &&
                diasDeLaSemana(s.dias) == _dias.texto,
          )
          .firstOrNull;
    } on Exception {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final apertura = _apertura;
    final cierre = _cierre;
    // Mientras se guarda no se sale: la sede se crearía sin que se viera el éxito.
    return PopScope(
      canPop: !_enviando,
      child: Scaffold(
        backgroundColor: p.bgBase,
        appBar: const BarraSuperior(titulo: 'Agregar sede'),
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
                    'Nueva sede',
                    style: Textos.h1.copyWith(color: p.textPrimary),
                  ),
                ),
                const SizedBox(height: Medidas.s4),
                Text(
                  'Nombre, dirección y horarios son obligatorios.',
                  style: Textos.cuerpo.copyWith(color: p.textSecondary),
                ),
                const SizedBox(height: Medidas.s16),
                CampoTexto(
                  etiqueta: 'NOMBRE DE LA SEDE',
                  etiquetaAccesible: 'Nombre de la sede',
                  controlador: _nombre,
                  foco: _focoNombre,
                  placeholder: 'Ej. Sede Haedo',
                  error: _error(_Campo.nombre),
                  habilitado: !_enviando,
                  accion: TextInputAction.next,
                  formateadores: [
                    LengthLimitingTextInputFormatter(_largoNombre),
                  ],
                ),
                const SizedBox(height: Medidas.s12),
                CampoTexto(
                  etiqueta: 'DIRECCIÓN',
                  etiquetaAccesible: 'Dirección',
                  controlador: _direccion,
                  foco: _focoDireccion,
                  placeholder: 'Calle y altura',
                  error: _error(_Campo.direccion),
                  habilitado: !_enviando,
                  teclado: TextInputType.streetAddress,
                  autocompletar: const [AutofillHints.streetAddressLine1],
                  accion: TextInputAction.done,
                  formateadores: [
                    LengthLimitingTextInputFormatter(_largoDireccion),
                  ],
                ),
                const SizedBox(height: Medidas.s12),
                CampoSelector(
                  etiqueta: 'HORARIO DE APERTURA',
                  etiquetaAccesible: 'Horario de apertura',
                  valor: apertura == null ? null : _hora(apertura),
                  placeholder: '08:00',
                  icono: Icons.schedule_rounded,
                  error: _error(_Campo.apertura),
                  alTocar: _enviando
                      ? null
                      : () => _elegirHora(_Campo.apertura),
                ),
                const SizedBox(height: Medidas.s12),
                CampoSelector(
                  etiqueta: 'HORARIO DE CIERRE',
                  etiquetaAccesible: 'Horario de cierre',
                  valor: cierre == null ? null : _hora(cierre),
                  placeholder: '23:00',
                  icono: Icons.schedule_rounded,
                  error: _error(_Campo.cierre),
                  alTocar: _enviando ? null : () => _elegirHora(_Campo.cierre),
                ),
                const SizedBox(height: Medidas.s12),
                CampoSelector(
                  etiqueta: 'DÍAS QUE ABRE',
                  etiquetaAccesible: 'Días que abre',
                  valor: _dias.texto,
                  placeholder: DiasQueAbre.lunesADomingo.texto,
                  icono: Icons.expand_more_rounded,
                  error: _error(_Campo.dias),
                  alTocar: _enviando ? null : _elegirDias,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BarraDeAccion(
          child: BotonPrimario(
            texto: 'GUARDAR SEDE',
            cargando: _enviando,
            atenuado: !_completo,
            alTocar: _guardar,
          ),
        ),
      ),
    );
  }
}
