import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'movimiento.dart';

/// Un microsegundo menos que [Movimiento.volver]: el controlador de la ruta da por terminada
/// la animación recién cuando el reloj pasa de su duración, y así termina a los 280 ms.
const _volver = Duration(microseconds: 279999);

/// Una raíz de pestaña o el login: aparece sin animación, se llegue como se llegue.
Page<void> paginaDeRaiz(
  BuildContext context,
  GoRouterState estado,
  Widget hijo,
) => NoTransitionPage<void>(key: estado.pageKey, child: hijo);

/// Una pantalla hija: entra desde la derecha y sale hacia la derecha.
Page<void> paginaQueAvanza(
  BuildContext context,
  GoRouterState estado,
  Widget hijo,
) {
  final quieta = MediaQuery.disableAnimationsOf(context);
  return CustomTransitionPage<void>(
    key: estado.pageKey,
    child: hijo,
    transitionDuration: quieta ? Duration.zero : Movimiento.avanzar,
    reverseTransitionDuration: quieta ? Duration.zero : _volver,
    transitionsBuilder: (context, animation, _, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Movimiento.salida)).animate(animation),
        child: child,
      );
    },
  );
}

/// Una pantalla de resultado: aparece con un fundido.
Page<void> paginaDeResultado(
  BuildContext context,
  GoRouterState estado,
  Widget hijo,
) {
  final quieta = MediaQuery.disableAnimationsOf(context);
  return CustomTransitionPage<void>(
    key: estado.pageKey,
    child: hijo,
    transitionDuration: quieta ? Duration.zero : Movimiento.fundido,
    reverseTransitionDuration: quieta ? Duration.zero : Movimiento.fundido,
    transitionsBuilder: (context, animation, _, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

/// Una pantalla que sube desde abajo y sale hacia abajo, para una ruta que se abre con el
/// `Navigator`.
Route<T> rutaQueSube<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final quieta = MediaQuery.disableAnimationsOf(context);
  return PageRouteBuilder<T>(
    fullscreenDialog: true,
    transitionDuration: quieta ? Duration.zero : Movimiento.subida,
    reverseTransitionDuration: quieta ? Duration.zero : Movimiento.subida,
    pageBuilder: (context, _, _) => builder(context),
    transitionsBuilder: _subida,
  );
}

Widget _subida(
  BuildContext context,
  Animation<double> animation,
  Animation<double> _,
  Widget child,
) {
  if (MediaQuery.disableAnimationsOf(context)) return child;
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).chain(CurveTween(curve: Movimiento.suave)).animate(animation),
    child: child,
  );
}
