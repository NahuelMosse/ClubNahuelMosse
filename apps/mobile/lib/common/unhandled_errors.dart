// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/foundation.dart';

/// Leaves a record of [error] in the development console, without bothering the person.
void logError(Object error, [StackTrace? stackTrace]) =>
    debugPrint('Error registrado: $error\n${stackTrace ?? ''}');
