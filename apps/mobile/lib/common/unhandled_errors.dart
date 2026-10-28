import 'package:flutter/foundation.dart';

/// Leaves a record of [error] in the development console, without bothering the person.
void logError(Object error, [StackTrace? stackTrace]) =>
    debugPrint('Error registrado: $error\n${stackTrace ?? ''}');
