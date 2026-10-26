import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_superior.dart';
import '../comun/boton.dart';
import '../comun/campo_texto.dart';
import '../comun/dialogo_error.dart';
import '../comun/faltantes.dart';
import '../comun/fechas.dart';
import '../comun/selector.dart';
import '../sedes/sede.dart';
import '../sedes/sedes.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'baja_sede.dart';

enum _Campo { nombre, direccion, apertura, cierre, dias }

const _largoNombre = 60;
const _largoDireccion = 80;
final _calleYAltura = RegExp(r'^.*\S\s+(\d{1,6})$');

/// `HH:MM` a la hora; `null` si no es una hora en punto.
int? _deHora(String hhmm) => switch (hhmm.split(':')) {
  [final h, '00'] => int.tryParse(h),
  _ => null,
};

/// El formulario de una sede: nombre, dirección, apertura, cierre y días que abre. Sin
/// [editando] da de alta una sede nueva; con [editando], corrige esa.
class PantallaFormularioSede extends StatefulWidget {
  const PantallaFormularioSede({
    super.key,
    required this.sedes,
    required this.sesion,
    this.editando,
  });

  final Sedes sedes;
  final Sesion sesion;
  final Sede? editando;

  @override
  State<PantallaFormularioSede> createState() => _PantallaFormularioSedeState();
}

class _PantallaFormularioSedeState extends State<PantallaFormularioSede> {
  late final _nombre = TextEditingController(text: widget.editando?.nombre);
  late final _direccion = TextEditingController(
    text: widget.editando?.direccion,
  );
  final _focoNombre = FocusNode();
  final _focoDireccion = FocusNode();
  late int? _apertura = switch (widget.editando) {
    final s? => _deHora(s.apertura),
    null => null,
  };
  late int? _cierre = switch (widget.editando) {
    final s? => _deHora(s.cierre),
    null => null,
  };
  late List<int> _dias =
      widget.editando?.dias ?? DiasQueAbre.lunesADomingo.dias;
  final _tocados = <_Campo>{};
  final _erroresDelServidor = <_Campo, String>{};
  bool _intentoGuardar = false;
  bool _enviando = false;
  bool _dandoDeBaja = false;

  /// Guardando o dando de baja: el formulario no se toca ni se sale.
  bool get _ocupado => _enviando || _dandoDeBaja;

  /// Un envío anterior se cortó: la API pudo haber guardado la sede sin que llegara la
  /// respuesta.
  bool _huboCorte = false;

  bool get _editando => widget.editando != null;

