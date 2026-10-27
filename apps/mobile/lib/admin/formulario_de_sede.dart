import 'package:flutter/material.dart';

import '../api/cliente_api.dart';
import '../comun/faltantes.dart';
import '../comun/fechas.dart';
import '../sedes/sede.dart';
import '../sedes/sedes.dart';
import '../sesion/sesion.dart';
import 'campo_de_sede.dart';
import 'reglas_de_sede.dart';

/// Lo que quedó pendiente de atender tras un envío que no guardó la sede.
typedef PendienteDeSede = ({
  int? afuera,
  bool yaNoEsta,
  bool vencida,
  Object? fallo,
});

/// Lo que se escribió y se eligió en el formulario de una sede, con sus errores y el envío.
/// Sin [editando] da de alta una sede nueva; con [editando], corrige esa. Avisa cada cambio.
class FormularioDeSede extends ChangeNotifier {
  FormularioDeSede({required this.sedes, this.editando})
    : nombre = TextEditingController(text: editando?.nombre),
      direccion = TextEditingController(text: editando?.direccion),
      apertura = editando == null ? null : deHora(editando.apertura),
      cierre = editando == null ? null : deHora(editando.cierre),
      dias = editando?.dias ?? DiasQueAbre.lunesADomingo.dias {
    for (final (foco, campo) in [
      (focoNombre, CampoDeSede.nombre),
      (focoDireccion, CampoDeSede.direccion),
    ]) {
      foco.addListener(() {
        // Salir de un campo vacío no marca nada: eso lo hace el intento de guardar.
        if (!foco.hasFocus && _controlador(campo).text.trim().isNotEmpty) {
          tocados.add(campo);
          notifyListeners();
        }
      });
    }
    for (final (controlador, campo) in [
      (nombre, CampoDeSede.nombre),
      (direccion, CampoDeSede.direccion),
    ]) {
      var anterior = controlador.text;
      controlador.addListener(() {
        // El controlador también avisa cuando se mueve el cursor: sólo cuenta el texto.
        if (controlador.text == anterior) return;
        anterior = controlador.text;
        erroresDelServidor.remove(campo);
        // En la edición los datos ya vienen cargados: el error se ve apenas se escribe.
        if (esEdicion) tocados.add(campo);
        notifyListeners();
      });
    }
  }

  final Sedes sedes;
  final Sede? editando;
  final TextEditingController nombre;
  final TextEditingController direccion;
  final focoNombre = FocusNode();
  final focoDireccion = FocusNode();
  int? apertura;
  int? cierre;
  List<int> dias;
  final tocados = <CampoDeSede>{};
  final erroresDelServidor = <CampoDeSede, String>{};
  bool intentoGuardar = false;
  bool enviando = false;
  bool _dandoDeBaja = false;

  /// Un envío anterior se cortó: la API pudo haber guardado la sede sin que llegara la
  /// respuesta.
  bool huboCorte = false;
  bool _cerrado = false;

  bool get esEdicion => editando != null;

  bool get dandoDeBaja => _dandoDeBaja;

  set dandoDeBaja(bool valor) {
    _dandoDeBaja = valor;
    notifyListeners();
  }

  /// Guardando o dando de baja: el formulario no se toca ni se sale.
  bool get ocupado => enviando || _dandoDeBaja;

  @override
  void notifyListeners() {
    if (!_cerrado) super.notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    nombre.dispose();
    direccion.dispose();
    focoNombre.dispose();
    focoDireccion.dispose();
    super.dispose();
  }

  TextEditingController _controlador(CampoDeSede campo) =>
      campo == CampoDeSede.nombre ? nombre : direccion;

  String? errorDeRegla(CampoDeSede campo) => switch (campo) {
    CampoDeSede.nombre => errorDelNombreDeSede(nombre.text),
    CampoDeSede.direccion => errorDeLaDireccionDeSede(direccion.text),
    CampoDeSede.apertura => errorDeLaApertura(apertura),
    CampoDeSede.cierre => errorDelCierre(cierre: cierre, apertura: apertura),
    CampoDeSede.dias => null,
  };

  String? error(CampoDeSede campo) => errorAMostrar(
    delServidor: erroresDelServidor[campo],
    deRegla: errorDeRegla(campo),
    intentado: intentoGuardar,
    tocado: tocados.contains(campo),
  );

  bool get completo =>
      CampoDeSede.values.every((c) => errorDeRegla(c) == null) &&
      erroresDelServidor.isEmpty;

