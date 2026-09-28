import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/avatar.dart';
import '../comun/dialogo_error.dart';
import '../comun/insignia.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'sesion.dart';

/// El avatar de la cabecera: abre la tarjeta de la cuenta.
class BotonCuenta extends StatelessWidget {
  const BotonCuenta({super.key, required this.sesion});

  final Sesion sesion;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    // Las iniciales siguen al perfil, también cuando se edita.
    listenable: sesion,
    builder: (context, _) => _avatar(context),
  );

  Widget _avatar(BuildContext context) {
    final perfil = sesion.perfil;
    if (perfil == null) return const SizedBox.shrink();
    void abrir() => mostrarTarjetaCuenta(context, sesion);
    return Semantics(
      container: true,
      button: true,
      label: 'Tu cuenta',
      // Con los hijos excluidos, el toque del lector de pantalla tiene que declararse acá.
      onTap: abrir,
      excludeSemantics: true,
      child: InkResponse(
        onTap: abrir,
        radius: TamanoAvatar.chico.lado / 2 + Medidas.s4,
        child: SizedBox.square(
          dimension: Medidas.altoControl,
          child: Center(
            child: AvatarIniciales(
              nombre: perfil.nombre,
              apellido: perfil.apellido,
              tamano: TamanoAvatar.chico,
            ),
          ),
        ),
      ),
    );
  }
}

/// Cierra la sesión; si Firebase no la pudo borrar del dispositivo, la persona queda adentro
/// y se le avisa, en vez de mostrarle el login con la sesión todavía guardada.
Future<void> cerrarSesion(BuildContext context, Sesion sesion) async {
  try {
    await sesion.cerrar();
  } on Exception {
    if (context.mounted) {
      await mostrarErrorDeRed(context, const ErrorDelServidor(0));
    }
  }
}

/// `Sheet-Perfil` del prototipo: quién tiene la sesión abierta y sus accesos. Se cierra al
/// tocar afuera sin hacer nada.
///
/// Un administrador sólo ve «Cerrar sesión»: no tiene perfil ni reservas propias.
Future<void> mostrarTarjetaCuenta(BuildContext context, Sesion sesion) {
  final perfil = sesion.perfil;
  if (perfil == null) return Future.value();
  final origen = context;
  final esUsuario = perfil.rol == Rol.usuario;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar la tarjeta de tu cuenta',
    barrierColor: context.paleta.bgScrim,
    pageBuilder: (context, _, _) {
      final p = context.paleta;
      // Perfil y reservas se apilan sobre el inicio: el atrás del teléfono vuelve a él.
      void ir(String ruta) {
        Navigator.of(context).pop();
        GoRouter.of(origen).push(ruta);
      }

      return SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Medidas.s16,
              72,
              Medidas.s16,
              Medidas.s16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Medidas.radioLg),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x8C000000),
                      offset: Offset(0, 14),
                      blurRadius: 34,
                    ),
                  ],
                ),
                child: Material(
                  color: p.bgSurfaceRaised,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Medidas.radioLg),
                    side: BorderSide(color: p.borderDefault),
                  ),
                  clipBehavior: Clip.antiAlias,
                  // Con el teléfono apaisado o el texto grande no entra en el alto.
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(Medidas.s16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AvatarIniciales(
                                nombre: perfil.nombre,
                                apellido: perfil.apellido,
                              ),
                              const SizedBox(width: Medidas.s12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${perfil.nombre} ${perfil.apellido}',
                                      style: Textos.titulo.copyWith(
                                        color: p.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: Medidas.s4),
                                    Text(
                                      perfil.correo,
                                      style: Textos.leyenda.copyWith(
                                        color: p.textMuted,
                                      ),
                                    ),
                                    if (esUsuario) ...[
                                      const SizedBox(height: Medidas.s4),
                                      const Insignia(texto: 'MIEMBRO ACTIVO'),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: p.borderDefault),
                        const SizedBox(height: Medidas.s8),
                        if (esUsuario) ...[
                          _Opcion(
                            icono: Icons.person_outline_rounded,
                            texto: 'Perfil completo',
                            alTocar: () => ir('/perfil'),
                          ),
                          _Opcion(
                            icono: Icons.calendar_today_outlined,
                            texto: 'Mis reservas',
                            alTocar: () => ir('/reservas'),
                          ),
                        ],
                        _Opcion(
                          icono: Icons.logout_rounded,
                          texto: 'Cerrar sesión',
                          peligro: true,
                          alTocar: () {
                            Navigator.of(context).pop();
                            cerrarSesion(origen, sesion);
                          },
                        ),
                        const SizedBox(height: Medidas.s8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.icono,
    required this.texto,
    required this.alTocar,
    this.peligro = false,
  });

  final IconData icono;
  final String texto;
  final VoidCallback alTocar;
  final bool peligro;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final color = peligro ? p.stateDangerInk : p.textPrimary;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: alTocar,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Medidas.altoControl),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Medidas.s16),
            child: Row(
              children: [
                Icon(icono, size: 20, color: peligro ? color : p.textSecondary),
                const SizedBox(width: Medidas.s12),
                Expanded(
                  child: Text(
                    texto,
                    style: Textos.cuerpoFuerte.copyWith(color: color),
                  ),
                ),
                if (!peligro)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: p.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
