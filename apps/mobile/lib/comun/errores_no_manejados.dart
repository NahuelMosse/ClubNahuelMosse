import 'package:flutter/foundation.dart';

/// Deja constancia de [error] en la consola de desarrollo, sin molestar a la persona.
void registrarError(Object error, [StackTrace? pila]) =>
    debugPrint('Error registrado: $error\n${pila ?? ''}');
