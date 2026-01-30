import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuración de Supabase - ARCHIVO DE EJEMPLO
/// 
/// INSTRUCCIONES PARA CONFIGURAR:
/// 1. Copia este archivo y renómbralo a 'supabase_config.dart'
/// 2. Ve a https://supabase.com y accede al proyecto
/// 3. En Settings > API encontrarás:
///    - Project URL (supabaseUrl)
///    - Project API keys > anon public (supabaseAnonKey)
/// 4. Reemplaza los valores de TU_SUPABASE_URL_AQUI y TU_SUPABASE_ANON_KEY_AQUI
/// 
/// IMPORTANTE: 
/// - NO compartas el archivo supabase_config.dart real (está en .gitignore)
/// - Solo comparte este archivo de ejemplo
/// - Cada desarrollador debe crear su propia copia del archivo

class SupabaseConfig {
  /// URL de tu proyecto de Supabase
  /// Ejemplo: 'https://xyzcompany.supabase.co'
  static const String supabaseUrl = 'TU_SUPABASE_URL_AQUI';

  /// Clave pública (anon key) de tu proyecto
  /// Ejemplo: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
  static const String supabaseAnonKey = 'TU_SUPABASE_ANON_KEY_AQUI';

  /// Cliente de Supabase
  static SupabaseClient get client => Supabase.instance.client;

  /// Verifica si las credenciales están configuradas
  static bool get isConfigured {
    return supabaseUrl != 'TU_SUPABASE_URL_AQUI' &&
        supabaseAnonKey != 'TU_SUPABASE_ANON_KEY_AQUI' &&
        supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty;
  }
}
