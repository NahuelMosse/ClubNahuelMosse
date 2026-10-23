import 'dart:async';
import 'package:flutter/foundation.dart';

/// Dónde queda el rastro de un error que la app no muestra.
typedef RegistroDeError = void Function(Object error, StackTrace? pila);

void _aConsola(Object error, StackTrace? pila) =>
    debugPrint('Error registrado: $error\n${pila ?? ''}');

/// El destino de [registrarError]; por defecto, la consola.
RegistroDeError registroDeErrores = _aConsola;

/// Deja constancia de [error], sin molestar a la persona.
void registrarError(Object error, [StackTrace? pila]) =>
    registroDeErrores(error, pila);

/// Que los errores de widgets y de la plataforma lleguen a [destino] (o a [registrarError]).
void instalarCapturaDeErrores([RegistroDeError? destino]) {
  final RegistroDeError registrar = destino ?? registrarError;
  FlutterError.onError = (detalles) =>
      registrar(detalles.exception, detalles.stack);
  PlatformDispatcher.instance.onError = (error, pila) {
    registrar(error, pila);
    return true;
  };
}

/// Corre [cuerpo] en una zona que registra lo que ningún otro lugar atrapa.
void correrProtegido(void Function() cuerpo, [RegistroDeError? destino]) {
  runZonedGuarded(cuerpo, destino ?? registrarError);
}