  /// Los campos que se pueden enfocar o no, con su error, en el orden en que se ven.
  List<(FocusNode?, String?)> get faltantes => [
    (focoNombre, errorDeRegla(CampoDeSede.nombre)),
    (focoDireccion, errorDeRegla(CampoDeSede.direccion)),
    (null, errorDeRegla(CampoDeSede.apertura)),
    (null, errorDeRegla(CampoDeSede.cierre)),
  ];

  void marcarIntentoDeGuardar() {
    intentoGuardar = true;
    notifyListeners();
  }

  /// Guarda la hora [elegida] para la apertura o el cierre; `null` si se cerró sin elegir.
  void elegirHora(CampoDeSede campo, int? elegida) {
    if (elegida != null) {
      tocados.add(campo);
      if (campo == CampoDeSede.cierre) {
        cierre = elegida;
      } else {
        apertura = elegida;
      }
      erroresDelServidor
        ..remove(CampoDeSede.apertura)
        ..remove(CampoDeSede.cierre);
    }
    notifyListeners();
  }

  void elegirDias(DiasQueAbre elegidos) {
    dias = elegidos.dias;
    erroresDelServidor.remove(CampoDeSede.dias);
    notifyListeners();
  }

  void _mostrarErrores(Map<String, String> errores) {
    for (final MapEntry(:key, :value) in errores.entries) {
      final campo = CampoDeSede.values.asNameMap()[key];
      if (campo != null) erroresDelServidor[campo] = value;
    }
    notifyListeners();
  }

  Future<Sede> _pedir(int apertura, int cierre, {required bool confirmar}) {
    final nombreEscrito = nombre.text.trim();
    final direccionEscrita = direccion.text.trim();
    final sede = editando;
    return sede == null
        ? sedes.darDeAlta(
            nombre: nombreEscrito,
            direccion: direccionEscrita,
            apertura: horaCerrada(apertura),
            cierre: horaCerrada(cierre),
            dias: dias,
          )
        : sedes.editar(
            sede.id,
            nombre: nombreEscrito,
            direccion: direccionEscrita,
            apertura: horaCerrada(apertura),
            cierre: horaCerrada(cierre),
            dias: dias,
            confirmar: confirmar,
          );
  }

  /// Guarda la sede con lo que se ve ahora, que tiene que estar [completo]. Si se guarda,
  /// llama a [alGuardar] y devuelve `null`; si no, devuelve qué falta atender.
  Future<PendienteDeSede?> enviar(
    int apertura,
    int cierre, {
    required bool confirmar,
    required void Function(Sede) alGuardar,
  }) async {
    enviando = true;
    notifyListeners();
    Object? fallo;
    var vencida = false;
    int? afuera;
    var yaNoEsta = false;
    try {
      alGuardar(await _pedir(apertura, cierre, confirmar: confirmar));
      return null;
    } on ReservasAfuera catch (e) {
      afuera = e.cantidad;
    } on SedeNoDisponible {
      yaNoEsta = true;
    } on SedeRechazada catch (e) {
      final guardada = !esEdicion && e.repetido && huboCorte
          ? await _laQueSeGuardo(apertura, cierre)
          : null;
      if (guardada != null) {
        alGuardar(guardada);
        return null;
      }
      if (!_cerrado) _mostrarErrores(e.errores);
    } on SesionVencida {
      vencida = true;
    } on SinConexion catch (e) {
      huboCorte = true;
      fallo = e;
    } on ErrorDelServidor catch (e) {
      fallo = e;
    } finally {
      if (!_cerrado) {
        enviando = false;
        notifyListeners();
      }
    }
    if (_cerrado) return null;
    return (afuera: afuera, yaNoEsta: yaNoEsta, vencida: vencida, fallo: fallo);
  }

  /// La sede que guardó el envío cortado, si es esta misma: así el reintento no la
  /// confunde con otra que ya tenía el nombre.
  Future<Sede?> _laQueSeGuardo(int apertura, int cierre) async {
    String normal(String texto) =>
        texto.trim().split(RegExp(r'\s+')).join(' ').toLowerCase();
    try {
      final activas = await sedes.activas();
      return activas
          .where(
            (s) =>
                normal(s.nombre) == normal(nombre.text) &&
                normal(s.direccion) == normal(direccion.text) &&
                s.apertura == horaCerrada(apertura) &&
                s.cierre == horaCerrada(cierre) &&
                diasDeLaSemana(s.dias) == diasDeLaSemana(dias),
          )
          .firstOrNull;
    } on Exception {
      return null;
    }
  }
}
