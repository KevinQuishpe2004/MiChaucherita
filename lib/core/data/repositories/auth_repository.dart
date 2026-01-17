import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user.dart' as app_user;
import '../../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository for authentication using Supabase
class AuthRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  // Stream para observar cambios en el estado de autenticación
  Stream<AuthState> get authStateChanges => _supabase.authStateChanges;

  // Usuario actual
  User? get currentUser => _supabase.currentUser;
  String? get currentUserId => _supabase.currentUserId;
  bool get isAuthenticated => _supabase.isAuthenticated;

  /// Registrar nuevo usuario
  Future<app_user.User> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _supabase.signUp(
        email: email,
        password: password,
        name: name,
      );

      if (response.user == null) {
        throw Exception('Error al crear usuario. Verifica que el email no esté registrado.');
      }

      // Guardar session local
      await _saveSession(response.user!.id);

      return app_user.User(
        id: null, // Supabase usa UUID como string, no int
        email: response.user!.email!,
        password: '', // Never store plain passwords
        name: name,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
    } on AuthException catch (e) {
      print('❌ AuthException: ${e.message} - Status: ${e.statusCode}');
      throw Exception(_getAuthErrorMessage(e));
    } catch (e) {
      print('❌ Error desconocido al registrar: $e');
      throw Exception('Error al registrar: $e');
    }
  }

  /// Iniciar sesión
  Future<app_user.User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.signIn(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Error al iniciar sesión');
      }

      // Guardar session local
      await _saveSession(response.user!.id);

      final userMetadata = response.user!.userMetadata;
      final name = userMetadata?['name'] as String? ?? 'Usuario';

      return app_user.User(
        id: null,
        email: response.user!.email!,
        password: '',
        name: name,
        createdAt: DateTime.parse(response.user!.createdAt),
        lastLoginAt: DateTime.now(),
      );
    } on AuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    try {
      await _supabase.signOut();
      await _clearSession();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  /// Obtener usuario actual
  Future<app_user.User?> getCurrentUser() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final userMetadata = user.userMetadata;
      final name = userMetadata?['name'] as String? ?? 'Usuario';

      return app_user.User(
        id: null,
        email: user.email!,
        password: '',
        name: name,
        createdAt: DateTime.parse(user.createdAt),
        lastLoginAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Verificar si hay sesión guardada
  Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    return userId != null && isAuthenticated;
  }

  /// Guardar sesión localmente
  Future<void> _saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }

  /// Limpiar sesión local
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }

  /// Traducir errores de autenticación
  String _getAuthErrorMessage(AuthException error) {
    final message = error.message.toLowerCase();
    
    // Manejar mensajes específicos de Supabase
    if (message.contains('user already registered')) {
      return 'Este correo ya está registrado. Intenta iniciar sesión.';
    }
    if (message.contains('email not confirmed')) {
      return 'Debes confirmar tu correo. Revisa tu bandeja de entrada.';
    }
    if (message.contains('invalid email')) {
      return 'El formato del correo es inválido.';
    }
    if (message.contains('password')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (message.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    
    // Fallback por código de estado
    switch (error.statusCode) {
      case '400':
        return 'Datos inválidos. Verifica tu correo y contraseña.';
      case '401':
        return 'Correo o contraseña incorrectos.';
      case '422':
        return 'El correo ya está registrado.';
      case '429':
        return 'Demasiados intentos. Intenta más tarde.';
      default:
        return error.message;
    }
  }

  // Métodos legacy para compatibilidad (ya no se usan con Supabase)
  Future<app_user.User?> getUserById(int userId) async {
    return getCurrentUser();
  }

  Future<bool> updateProfile({
    required int userId,
    String? name,
    String? email,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;

      if (updates.isNotEmpty) {
        await _supabase.client.auth.updateUser(
          UserAttributes(data: updates),
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _supabase.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUser(int userId) async {
    // Supabase maneja esto a través del admin API o políticas RLS
    return false;
  }
}
