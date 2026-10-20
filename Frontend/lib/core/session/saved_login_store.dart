/// Author / Project Supervisor : Omar Terro
/// GitHub                      : https://github.com/IOTERRO
/// Website                     : https://omarterro.fr
/// Student (FYP)               : Khaled Othman
/// Date                        : 20 October 2026
/// Project                     : SmartUni - Smart University CityU
import 'package:shared_preferences/shared_preferences.dart';

/// Persists optional "Remember me" login fields on device (SharedPreferences).
class SavedLoginStore {
  SavedLoginStore._();

  static const _studentRemember = 'login.student.remember';
  static const _studentId = 'login.student.id';
  static const _studentPassword = 'login.student.password';

  static const _adminRemember = 'login.admin.remember';
  static const _adminUsername = 'login.admin.username';
  static const _adminPassword = 'login.admin.password';

  static Future<({bool remember, String id, String password})>
      loadStudent() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_studentRemember) ?? false;
    if (!remember) {
      return (remember: false, id: '', password: '');
    }
    return (
      remember: true,
      id: prefs.getString(_studentId) ?? '',
      password: prefs.getString(_studentPassword) ?? '',
    );
  }

  static Future<void> saveStudent({
    required bool remember,
    required String id,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!remember) {
      await prefs.remove(_studentRemember);
      await prefs.remove(_studentId);
      await prefs.remove(_studentPassword);
      return;
    }
    await prefs.setBool(_studentRemember, true);
    await prefs.setString(_studentId, id.trim());
    await prefs.setString(_studentPassword, password);
  }

  static Future<({bool remember, String username, String password})>
      loadAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_adminRemember) ?? false;
    if (!remember) {
      return (remember: false, username: '', password: '');
    }
    return (
      remember: true,
      username: prefs.getString(_adminUsername) ?? '',
      password: prefs.getString(_adminPassword) ?? '',
    );
  }

  static Future<void> saveAdmin({
    required bool remember,
    required String username,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!remember) {
      await prefs.remove(_adminRemember);
      await prefs.remove(_adminUsername);
      await prefs.remove(_adminPassword);
      return;
    }
    await prefs.setBool(_adminRemember, true);
    await prefs.setString(_adminUsername, username.trim());
    await prefs.setString(_adminPassword, password);
  }
}
