import 'package:shared_preferences/shared_preferences.dart';

class TutoService {
  static const String _prefix = 'hide_tuto_';

  static Future<bool> isPermanentlyHidden(String screenKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$screenKey') ?? false;
  }

  static Future<void> markAsPermanentlyHidden(String screenKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$screenKey', true);
  }

  static Future<void> resetAllTutos() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (String key in keys) {
      await prefs.remove(key);
    }
  }
}