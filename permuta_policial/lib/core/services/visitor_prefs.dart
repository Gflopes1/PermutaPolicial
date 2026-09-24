import 'package:shared_preferences/shared_preferences.dart';

/// Persiste a escolha de navegar como visitante (mapa sem login).
class VisitorPrefs {
  VisitorPrefs._();

  static const _key = 'visitor_mode_enabled';

  static Future<bool> isVisitorMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> setVisitorMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
  }

  static Future<void> clear() => setVisitorMode(false);
}
