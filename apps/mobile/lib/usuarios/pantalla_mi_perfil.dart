import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/apariencia.dart';
import '../comun/avatar.dart';
import '../comun/barra_inferior.dart';
import '../comun/boton.dart';
import '../comun/calendario.dart';
import '../comun/campo_texto.dart';
import '../comun/dialogo_error.dart';
import '../comun/formato_fecha.dart';
import '../comun/insignia.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'reglas_registro.dart';

/// Mi perfil: todos los datos de la cuenta, pedidos a la API cada vez que se abre, y los
/// accesos a lo que se puede hacer con ella.
class PantallaMiPerfil extends StatefulWidget {
  const PantallaMiPerfil({
    super.key,
    required this.sesion,
    required this.apariencia,
  });

  final Sesion sesion;
  final Apariencia apariencia;

  @override
  State<PantallaMiPerfil> createState() => _PantallaMiPerfilState();
}

class _PantallaMiPerfilState extends State<PantallaMiPerfil> {
  Perfil? _perfil;
  bool _editando = false;
  bool _cargando = true;
  bool _dandoDeBaja = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!_cargando) setState(() => _cargando = true);
    Object? fallo;
    try {
      final perfil = await widget.sesion.refrescar();
      if (mounted) {
        setState(() {
          _perfil = perfil;
          _cargando = false;
        });
      }
      return;
    } on SesionVencida {
      if (!mounted) {
        // Salió del perfil mientras cargaba: igual se cierra la sesión que ya no vale, y
        // las rutas lo llevan al login.
        try {
          await widget.sesion.cerrar();
        } on Exception {
          // Si Firebase no la pudo cerrar, el próximo pedido vuelve a encontrarla vencida.
        }
        return;
      }
      setState(() => _cargando = false);
      await mostrarSesionVencida(context);
      if (mounted) await cerrarSesion(context, widget.sesion);
      return;
    } on SinConexion catch (e) {
      fallo = e;
    } on ErrorDelServidor catch (e) {
      fallo = e;
    }
    if (!mounted) return;
    // Sin datos frescos no se muestra nada: ni parciales ni viejos.
    setState(() => _cargando = false);
    final resultado = await atenderErrorDeRed(context, fallo);
    if (!mounted) return;
    if (resultado == ResultadoDeError.reintentar) {
      await _cargar();
    } else if (resultado == ResultadoDeError.cerrado) {
      context.go('/inicio');
    }
  }

  Future<void> _confirmarBaja() async {
    final confirmada = await showDialog<bool>(
      context: context,
      barrierColor: context.paleta.bgScrim,
      builder: (context) => const _ConfirmarBaja(),
    );
    if (confirmada == true && mounted) await _darDeBaja();
  }

  /// Si el intento anterior se cortó por la red, el servidor pudo haber terminado la baja.
  bool _huboCorte = false;

  Future<void> _darDeBaja() async {
    if (_dandoDeBaja) return;
    setState(() => _dandoDeBaja = true);
    Object? fallo;
    var vencida = false;
    try {
      // Si sale bien, la sesión se cierra y las rutas llevan al login.
      await widget.sesion.darDeBaja();
      return;
    } on SesionVencida {
      vencida = true;
    } on SinConexion catch (e) {
      fallo = e;
    } on ErrorDelServidor catch (e) {
      fallo = e;
    } finally {
      if (mounted) setState(() => _dandoDeBaja = false);
    }
    if (vencida && (_huboCorte || !mounted)) {
      // Un 401 después de un corte es la baja que ya se hizo; y si la persona salió de la
      // pantalla, la sesión que no vale se cierra igual. En los dos casos, al login.
      try {
        await widget.sesion.cerrar();
      } on Exception {
        // El próximo arranque la encuentra vencida y la cierra.
      }
      return;
    }
    if (!mounted) return;
    if (vencida) {
      await mostrarSesionVencida(context);
      if (mounted) await cerrarSesion(context, widget.sesion);
    } else if (fallo != null) {
      _huboCorte = fallo is SinConexion;
      final reintentar = await mostrarErrorDeRed(context, fallo);
      if (reintentar && mounted) await _darDeBaja();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final perfil = _perfil;
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: const BarraInferior(actual: Seccion.perfil),
      body: perfil == null
          ? (_cargando
                ? Center(
                    child: Semantics(
                      label: 'Cargando tu perfil',
                      child: CircularProgressIndicator(color: p.accentInk),
                    ),
                  )
                : const SizedBox.shrink())
          // Una pantalla corta y fija: todo queda armado aunque salga de la vista.
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Cabecera(perfil: perfil),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Medidas.s24,
                      Medidas.s20,
                      Medidas.s24,
                      Medidas.s48,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Tarjeta(
                          titulo: 'DATOS PERSONALES',
                          accion: _editando
                              ? null
                              : _BotonChico(
                                  texto: 'Editar',
                                  icono: Icons.edit_outlined,
                                  alTocar: () =>
                                      setState(() => _editando = true),
                                ),
                          child: _editando
                              ? _Edicion(
                                  perfil: perfil,
                                  sesion: widget.sesion,
                                  alGuardar: (nuevo) {
                                    if (!mounted) return;
                                    setState(() {
                                      _perfil = nuevo;
                                      _editando = false;
                                    });
                                  },
                                )
                              : _Datos(perfil: perfil),
                        ),
                        const SizedBox(height: Medidas.s16),
                        _Tarjeta(
                          titulo: 'SEGURIDAD',
                          child: _Fila(
                            icono: Icons.lock_outline_rounded,
                            texto: 'Cambiar contraseña',
                            alTocar: () => context.push('/perfil/contrasena'),
                          ),
                        ),
                        const SizedBox(height: Medidas.s16),
                        _Tarjeta(
                          titulo: 'APARIENCIA',
                          child: _ModoOscuro(apariencia: widget.apariencia),
                        ),
                        const SizedBox(height: Medidas.s20),
                        BotonContorno(
                          texto: 'CERRAR SESIÓN',
                          alTocar: _dandoDeBaja
                              ? null
                              : () => cerrarSesion(context, widget.sesion),
                        ),
                        const SizedBox(height: Medidas.s8),
                        BotonContorno(
                          texto: _dandoDeBaja
                              ? 'ELIMINANDO TU CUENTA…'
                              : 'ELIMINAR CUENTA',
                          peligro: true,
                          alTocar: _dandoDeBaja ? null : _confirmarBaja,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.perfil});

  final Perfil perfil;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.bgHeroFrom, p.bgBase],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Medidas.s24,
            Medidas.s48,
            Medidas.s24,
            Medidas.s24,
          ),
          child: Column(
            children: [
              AvatarIniciales(
                nombre: perfil.nombre,
                apellido: perfil.apellido,
                tamano: TamanoAvatar.grande,
              ),
              const SizedBox(height: Medidas.s8),
              Semantics(
                header: true,
                child: Text(
                  '${perfil.nombre} ${perfil.apellido}',
                  textAlign: TextAlign.center,
                  style: Textos.h1.copyWith(color: p.textPrimary),
                ),
              ),
              const SizedBox(height: Medidas.s8),
              Text(
                perfil.correo,
                textAlign: TextAlign.center,
                style: Textos.leyenda.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: Medidas.s8),
              const Insignia(texto: 'MIEMBRO ACTIVO'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Los datos personales en modo lectura. El correo no se puede cambiar (RF 2) y se ve y se
/// anuncia así.
class _Datos extends StatelessWidget {
  const _Datos({required this.perfil});

  final Perfil perfil;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FilaDato(etiqueta: 'Nombre', valor: perfil.nombre),
        _FilaDato(etiqueta: 'Apellido', valor: perfil.apellido),
        _FilaDato(etiqueta: 'DNI', valor: dniLegible(perfil.dni)),
        _FilaDato(
          etiqueta: 'Nacimiento',
          valor: fechaLegible(perfil.fechaNacimiento),
        ),
        _FilaDato(etiqueta: 'Correo', valor: perfil.correo, fija: true),
      ],
    );
  }
}

