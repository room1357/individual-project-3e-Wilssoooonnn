import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _kUserPrefix = 'user_';

  static Future<void> _ensureAdminExists() async {
    final prefs = await SharedPreferences.getInstance();
    final adminKey = '$_kUserPrefix-admin';

    if (prefs.getString(adminKey) == null) {
      await prefs.setString(adminKey, 'admin123');
    }
  }

  static Future<bool> login(String username, String password) async {
    await _ensureAdminExists();

    final prefs = await SharedPreferences.getInstance();

    final userKey = '$_kUserPrefix$username';

    final String? storedPassword = prefs.getString(userKey);

    if (storedPassword == null) {
      return false;
    }

    return storedPassword == password;
  }

  static Future<bool> register(String username, String password) async {
    await _ensureAdminExists();

    final prefs = await SharedPreferences.getInstance();

    final userKey = '$_kUserPrefix$username';

    if (prefs.getString(userKey) != null) {
      return false;
    }

    await prefs.setString(userKey, password);
    return true;
  }
}
