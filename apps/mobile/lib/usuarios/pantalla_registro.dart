import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_superior.dart';
import '../comun/boton.dart';
import '../comun/calendario.dart';
import '../comun/dialogo_error.dart';
import '../comun/errores_de_campo.dart';
import '../comun/faltantes.dart';
import '../comun/reglas_registro.dart';
import '../comun/reloj.dart';
import '../tema/tokens.dart';
import 'campo_de_registro.dart';
import 'encabezado_de_registro.dart';
import 'formulario_de_registro.dart';
import 'registro.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key, required this.api, this.hoy});

  final ClienteApi api;

  /// Para fijar el día en los tests de widgets; en la app es el día de hoy.
  final DateTime Function()? hoy;

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _controladores = [
    for (final _ in CampoDeRegistro.values) TextEditingController(),
  ];
  final _focos = [for (final _ in CampoDeRegistro.values) FocusNode()];
  final _textos = [for (final _ in CampoDeRegistro.values) ''];
  final _tocados = <CampoDeRegistro>{};
  final _erroresDelServidor = <CampoDeRegistro, String>{};
  bool _intentoCrear = false;
  String? _aviso;

  /// Un pedido anterior se cortó sin respuesta: la API pudo haber creado la cuenta igual.
  bool _huboCorte = false;

  /// El 409 llegó después de un corte: la cuenta que se mandó crear ya existe.
  bool _yaExiste = false;
  bool _enviando = false;
  bool _contrasenaVisible = false;

  late final _servicio = RegistroServicio(widget.api);

  DateTime get _hoy => (widget.hoy ?? ahoraEnElClub)();

  @override
  void initState() {
    super.initState();
    for (final campo in CampoDeRegistro.values) {
      _focos[campo.index].addListener(() {
        // Salir de un campo vacío no marca nada: eso lo hace el intento de crear la cuenta.
        if (!_focos[campo.index].hasFocus && _valor(campo).isNotEmpty) {
          setState(() => _tocados.add(campo));
        }
      });
      _controladores[campo.index].addListener(() => _alCambiar(campo));
    }
  }

  /// Sólo un cambio de texto invalida lo que dijo la API; mover el cursor, no.
  void _alCambiar(CampoDeRegistro campo) {
    final texto = _controladores[campo.index].text;
    if (texto == _textos[campo.index]) return;
    setState(() {
      _textos[campo.index] = texto;
      _erroresDelServidor.remove(campo);
      if (campo == CampoDeRegistro.correo || campo == CampoDeRegistro.dni) {
        _aviso = null;
        _huboCorte = false;
        _yaExiste = false;
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controladores) {
      c.dispose();
    }
    for (final f in _focos) {
      f.dispose();
    }
    super.dispose();
  }

  String _valor(CampoDeRegistro c) => _controladores[c.index].text;

  String? _errorDeRegla(CampoDeRegistro campo) => switch (campo) {
    CampoDeRegistro.nombre => validarNombre(
      _valor(campo),
      obligatorio: 'El nombre es obligatorio',
    ),
    CampoDeRegistro.apellido => validarNombre(
      _valor(campo),
      obligatorio: 'El apellido es obligatorio',
    ),
    CampoDeRegistro.dni => validarDni(_valor(campo)),
    CampoDeRegistro.fechaNacimiento => validarFechaNacimiento(
      _valor(campo),
      _hoy,
    ),
    CampoDeRegistro.correo => validarCorreo(_valor(campo)),
    CampoDeRegistro.contrasena => validarContrasena(_valor(campo)),
  };

  String? _errorVisible(CampoDeRegistro campo) => errorAMostrar(
    delServidor: _erroresDelServidor[campo],
    deRegla: _errorDeRegla(campo),
    intentado: _intentoCrear,
    tocado: _tocados.contains(campo),
  );

  bool get _completo =>
      CampoDeRegistro.values.every((c) => _errorDeRegla(c) == null);

  Future<void> _crearCuenta() async {
    if (_enviando) return;
    final fecha = leerFecha(_valor(CampoDeRegistro.fechaNacimiento));
    if (!_completo || fecha == null) {
      setState(() => _intentoCrear = true);
      enfocarElPrimerFaltante([
        for (final c in CampoDeRegistro.values)
          (_focos[c.index], _errorDeRegla(c)),
      ]);
      return;
    }
    setState(() {
      _enviando = true;
      _aviso = null;
    });
    Object? fallo;
    try {
      final r = await _servicio.registrar(
        DatosDeRegistro(
          nombre: _valor(CampoDeRegistro.nombre),
          apellido: _valor(CampoDeRegistro.apellido),
          dni: _valor(CampoDeRegistro.dni),
          fechaNacimiento: fecha,
          correo: _valor(CampoDeRegistro.correo),
          contrasena: _valor(CampoDeRegistro.contrasena),
        ),
      );
      if (!mounted) return;
      if (r.codigo == 201) {
        context.go('/registro/exitoso');
        return;
      }
      if (r.codigo == 409 && _huboCorte) {
        setState(() => _yaExiste = true);
        return;
      }
      final errores = erroresDeCampo(r.cuerpo);
      final mensaje = r.cuerpo['mensaje'];
      if (errores.isEmpty) {
        fallo = ErrorDelServidor(r.codigo);
      } else {
        setState(() {
          for (final MapEntry(:key, :value) in errores.entries) {
            final campo = CampoDeRegistro.deLaApi(key);
            if (campo != null) _erroresDelServidor[campo] = value;
          }
          _aviso = r.codigo == 409 && mensaje is String ? mensaje : null;
        });
      }
    } on SinConexion catch (e) {
      _huboCorte = true;
      fallo = e;
    } on ErrorDelServidor catch (e) {
      fallo = e;
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
    if (fallo != null && mounted) {
      final reintentar = await mostrarErrorDeRed(context, fallo);
      if (reintentar && mounted) await _crearCuenta();
    }
  }

  Future<void> _elegirFecha() async {
    final elegida = await elegirFechaDeNacimiento(
      context,
      leerFecha(_valor(CampoDeRegistro.fechaNacimiento)) ??
          DateTime(_hoy.year - 20),
    );
    if (elegida == null || !mounted) return;
    _controladores[CampoDeRegistro.fechaNacimiento.index].text = formatearFecha(
      elegida,
    );
    setState(() => _tocados.add(CampoDeRegistro.fechaNacimiento));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BarraSuperior(
        titulo: 'Registro',
        alVolver: () => context.go('/'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Medidas.s24,
            Medidas.s8,
            Medidas.s24,
            Medidas.s40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EncabezadoDeRegistro(yaExiste: _yaExiste, aviso: _aviso),
              FormularioDeRegistro(
                controladores: _controladores,
                focos: _focos,
                errorDe: _errorVisible,
                enviando: _enviando,
                contrasenaVisible: _contrasenaVisible,
                alElegirFecha: _elegirFecha,
                alCambiarVisibilidad: () =>
                    setState(() => _contrasenaVisible = !_contrasenaVisible),
              ),
              const SizedBox(height: Medidas.s16),
              BotonPrimario(
                texto: 'CREAR CUENTA',
                cargando: _enviando,
                atenuado: !_completo,
                alTocar: _crearCuenta,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
