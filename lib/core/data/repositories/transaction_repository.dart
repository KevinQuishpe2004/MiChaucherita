import 'package:flutter/foundation.dart' show kIsWeb;
import '../database_helper.dart';
import '../database_web.dart';
import '../../domain/models/transaction.dart';
import '../../services/supabase_service.dart';
import '../../services/logger_service.dart';

/// Repository for Transaction CRUD operations
/// Uses Supabase as primary backend, with local sqflite as fallback for offline mode
class TransactionRepository {
  final SupabaseService _supabase = SupabaseService.instance;
  final DatabaseHelper? _dbHelper = kIsWeb ? null : DatabaseHelper.instance;
  final WebDatabaseHelper? _webHelper = kIsWeb ? WebDatabaseHelper.instance : null;

  /// Get all transactions for current user
  Future<List<Transaction>> getAll({int limit = 100, String? accountId}) async {
    try {
      if (_supabase.isAuthenticated) {
        final userId = _supabase.currentUserId;
        
        dynamic query = _supabase.client
            .from('transactions')
            .select()
            .eq('user_id', userId!);

        if (accountId != null) {
          query = query.eq('account_id', accountId);
        }

        query = query.order('date', ascending: false).limit(limit);

        final response = await query;
        return (response as List)
            .map((json) => Transaction.fromSupabase(json))
            .toList();
      }
    } catch (e) {
      AppLogger.warning('Error fetching transactions from Supabase: $e');
    }

    return _getFromLocal(limit: limit);
  }

  Future<List<Transaction>> _getFromLocal({int limit = 100}) async {
    if (kIsWeb) {
      final maps = await _webHelper!.getTransactions();
      return maps.take(limit).map((map) => Transaction.fromJson(map)).toList();
    } else {
      final db = await _dbHelper!.database;
      final maps = await db.query(
        'transactions',
        orderBy: 'date DESC',
        limit: limit,
      );
      return maps.map((map) => Transaction.fromJson(map)).toList();
    }
  }

  /// Get transaction by ID
  Future<Transaction?> getById(String id) async {
    try {
      if (_supabase.isAuthenticated) {
        final response = await _supabase.client
            .from('transactions')
            .select()
            .eq('id', id)
            .single();

        return Transaction.fromSupabase(response);
      }
    } catch (e) {
      AppLogger.warning('Error fetching transaction: $e');
    }
    return null;
  }

  /// Get recent transactions
  Future<List<Transaction>> getRecent({int limit = 10}) async {
    return getAll(limit: limit);
  }

  /// Get transactions by date range
  Future<List<Transaction>> getByDateRange(DateTime start, DateTime end) async {
    try {
      if (_supabase.isAuthenticated) {
        final userId = _supabase.currentUserId;
        final response = await _supabase.client
            .from('transactions')
            .select()
            .eq('user_id', userId!)
            .gte('date', start.toIso8601String())
            .lte('date', end.toIso8601String())
            .order('date', ascending: false);

        return (response as List)
            .map((json) => Transaction.fromSupabase(json))
            .toList();
      }
    } catch (e) {
      AppLogger.warning('Error fetching by date range: $e');
    }

    // Fallback local
    if (kIsWeb) {
      final maps = await _webHelper!.getTransactionsByDateRange(start, end);
      return maps.map((map) => Transaction.fromJson(map)).toList();
    } else {
      final db = await _dbHelper!.database;
      final maps = await db.query(
        'transactions',
        where: 'date BETWEEN ? AND ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'date DESC',
      );
      return maps.map((map) => Transaction.fromJson(map)).toList();
    }
  }

  /// Get transactions by account
  Future<List<Transaction>> getByAccount(String accountId) async {
    return getAll(accountId: accountId);
  }

  /// Create new transaction
  Future<Transaction> create(Transaction transaction) async {
    try {
      if (_supabase.isAuthenticated) {
        final userId = _supabase.currentUserId!;

        final data = {
          'user_id': userId,
          'account_id': transaction.accountId,
          'category_id': transaction.categoryId,
          'type': transaction.type,
          'amount': transaction.amount,
          'description': transaction.description,
          'date': transaction.date.toIso8601String(),
        };

        final response = await _supabase.client
            .from('transactions')
            .insert(data)
            .select()
            .single();

        final created = Transaction.fromSupabase(response);

        // Actualizar balance de la cuenta
        await _updateAccountBalance(
          transaction.accountId,
          transaction.amount,
          transaction.type,
        );

        return created;
      }
    } catch (e) {
      AppLogger.error('Error creating transaction', e);
      throw Exception('No se pudo crear la transacción: $e');
    }

    throw Exception('No autenticado');
  }

