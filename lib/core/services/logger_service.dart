import 'package:flutter/foundation.dart';

/// Servicio de logging para la aplicación
/// Solo muestra logs en modo debug, nunca en producción
class AppLogger {
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ $message');
    }
  }

  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ $message');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ $message');
    }
  }

  static void error(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('❌ $message${error != null ? ': $error' : ''}');
    }
  }
}
