import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/user.dart';

class SessionService {
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyIsLoggedIn = 'is_logged_in';

  final SharedPreferences _prefs;

  SessionService(this._prefs);

  // Guardar sesión de usuario
  Future<void> saveSession(User user) async {
    await _prefs.setInt(_keyUserId, user.id ?? 0);
    await _prefs.setString(_keyUserEmail, user.email);
    await _prefs.setString(_keyUserName, user.name);
    await _prefs.setBool(_keyIsLoggedIn, true);
  }

  // Obtener ID de usuario actual
  int? getUserId() {
    return _prefs.getInt(_keyUserId);
  }

  // Obtener email de usuario actual
  String? getUserEmail() {
    return _prefs.getString(_keyUserEmail);
  }

  // Obtener nombre de usuario actual
  String? getUserName() {
    return _prefs.getString(_keyUserName);
  }

  // Verificar si hay sesión activa
  bool isLoggedIn() {
    return _prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Cerrar sesión
  Future<void> logout() async {
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyUserEmail);
    await _prefs.remove(_keyUserName);
    await _prefs.setBool(_keyIsLoggedIn, false);
  }

  // Limpiar todos los datos de sesión
  Future<void> clearSession() async {
    await _prefs.clear();
  }
}
