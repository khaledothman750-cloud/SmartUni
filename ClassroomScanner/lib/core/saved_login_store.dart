// Author / Project Supervisor : Omar Terro
// GitHub                      : https://github.com/IOTERRO
// Website                     : https://omarterro.fr
// Student (FYP)               : Khaled Othman
// Date                        : 20 October 2026
// Project                     : SmartUni - Classroom Scanner
import 'package:shared_preferences/shared_preferences.dart';

/// Persists optional "Remember me" admin login on this device.
class SavedLoginStore {
  SavedLoginStore._();

  static const _rememberKey = 'scanner.login.remember';
  static const _usernameKey = 'scanner.login.username';
  static const _passwordKey = 'scanner.login.password';

  static Future<({bool remember, String username, String password})>
      load() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_rememberKey) ?? false;
    if (!remember) {
      return (remember: false, username: '', password: '');
    }
    return (
      remember: true,
      username: prefs.getString(_usernameKey) ?? '',
      password: prefs.getString(_passwordKey) ?? '',
    );
  }

  static Future<void> save({
    required bool remember,
    required String username,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!remember) {
      await prefs.remove(_rememberKey);
      await prefs.remove(_usernameKey);
      await prefs.remove(_passwordKey);
      return;
    }
    await prefs.setBool(_rememberKey, true);
    await prefs.setString(_usernameKey, username.trim());
    await prefs.setString(_passwordKey, password);
  }
}
