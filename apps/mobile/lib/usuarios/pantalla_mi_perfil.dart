import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/apariencia.dart';
import '../comun/avatar.dart';
import '../comun/barra_inferior.dart';
import '../comun/boton.dart';
import '../comun/dialogo_error.dart';
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
    final reintentar = await mostrarErrorDeRed(context, fallo);
    if (!mounted) return;
    if (reintentar) {
      await _cargar();
    } else {
      context.go('/inicio');
    }
  }

  Future<void> _confirmarBaja() => showDialog<void>(
    context: context,
    barrierColor: context.paleta.bgScrim,
    builder: (context) => const _ConfirmarBaja(),
  );

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
                              ? _Edicion(perfil: perfil)
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
                          alTocar: () => cerrarSesion(context, widget.sesion),
                        ),
                        const SizedBox(height: Medidas.s8),
                        BotonContorno(
                          texto: 'ELIMINAR CUENTA',
                          peligro: true,
                          alTocar: _confirmarBaja,
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

/// Los datos personales en modo edición: guardar los cambios lo hace Editar perfil (CU-06).
class _Edicion extends StatelessWidget {
  const _Edicion({required this.perfil});

  final Perfil perfil;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FilaDato(etiqueta: 'Correo', valor: perfil.correo, fija: true),
        const SizedBox(height: Medidas.s16),
        const BotonPrimario(texto: 'GUARDAR', alTocar: null),
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
            BotonContorno(
              texto: 'CANCELAR',
              alTocar: () => Navigator.of(context).pop(),
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