class _FilaDato extends StatelessWidget {
  const _FilaDato({
    required this.etiqueta,
    required this.valor,
    this.fija = false,
  });

  final String etiqueta;
  final String valor;
  final bool fija;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final mostrado = valor.trim().isEmpty ? '—' : valor;
    return Semantics(
      container: true,
      label: fija
          ? '$etiqueta: $mostrado. No se puede cambiar'
          : '$etiqueta: $mostrado',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Medidas.s12),
        child: Row(
          children: [
            Text(etiqueta, style: Textos.leyenda.copyWith(color: p.textMuted)),
            const SizedBox(width: Medidas.s12),
            Expanded(
              child: Text(
                mostrado,
                textAlign: TextAlign.right,
                style: Textos.cuerpoFuerte.copyWith(
                  color: fija ? p.textMuted : p.textPrimary,
                ),
              ),
            ),
            if (fija) ...[
              const SizedBox(width: Medidas.s8),
              Icon(Icons.lock_outline_rounded, size: 15, color: p.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}

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
class _Edicion extends StatefulWidget {
  const _Edicion({
    required this.perfil,
    required this.sesion,
    required this.alGuardar,
  });

  final Perfil perfil;
  final Sesion sesion;
  final ValueChanged<Perfil> alGuardar;

  @override
  State<_Edicion> createState() => _EdicionState();
}

class _EdicionState extends State<_Edicion> {
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
    final hoy = DateTime.now();
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
    } on SinConexion catch (e) {
      fallo = e;
    } on ErrorDelServidor catch (e) {
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
    if (vencida) {
      await mostrarSesionVencida(context);
      if (mounted) await cerrarSesion(context, widget.sesion);
    } else if (fallo != null) {
      final reintentar = await mostrarErrorDeRed(context, fallo);
      if (reintentar && mounted) await _guardar();
    }
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

class _ModoOscuro extends StatelessWidget {
  const _ModoOscuro({required this.apariencia});

  final Apariencia apariencia;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return ListenableBuilder(
      listenable: apariencia,
      builder: (context, _) {
        void alternar() => apariencia.cambiar(oscuro: !apariencia.oscuro);
        // Toda la fila alterna el tema, no sólo el interruptor.
        return Semantics(
          container: true,
          label: 'Modo oscuro',
          toggled: apariencia.oscuro,
          onTap: alternar,
          excludeSemantics: true,
          child: InkWell(
            onTap: alternar,
            borderRadius: BorderRadius.circular(Medidas.radioMd),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: Medidas.altoControl),
              child: Row(
                children: [
                  Icon(
                    Icons.dark_mode_outlined,
                    size: 20,
                    color: p.textSecondary,
                  ),
                  const SizedBox(width: Medidas.s12),
                  Expanded(
                    child: Text(
                      'Modo oscuro',
                      style: Textos.cuerpoFuerte.copyWith(color: p.textPrimary),
                    ),
                  ),
                  Switch(
                    value: apariencia.oscuro,
                    activeTrackColor: p.accentBase,
                    activeThumbColor: p.accentOn,
                    onChanged: (oscuro) => apariencia.cambiar(oscuro: oscuro),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ConfirmarBaja extends StatelessWidget {
  const _ConfirmarBaja();

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Dialog(
      backgroundColor: p.bgSurfaceRaised,
      insetPadding: const EdgeInsets.symmetric(horizontal: Medidas.s24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Medidas.radioLg),
        side: BorderSide(color: p.borderDefault),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Medidas.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: p.stateDangerMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 28,
                  color: p.stateDangerInk,
                ),
              ),
            ),
            const SizedBox(height: Medidas.s12),
            Text(
              '¿Eliminar tu cuenta?',
              textAlign: TextAlign.center,
              style: Textos.h2.copyWith(color: p.textPrimary),
            ),
            const SizedBox(height: Medidas.s12),
            Text(
              'Esta acción es permanente. Se eliminarán tus datos y tus reservas '
              'vigentes.',
              textAlign: TextAlign.center,
              style: Textos.cuerpo.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: Medidas.s12),
            BotonPeligro(
              texto: 'ELIMINAR CUENTA',
              alTocar: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: Medidas.s8),
            BotonContorno(
              texto: 'CANCELAR',
              alTocar: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.titulo, required this.child, this.accion});

  final String titulo;
  final Widget child;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final boton = accion;
    return Container(
      padding: const EdgeInsets.all(Medidas.s16),
      decoration: BoxDecoration(
        color: p.bgSurface,
        border: Border.all(color: p.borderDefault),
        borderRadius: BorderRadius.circular(Medidas.radioLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    titulo,
                    style: Textos.sobretitulo.copyWith(color: p.textMuted),
                  ),
                ),
              ),
              ?boton,
            ],
          ),
          const SizedBox(height: Medidas.s8),
          child,
        ],
      ),
    );
  }
}

/// `Btn-Small`: acción secundaria dentro de una tarjeta.
class _BotonChico extends StatelessWidget {
  const _BotonChico({
    required this.texto,
    required this.icono,
    required this.alTocar,
  });

  final String texto;
  final IconData icono;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return OutlinedButton.icon(
      onPressed: alTocar,
      icon: Icon(icono, size: 15),
      label: Text(texto),
      style: OutlinedButton.styleFrom(
        foregroundColor: p.textPrimary,
        side: BorderSide(color: p.borderDefault),
        shape: const StadiumBorder(),
        minimumSize: const Size(0, Medidas.tactil),
        textStyle: Textos.leyenda,
        padding: const EdgeInsets.symmetric(horizontal: Medidas.s12),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.icono,
    required this.texto,
    required this.alTocar,
  });

  final IconData icono;
  final String texto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: alTocar,
        borderRadius: BorderRadius.circular(Medidas.radioMd),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Medidas.altoControl),
          child: Row(
            children: [
              Icon(icono, size: 20, color: p.textSecondary),
              const SizedBox(width: Medidas.s12),
              Expanded(
                child: Text(
                  texto,
                  style: Textos.cuerpoFuerte.copyWith(color: p.textPrimary),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: p.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
