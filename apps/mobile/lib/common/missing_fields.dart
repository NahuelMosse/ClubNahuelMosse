// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/widgets.dart';

/// The error a form shows under a field: the one the server gave and, if none, the one from
/// the rules, but only from the first submit attempt on or if the person already went through
/// the field with something typed. Leaving an empty field marks nothing.
String? errorToShow({
  String? serverError,
  required String? ruleError,
  required bool attempted,
  required bool touched,
}) => serverError ?? (attempted || touched ? ruleError : null);

/// Moves focus to the first of [fields] that has an error. A selector, which has no focus
/// of its own, does not get it.
void focusFirstMissing(Iterable<(FocusNode?, String?)> fields) {
  for (final (focus, error) in fields) {
    if (error == null) continue;
    focus?.requestFocus();
    return;
  }
}
