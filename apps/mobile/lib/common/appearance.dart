import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The light or dark mode of the whole app. It is saved on the device, so it survives
/// signing out; the first time it starts in dark.
class Appearance extends ChangeNotifier {
  Appearance._(this._preferences, this._dark);

  /// Saves nothing: to show individual screens, as in the screenshots.
  Appearance.inMemory({bool dark = true}) : this._(null, dark);

  static const _key = 'modo_oscuro';

  static Future<Appearance> load() async {
    final preferences = await SharedPreferences.getInstance();
    return Appearance._(preferences, preferences.getBool(_key) ?? true);
  }

  final SharedPreferences? _preferences;
  bool _dark;

  bool get dark => _dark;

  ThemeMode get mode => _dark ? ThemeMode.dark : ThemeMode.light;

  Future<void> change({required bool dark}) async {
    if (dark == _dark) return;
    _dark = dark;
    notifyListeners();
    await _preferences?.setBool(_key, dark);
  }
}
