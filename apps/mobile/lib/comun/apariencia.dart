import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// El modo claro u oscuro de toda la app. Se guarda en el dispositivo, así que sobrevive a
/// cerrar la sesión; la primera vez arranca en oscuro.
class Apariencia extends ChangeNotifier {
  Apariencia._(this._preferencias, this._oscuro);

  /// Sin guardar nada: para mostrar pantallas sueltas, como en las capturas.
  Apariencia.enMemoria({bool oscuro = true}) : this._(null, oscuro);

  static const _clave = 'modo_oscuro';

  static Future<Apariencia> cargar() async {
    final preferencias = await SharedPreferences.getInstance();
    return Apariencia._(preferencias, preferencias.getBool(_clave) ?? true);
  }

  final SharedPreferences? _preferencias;
  bool _oscuro;

  bool get oscuro => _oscuro;

  ThemeMode get modo => _oscuro ? ThemeMode.dark : ThemeMode.light;

  Future<void> cambiar({required bool oscuro}) async {
    if (oscuro == _oscuro) return;
    _oscuro = oscuro;
    notifyListeners();
    await _preferencias?.setBool(_clave, oscuro);
  }
}
