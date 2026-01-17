import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;
  
  User? get currentUser => client.auth.currentUser;
  String? get currentUserId => currentUser?.id;
  bool get isAuthenticated => currentUser != null;

  /// Initialize Supabase with your project credentials
  /// Call this in main() before runApp()
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  /// Sign up a new user
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
    return response;
  }

  /// Sign in existing user
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  /// Sign out current user
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Check if user is signed in
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Get user profile data
  Map<String, dynamic>? get userMetadata => currentUser?.userMetadata;
}