  @override
  void initState() {
    super.initState();
    for (final (foco, campo) in [
      (_focoNombre, _Campo.nombre),
      (_focoDireccion, _Campo.direccion),
    ]) {
      foco.addListener(() {
        // Salir de un campo vacío no marca nada: eso lo hace el intento de guardar.
        if (!foco.hasFocus && _controlador(campo).text.trim().isNotEmpty) {
          setState(() => _tocados.add(campo));
        }
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
        setState(() {
          _erroresDelServidor.remove(campo);
          // En la edición los datos ya vienen cargados: el error se ve apenas se escribe.
          if (_editando) _tocados.add(campo);
        });
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

  TextEditingController _controlador(_Campo campo) =>
      campo == _Campo.nombre ? _nombre : _direccion;

  String? _error(_Campo campo) => errorAMostrar(
    delServidor: _erroresDelServidor[campo],
    deRegla: _errorDeRegla(campo),
    intentado: _intentoGuardar,
    tocado: _tocados.contains(campo),
  );

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
      opciones: [for (final h in horas) (h, horaCerrada(h))],
      columnas: 4,
      elegida: esCierre ? _cierre : _apertura,
    );
    if (!mounted) return;
    setState(() {
      if (elegida == null) return;
      _tocados.add(campo);
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
      elegida: DiasQueAbre.values
          .where((d) => diasDeLaSemana(d.dias) == diasDeLaSemana(_dias))
          .firstOrNull,
    );
    if (elegidos == null || !mounted) return;
    setState(() {
      _dias = elegidos.dias;
      _erroresDelServidor.remove(_Campo.dias);
    });
  }

  Future<Sede> _enviar(int apertura, int cierre, {required bool confirmar}) {
    final nombre = _nombre.text.trim();
    final direccion = _direccion.text.trim();
    final sede = widget.editando;
    return sede == null
        ? widget.sedes.darDeAlta(
            nombre: nombre,
            direccion: direccion,
            apertura: horaCerrada(apertura),
            cierre: horaCerrada(cierre),
            dias: _dias,
          )
        : widget.sedes.editar(
            sede.id,
            nombre: nombre,
            direccion: direccion,
            apertura: horaCerrada(apertura),
            cierre: horaCerrada(cierre),
            dias: _dias,
            confirmar: confirmar,
          );
  }

  void _listo(Sede sede) {
    if (!_editando) {
      context.go('/admin/sedes/creada', extra: sede);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Los cambios se guardaron correctamente')),
    );
    context.go('/admin/sedes');
  }

  Future<void> _guardar({bool confirmar = false}) async {
    final apertura = _apertura;
    final cierre = _cierre;
    if (_ocupado) return;
    if (!_completo || apertura == null || cierre == null) {
      setState(() => _intentoGuardar = true);
      enfocarElPrimerFaltante([
        (_focoNombre, _errorDeRegla(_Campo.nombre)),
        (_focoDireccion, _errorDeRegla(_Campo.direccion)),
        (null, _errorDeRegla(_Campo.apertura)),
        (null, _errorDeRegla(_Campo.cierre)),
      ]);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _enviando = true);
    Object? fallo;
    var vencida = false;
    int? afuera;
    var yaNoEsta = false;
    try {
      final sede = await _enviar(apertura, cierre, confirmar: confirmar);
      if (mounted) _listo(sede);
      return;
    } on ReservasAfuera catch (e) {
      afuera = e.cantidad;
    } on SedeNoDisponible {
      yaNoEsta = true;
    } on SedeRechazada catch (e) {
      final guardada = !_editando && e.repetido && _huboCorte
          ? await _laQueSeGuardo(apertura, cierre)
          : null;
      if (guardada != null) {
        if (mounted) _listo(guardada);
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
    if (afuera case final n?) {
      final guardarIgual = await confirmarHorarioNuevo(
        context,
        _textoDeAfuera(n, apertura, cierre),
      );
      if (guardarIgual && mounted) await _guardar(confirmar: true);
    } else if (yaNoEsta) {
      await mostrarCambioMientrasTanto(context);
      widget.sedes.avisarCambio();
      if (mounted) context.go('/admin/sedes');
    } else if (vencida) {
      await mostrarSesionVencida(context);
      if (mounted) await cerrarSesion(context, widget.sesion);
    } else if (fallo != null) {
      final reintentar = await mostrarErrorDeRed(context, fallo);
      if (reintentar && mounted) await _guardar(confirmar: confirmar);
    }
  }

  /// «2 reservas futuras de Sede Morón empiezan antes de las 09:00…», según qué se achicó.
  String _textoDeAfuera(int n, int apertura, int cierre) {
    final antes = widget.editando;
    final una = n == 1;
    final sujeto =
        '$n ${una ? 'reserva futura' : 'reservas futuras'} de ${antes?.nombre}';
    final hasta = cierre == 0 ? 24 : cierre;
    final antesApertura = antes == null ? null : _deHora(antes.apertura);
    final antesCierre = switch (antes == null ? null : _deHora(antes.cierre)) {
      0 => 24,
      final c => c,
    };
    final motivos = [
      if (antesApertura != null && apertura > antesApertura)
        '${una ? 'empieza' : 'empiezan'} antes de las ${horaCerrada(apertura)}',
      if (antesCierre != null && hasta < antesCierre)
        '${una ? 'termina' : 'terminan'} después de las ${horaCerrada(cierre)}',
      if (antes != null && antes.dias.any((d) => !_dias.contains(d)))
        '${una ? 'cae' : 'caen'} en un día que la sede deja de abrir',
    ];
    final motivo = motivos.length == 1
        ? motivos.single
        : '${una ? 'queda' : 'quedan'} fuera del horario nuevo';
    return '$sujeto $motivo. Si guardás, ${una ? 'se mantiene' : 'se mantienen'} '
        'en su horario original: el cambio rige para las reservas nuevas.';
  }

  Future<void> _darDeBaja() async {
    final sede = widget.editando;
    if (sede == null) return;
    await darDeBajaSede(
      context,
      sede: sede,
      sedes: widget.sedes,
      sesion: widget.sesion,
      volverAlListado: true,
      enviando: (enCamino) {
        if (mounted) setState(() => _dandoDeBaja = enCamino);
      },
    );
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
                s.apertura == horaCerrada(apertura) &&
                s.cierre == horaCerrada(cierre) &&
                diasDeLaSemana(s.dias) == diasDeLaSemana(_dias),
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
    final editando = widget.editando;
    // Mientras se guarda no se sale: la sede se guardaría sin que se viera el éxito.
    return PopScope(
      canPop: !_ocupado,
      child: Scaffold(
        backgroundColor: p.bgBase,
        appBar: BarraSuperior(
          titulo: editando == null ? 'Agregar sede' : 'Editar sede',
        ),
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
                    editando?.nombre ?? 'Nueva sede',
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
                  habilitado: !_ocupado,
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
                  placeholder: editando == null
                      ? 'Calle y altura'
                      : 'Escribí la dirección',
                  error: _error(_Campo.direccion),
                  habilitado: !_ocupado,
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
                  valor: apertura == null ? null : horaCerrada(apertura),
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
                  valor: cierre == null ? null : horaCerrada(cierre),
                  placeholder: '23:00',
                  icono: Icons.schedule_rounded,
                  error: _error(_Campo.cierre),
                  alTocar: _ocupado ? null : () => _elegirHora(_Campo.cierre),
                ),
                const SizedBox(height: Medidas.s12),
                CampoSelector(
                  etiqueta: 'DÍAS QUE ABRE',
                  etiquetaAccesible: 'Días que abre',
                  valor: diasDeLaSemana(_dias),
                  placeholder: DiasQueAbre.lunesADomingo.texto,
                  icono: Icons.expand_more_rounded,
                  error: _error(_Campo.dias),
                  alTocar: _ocupado ? null : _elegirDias,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BarraDeAccion(
          child: editando == null
              ? BotonPrimario(
                  texto: 'GUARDAR SEDE',
                  cargando: _enviando,
                  atenuado: !_completo,
                  alTocar: _guardar,
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BotonPrimario(
                      texto: 'GUARDAR CAMBIOS',
                      cargando: _enviando,
                      atenuado: !_completo,
                      alTocar: _dandoDeBaja ? null : _guardar,
                    ),
                    const SizedBox(height: Medidas.s12),
                    if (_dandoDeBaja)
                      Semantics(
                        label: 'Dando de baja la sede',
                        excludeSemantics: true,
                        child: const SizedBox(
                          height: Medidas.altoControl,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      )
                    else
                      BotonContorno(
                        texto: 'DAR DE BAJA LA SEDE',
                        peligro: true,
                        alTocar: _enviando ? null : _darDeBaja,
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
