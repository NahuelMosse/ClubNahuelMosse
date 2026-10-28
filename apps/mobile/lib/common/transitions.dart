import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'motion.dart';

/// One microsecond less than [AppMotion.back]: the route controller considers the animation
/// finished only when the clock passes its duration, and so it ends at 280 ms.
const _back = Duration(microseconds: 279999);

/// A tab root or the login: appears without animation, however it is reached.
Page<void> rootPage(BuildContext context, GoRouterState state, Widget child) =>
    NoTransitionPage<void>(key: state.pageKey, child: child);

/// A child screen: enters from the right and leaves to the right.
Page<void> forwardPage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  final still = MediaQuery.disableAnimationsOf(context);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: still ? Duration.zero : AppMotion.forward,
    reverseTransitionDuration: still ? Duration.zero : _back,
    transitionsBuilder: (context, animation, _, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: AppMotion.out)).animate(animation),
        child: child,
      );
    },
  );
}

/// A result screen: appears with a fade.
Page<void> resultPage(BuildContext context, GoRouterState state, Widget child) {
  final still = MediaQuery.disableAnimationsOf(context);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: still ? Duration.zero : AppMotion.fade,
    reverseTransitionDuration: still ? Duration.zero : AppMotion.fade,
    transitionsBuilder: (context, animation, _, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

/// A screen that rises from the bottom and leaves downward, for a route opened with the
/// `Navigator`.
Route<T> risingRoute<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final still = MediaQuery.disableAnimationsOf(context);
  return PageRouteBuilder<T>(
    fullscreenDialog: true,
    transitionDuration: still ? Duration.zero : AppMotion.rise,
    reverseTransitionDuration: still ? Duration.zero : AppMotion.rise,
    pageBuilder: (context, _, _) => builder(context),
    transitionsBuilder: _rise,
  );
}

Widget _rise(
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
    ).chain(CurveTween(curve: AppMotion.smooth)).animate(animation),
    child: child,
  );
}
