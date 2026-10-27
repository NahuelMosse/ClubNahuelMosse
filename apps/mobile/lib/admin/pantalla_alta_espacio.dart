import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/barra_superior.dart';
import '../comun/dialogo_error.dart';
import '../espacios/espacios.dart';
import '../sedes/sedes.dart';
import '../sesion/fallo_de_carga.dart';
import '../sesion/sesion.dart';
import '../tema/tokens.dart';
import 'campo_de_alta_de_espacio.dart';
import 'cuerpo_de_alta_de_espacio.dart';
import 'formulario_de_alta_de_espacio.dart';
import 'formulario_espacio.dart';
import 'opciones_de_alta_de_espacio.dart';

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
  late final _f = FormularioDeAltaDeEspacio(
    espacios: widget.espacios,
    sedes: widget.sedes,
  );

  @override
  void initState() {
    super.initState();
    _f.addListener(() => setState(() {}));
    _cargar();
  }

  @override
  void dispose() {
    _f.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final falla = await _f.cargar();
    if (falla == null || !mounted) return;
    if (falla.vencida) {
      await avisarSesionVencida(context, widget.sesion);
      return;
    }
    final fallo = falla.fallo;
    if (fallo == null) return;
    final resultado = await atenderErrorDeRed(context, fallo);
    if (!mounted) return;
    if (resultado == ResultadoDeError.reintentar) {
      await _cargar();
    } else if (resultado == ResultadoDeError.cerrado) {
      context.go('/admin/espacios');
    }
  }

  /// Avisa que la sesión venció si [vencio] lo dice.
  Future<void> _avisarSiVencio(Future<bool> vencio) async {
    if (await vencio && mounted) {
      await avisarSesionVencida(context, widget.sesion);
    }
  }

  Future<void> _calcularNombre() => _avisarSiVencio(_f.calcularNombre());

  Future<void> _elegirSede() async {
    final elegida = await elegirSedeDeAlta(context, _f);
    if (elegida == null || !mounted || elegida == _f.sede) return;
    await _avisarSiVencio(_f.elegirSede(elegida));
  }

  Future<void> _elegirDeporte() async {
    final elegido = await elegirDeporteDeAlta(context, _f);
    if (elegido == null || !mounted || elegido == _f.deporte) return;
    await _avisarSiVencio(_f.elegirDeporte(elegido));
  }

  Future<void> _elegirTipo() async {
    final elegido = await elegirTipoDeAlta(context, _f);
    if (elegido == null || !mounted || elegido == _f.tipo) return;
    await _avisarSiVencio(_f.elegirTipo(elegido));
  }

  Future<void> _elegirSiNo(CampoDeAltaDeEspacio campo) async {
    final condicion = campo == CampoDeAltaDeEspacio.condicion;
    final elegido = await elegirSiNo(
      context,
      condicion: condicion,
      elegida: condicion ? _f.techada : _f.iluminada,
    );
    if (elegido == null || !mounted) return;
    _f.elegirSiNo(campo, valor: elegido);
  }

  /// Calcula el nombre si falta; devuelve si hay que cortar el guardado porque no se pudo.
  Future<bool> _fallaElNombre() async {
    if (_f.sugerido != null || !_f.puedeCalcularElNombre) return false;
    await _calcularNombre();
    if (!mounted) return true;
    final fallo = _f.falloDelNombre;
    if (fallo == null) return false;
    await avisarFalloDeEnvio(
      context,
      sesion: widget.sesion,
      vencida: false,
      error: fallo,
      reintentar: _guardar,
    );
    return true;
  }

  Future<void> _guardar() async {
    if (_f.enviando || _f.calculando) return;
    if (await _fallaElNombre() || !mounted) return;
    // Lo que se manda es lo que se ve ahora, aunque haya cambiado mientras se calculaba.
    if (!_f.completo) return _f.marcarIntentoDeGuardar();
    FocusScope.of(context).unfocus();
    final pendiente = await _f.enviar(
      alCrear: (espacio) {
        if (mounted) context.go('/admin/espacios/creado', extra: espacio);
      },
    );
    if (pendiente == null || !mounted) return;
    await avisarFalloDeEnvio(
      context,
      sesion: widget.sesion,
      vencida: pendiente.vencida,
      error: pendiente.fallo,
      reintentar: _guardar,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Mientras se guarda no se sale: el espacio se crearía sin que se viera el éxito.
      canPop: !_f.enviando,
      child: Scaffold(
        backgroundColor: context.paleta.bgBase,
        appBar: const BarraSuperior(titulo: 'Nuevo espacio'),
        body: SafeArea(
          top: false,
          child: _f.cargando && _f.opcionesDeSede == null
              ? const Center(child: CircularProgressIndicator())
              : CuerpoDeAltaDeEspacio(
                  formulario: _f,
                  alElegirSede: _elegirSede,
                  alElegirDeporte: _elegirDeporte,
                  alElegirTipo: _elegirTipo,
                  alElegirSiNo: _elegirSiNo,
                  alReintentarElNombre: _calcularNombre,
                  alGuardar: _guardar,
                ),
        ),
      ),
    );
  }
}
