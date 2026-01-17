import 'package:flutter/foundation.dart' show kIsWeb;
import '../database_helper.dart';
import '../database_web.dart';
import '../../domain/models/account.dart';
import '../../services/supabase_service.dart';

/// Repository for Account CRUD operations
/// Uses Supabase as primary backend, with local sqflite as fallback for offline mode
class AccountRepository {
  final SupabaseService _supabase = SupabaseService.instance;
  final DatabaseHelper? _dbHelper = kIsWeb ? null : DatabaseHelper.instance;
  final WebDatabaseHelper? _webHelper = kIsWeb ? WebDatabaseHelper.instance : null;

  /// Get all active accounts for current user
  Future<List<Account>> getAll() async {
    try {
      // Try Supabase first (cloud)
      if (_supabase.isAuthenticated) {
        final userId = _supabase.currentUserId;
        final response = await _supabase.client
            .from('accounts')
            .select()
            .eq('user_id', userId!)
            .eq('is_active', true)
            .order('created_at', ascending: false);

        return (response as List)
            .map((json) => Account.fromSupabase(json))
            .toList();
      }
    } catch (e) {
      print('⚠️ Error fetching from Supabase, using local: $e');
    }

    // Fallback to local database
    return _getFromLocal();
  }

  Future<List<Account>> _getFromLocal() async {
    if (kIsWeb) {
      final maps = await _webHelper!.getAccounts();
      return maps.map((map) => Account.fromJson(map)).toList();
    } else {
      final db = await _dbHelper!.database;
      final maps = await db.query('accounts', where: 'isActive = ?', whereArgs: [1]);
      return maps.map((map) => Account.fromJson(map)).toList();
    }
  }

  /// Get account by ID
  Future<Account?> getById(String id) async {
    try {
      if (_supabase.isAuthenticated) {
        final response = await _supabase.client
            .from('accounts')
            .select()
            .eq('id', id)
            .single();

        return Account.fromSupabase(response);
      }
    } catch (e) {
      print('⚠️ Error fetching account: $e');
    }

    return null;
  }

  /// Create new account
  Future<Account> create(Account account) async {
    try {
      if (_supabase.isAuthenticated) {
        final userId = _supabase.currentUserId!;
        
        final data = {
          'user_id': userId,
          'name': account.name,
          'type': account.type,
          'balance': account.balance,
          'currency': account.currency,
          'is_active': account.isActive,
        };

        final response = await _supabase.client
            .from('accounts')
            .insert(data)
            .select()
            .single();

        final created = Account.fromSupabase(response);
        
        // También guardar localmente para modo offline
        await _saveToLocal(created);
        
        return created;
      }
    } catch (e) {
      print('❌ Error creating account in Supabase: $e');
      throw Exception('No se pudo crear la cuenta: $e');
    }

    throw Exception('No autenticado');
  }

  Future<void> _saveToLocal(Account account) async {
    if (kIsWeb) return; // No local storage in web
    
    try {
      final db = await _dbHelper!.database;
      await db.insert('accounts', account.toJson());
    } catch (e) {
      print('⚠️ Error saving to local: $e');
    }
  }

  /// Update existing account
  Future<Account> update(Account account) async {
    try {
      if (_supabase.isAuthenticated && account.id != null) {
        final data = {
          'name': account.name,
          'type': account.type,
          'balance': account.balance,
          'currency': account.currency,
          'is_active': account.isActive,
        };

        await _supabase.client
            .from('accounts')
            .update(data)
            .eq('id', account.id!);

        return account;
      }
    } catch (e) {
      print('❌ Error updating account: $e');
      throw Exception('No se pudo actualizar la cuenta: $e');
    }

    throw Exception('No autenticado o cuenta sin ID');
  }

  /// Soft delete account (mark as inactive)
  Future<void> delete(String id) async {
    try {
      if (_supabase.isAuthenticated) {
        await _supabase.client
            .from('accounts')
            .update({'is_active': false})
            .eq('id', id);
      }
    } catch (e) {
      print('❌ Error deleting account: $e');
      throw Exception('No se pudo eliminar la cuenta: $e');
    }
  }

  /// Get total balance across all accounts
  Future<double> getTotalBalance() async {
    final accounts = await getAll();
    return accounts.fold<double>(0.0, (sum, account) => sum + account.balance);
  }

  /// Watch accounts in real-time (Supabase Realtime)
  Stream<List<Account>> watchAll() {
    if (!_supabase.isAuthenticated) {
      return Stream.value([]);
    }

    final userId = _supabase.currentUserId!;
    
    return _supabase.client
        .from('accounts')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data
            .where((json) => json['is_active'] == true)
            .map((json) => Account.fromSupabase(json))
            .toList());
  }
}