  /// Update existing transaction
  Future<Transaction> update(Transaction transaction) async {
    try {
      if (_supabase.isAuthenticated && transaction.id != null) {
        // Obtener transacción anterior para revertir balance
        final oldTx = await getById(transaction.id!);

        final data = {
          'account_id': transaction.accountId,
          'category_id': transaction.categoryId,
          'type': transaction.type,
          'amount': transaction.amount,
          'description': transaction.description,
          'date': transaction.date.toIso8601String(),
        };

        await _supabase.client
            .from('transactions')
            .update(data)
            .eq('id', transaction.id!);

        // Revertir balance anterior
        if (oldTx != null) {
          await _updateAccountBalance(
            oldTx.accountId,
            oldTx.amount,
            oldTx.type == 'income' ? 'expense' : 'income',
          );
        }

        // Aplicar nuevo balance
        await _updateAccountBalance(
          transaction.accountId,
          transaction.amount,
          transaction.type,
        );

        return transaction;
      }
    } catch (e) {
      AppLogger.error('Error updating transaction', e);
      throw Exception('No se pudo actualizar la transacción: $e');
    }

    throw Exception('No autenticado o transacción sin ID');
  }

  /// Delete transaction
  Future<void> delete(String id) async {
    try {
      if (_supabase.isAuthenticated) {
        // Obtener transacción para revertir balance
        final tx = await getById(id);

        await _supabase.client
            .from('transactions')
            .delete()
            .eq('id', id);

        // Revertir balance
        if (tx != null) {
          await _updateAccountBalance(
            tx.accountId,
            tx.amount,
            tx.type == 'income' ? 'expense' : 'income',
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error deleting transaction', e);
      throw Exception('No se pudo eliminar la transacción: $e');
    }
  }

  /// Update account balance after transaction
  Future<void> _updateAccountBalance(String accountId, double amount, String type) async {
    try {
      if (_supabase.isAuthenticated) {
        // Obtener balance actual
        final response = await _supabase.client
            .from('accounts')
            .select('balance')
            .eq('id', accountId)
            .single();

        final currentBalance = (response['balance'] as num).toDouble();
        double newBalance;
        
        if (type == 'income') {
          newBalance = currentBalance + amount;
        } else if (type == 'expense') {
          newBalance = currentBalance - amount;
        } else if (type == 'transfer') {
          // Para transferencias, se resta de la cuenta origen
          newBalance = currentBalance - amount;
        } else {
          newBalance = currentBalance;
        }

        // Actualizar balance
        await _supabase.client
            .from('accounts')
            .update({'balance': newBalance})
            .eq('id', accountId);
      }
    } catch (e) {
      AppLogger.warning('Error updating account balance: $e');
    }
  }

  /// Update account balance for transfer destination (adds amount)
  Future<void> updateAccountBalanceForTransfer(String toAccountId, double amount) async {
    try {
      if (_supabase.isAuthenticated) {
        // Obtener balance actual de la cuenta destino
        final response = await _supabase.client
            .from('accounts')
            .select('balance')
            .eq('id', toAccountId)
            .single();

        final currentBalance = (response['balance'] as num).toDouble();
        final newBalance = currentBalance + amount;

        // Actualizar balance (sumar a la cuenta destino)
        await _supabase.client
            .from('accounts')
            .update({'balance': newBalance})
            .eq('id', toAccountId);
      }
    } catch (e) {
      AppLogger.warning('Error updating transfer destination balance: $e');
    }
  }

  /// Get total income for date range
  Future<double> getTotalIncome(DateTime start, DateTime end) async {
    final transactions = await getByDateRange(start, end);
    return transactions
        .where((t) => t.type == 'income')
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  /// Get total expense for date range
  Future<double> getTotalExpense(DateTime start, DateTime end) async {
    final transactions = await getByDateRange(start, end);
    return transactions
        .where((t) => t.type == 'expense')
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  /// Watch transactions in real-time
  Stream<List<Transaction>> watchRecent({int limit = 10}) {
    if (!_supabase.isAuthenticated) {
      return Stream.value([]);
    }

    final userId = _supabase.currentUserId!;

    return _supabase.client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('date', ascending: false)
        .limit(limit)
        .map((data) => data.map((json) => Transaction.fromSupabase(json)).toList());
  }

  /// Watch transactions by date range
  Stream<List<Transaction>> watchByDateRange(DateTime start, DateTime end) {
    if (!_supabase.isAuthenticated) {
      return Stream.value([]);
    }

    return _supabase.client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .map((data) {
          final transactions = data
              .map((json) => Transaction.fromSupabase(json))
              .where((t) => t.date.isAfter(start.subtract(const Duration(days: 1))) && t.date.isBefore(end.add(const Duration(days: 1))))
              .toList();
          transactions.sort((a, b) => b.date.compareTo(a.date));
          return transactions;
        });
  }

  /// Watch transactions by account
  Stream<List<Transaction>> watchByAccount(String accountId) {
    if (!_supabase.isAuthenticated) {
      return Stream.value([]);
    }

    return _supabase.client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .map((data) {
          final transactions = data
              .map((json) => Transaction.fromSupabase(json))
              .where((t) => t.accountId == accountId)
              .toList();
          transactions.sort((a, b) => b.date.compareTo(a.date));
          return transactions;
        });
  }

  /// Count transactions by account
  Future<int> countByAccount(String accountId) async {
    try {
      if (_supabase.isAuthenticated) {
        final response = await _supabase.client
            .from('transactions')
            .select('id')
            .eq('account_id', accountId);

        return (response as List).length;
      }
    } catch (e) {
      AppLogger.warning('Error counting transactions: $e');
    }
    return 0;
  }
}
