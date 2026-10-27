import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/cliente_api.dart';
import '../comun/boton.dart';
import '../comun/calendario.dart';
import '../comun/campo_texto.dart';
import '../comun/formato_fecha.dart';
import '../comun/reglas_registro.dart';
import '../comun/reloj.dart';
import '../sesion/fallo_de_carga.dart';
import '../sesion/sesion.dart';
import '../tema/tokens.dart';

enum _Campo {
  nombre('nombre'),
  apellido('apellido'),
  dni('dni'),
  fechaNacimiento('fecha_nacimiento');

  const _Campo(this.clave);

  /// El nombre del campo en la API.
  final String clave;
}

/// Los datos personales en modo edición. Todo se puede cambiar menos el correo (RF 2).
class EdicionDePerfil extends StatefulWidget {
  const EdicionDePerfil({
    super.key,
    required this.perfil,
    required this.sesion,
    required this.alGuardar,
  });

  final Perfil perfil;
  final Sesion sesion;
  final ValueChanged<Perfil> alGuardar;

  @override
  State<EdicionDePerfil> createState() => _EdicionDePerfilState();
}

class _EdicionDePerfilState extends State<EdicionDePerfil> {
  static const _invalido = 'El formato de los datos no es válido';

  late final _controladores = [
    for (final campo in _Campo.values)
      TextEditingController(
        text: switch (campo) {
          _Campo.nombre => widget.perfil.nombre,
          _Campo.apellido => widget.perfil.apellido,
          _Campo.dni => dniLegible(widget.perfil.dni),
          _Campo.fechaNacimiento => formatearFecha(
            widget.perfil.fechaNacimiento,
          ),
        },
      ),
  ];
  late final _correo = TextEditingController(text: widget.perfil.correo);
  final _errores = <_Campo, String>{};
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    for (final campo in _Campo.values) {
      final controlador = _controladores[campo.index];
      var anterior = controlador.text;
      controlador.addListener(() {
        if (controlador.text == anterior) return;
        anterior = controlador.text;
        if (_errores.containsKey(campo)) setState(() => _errores.remove(campo));
      });
    }
  }

  @override
  void dispose() {
    for (final controlador in _controladores) {
      controlador.dispose();
    }
    _correo.dispose();
    super.dispose();
  }

  String _valor(_Campo campo) => _controladores[campo.index].text;

  /// Los campos que no pasan las reglas del registro. El prototipo los marca todos con el
  /// mismo mensaje.
  Set<_Campo> _invalidos() {
    final hoy = ahoraEnElClub();
    return {
      for (final campo in [_Campo.nombre, _Campo.apellido])
        if (validarNombre(_valor(campo), obligatorio: _invalido) != null) campo,
      if (validarDni(_valor(_Campo.dni)) != null) _Campo.dni,
      if (validarFechaNacimiento(_valor(_Campo.fechaNacimiento), hoy) != null)
        _Campo.fechaNacimiento,
    };
  }

  Future<void> _guardar() async {
    if (_enviando) return;
    FocusScope.of(context).unfocus();
    final invalidos = _invalidos();
    final fecha = leerFecha(_valor(_Campo.fechaNacimiento));
    if (invalidos.isNotEmpty || fecha == null) {
      setState(() {
        _errores
          ..clear()
          ..addEntries(invalidos.map((c) => MapEntry(c, _invalido)));
      });
      return;
    }
    setState(() => _enviando = true);
    Object? fallo;
    var vencida = false;
    try {
      final perfil = await widget.sesion.editarPerfil(
        nombre: _valor(_Campo.nombre).trim(),
        apellido: _valor(_Campo.apellido).trim(),
        dni: normalizarDni(_valor(_Campo.dni)),
        fechaNacimiento: fechaIso(fecha),
      );
      if (mounted) widget.alGuardar(perfil);
      return;
    } on DatosRechazados catch (e) {
      if (mounted) {
        setState(() {
          for (final campo in _Campo.values) {
            final mensaje = e.errores[campo.clave];
            if (mensaje == null) continue;
            // El dato de otra cuenta tiene su propio mensaje; lo demás es de formato.
            _errores[campo] = e.repetido ? mensaje : _invalido;
          }
        });
      }
    } on SesionVencida {
      vencida = true;
    } on FalloDeRed catch (e) {
      fallo = e;
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
    if (!mounted) {
      // Salió de la pantalla mientras guardaba: la sesión vencida se cierra igual.
      if (vencida) {
        try {
          await widget.sesion.cerrar();
        } on Exception {
          // El próximo pedido la vuelve a encontrar vencida.
        }
      }
      return;
    }
    await avisarFalloDeEnvio(
      context,
      sesion: widget.sesion,
      vencida: vencida,
      error: fallo,
      reintentar: _guardar,
    );
  }

  Future<void> _elegirFecha() async {
    final elegida = await elegirFechaDeNacimiento(
      context,
      leerFecha(_valor(_Campo.fechaNacimiento)) ??
          widget.perfil.fechaNacimiento,
    );
    if (elegida == null || !mounted) return;
    _controladores[_Campo.fechaNacimiento.index].text = formatearFecha(elegida);
  }

  CampoTexto _campo(
    _Campo campo, {
    required String etiqueta,
    required String accesible,
    TextInputType? teclado,
    List<TextInputFormatter>? formateadores,
    Widget? accionFinal,
  }) => CampoTexto(
    etiqueta: etiqueta,
    etiquetaAccesible: accesible,
    controlador: _controladores[campo.index],
    error: _errores[campo],
    teclado: teclado,
    formateadores: formateadores,
    habilitado: !_enviando,
    accionFinal: accionFinal,
    accion: TextInputAction.next,
  );

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _campo(_Campo.nombre, etiqueta: 'NOMBRE', accesible: 'Nombre'),
        const SizedBox(height: Medidas.s12),
        _campo(_Campo.apellido, etiqueta: 'APELLIDO', accesible: 'Apellido'),
        const SizedBox(height: Medidas.s12),
        _campo(
          _Campo.dni,
          etiqueta: 'DNI',
          accesible: 'DNI',
          teclado: TextInputType.number,
          formateadores: [formatoDni],
        ),
        const SizedBox(height: Medidas.s12),
        _campo(
          _Campo.fechaNacimiento,
          etiqueta: 'FECHA DE NACIMIENTO',
          accesible: 'Fecha de nacimiento',
          teclado: TextInputType.number,
          formateadores: const [FormatoFecha()],
          accionFinal: IconButton(
            tooltip: 'Elegir la fecha en el calendario',
            onPressed: _enviando ? null : _elegirFecha,
            icon: Icon(Icons.calendar_today_outlined, color: p.textSecondary),
          ),
        ),
        const SizedBox(height: Medidas.s12),
        // El correo se ve pero no se edita.
        Opacity(
          opacity: 0.4,
          child: CampoTexto(
            etiqueta: 'CORREO ELECTRÓNICO',
            etiquetaAccesible: 'Correo electrónico',
            controlador: _correo,
            habilitado: false,
            accionFinal: Padding(
              padding: const EdgeInsets.only(right: Medidas.s12),
              child: Icon(Icons.lock_outline_rounded, color: p.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: Medidas.s16),
        BotonPrimario(texto: 'GUARDAR', cargando: _enviando, alTocar: _guardar),
      ],
    );
  }
}
