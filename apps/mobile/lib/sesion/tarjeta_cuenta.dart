import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/avatar.dart';
import '../comun/dialogo_error.dart';
import '../tema/tokens.dart';
import 'panel_de_cuenta.dart';
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
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar la tarjeta de tu cuenta',
    barrierColor: context.paleta.bgScrim,
    pageBuilder: (context, _, _) {
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
              child: PanelDeCuenta(
                perfil: perfil,
                alIr: ir,
                alCerrarSesion: () {
                  Navigator.of(context).pop();
                  cerrarSesion(origen, sesion);
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}
