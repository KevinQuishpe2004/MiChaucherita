import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mi_chaucherita/core/data/database_helper.dart';
import 'package:mi_chaucherita/core/data/repositories/account_repository.dart';
import 'package:mi_chaucherita/core/data/repositories/category_repository.dart';
import 'package:mi_chaucherita/core/data/repositories/transaction_repository.dart';
import 'package:mi_chaucherita/core/domain/models/account.dart';
import 'package:mi_chaucherita/core/domain/models/transaction.dart' as models;

void main() {
  // Inicializar sqflite_ffi para tests
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Tests', () {
    late AccountRepository accountRepo;
    late CategoryRepository categoryRepo;
    late TransactionRepository transactionRepo;

    setUp(() async {
      accountRepo = AccountRepository();
      categoryRepo = CategoryRepository();
      transactionRepo = TransactionRepository();
      
      // Limpiar base de datos antes de cada test
      final db = await DatabaseHelper.instance.database;
      await db.delete('transactions');
      await db.delete('accounts');
      await db.delete('categories');
      
      // Re-seed data
      await DatabaseHelper.instance.database;
    });

    test('Database should have seed accounts', () async {
      final accounts = await accountRepo.getAll();
      
      expect(accounts.length, greaterThanOrEqualTo(4));
      expect(accounts.any((a) => a.name == 'Efectivo'), true);
      expect(accounts.any((a) => a.name == 'Banco BCP'), true);
    });

    test('Database should have seed categories', () async {
      final categories = await categoryRepo.getAll();
      
      expect(categories.length, greaterThanOrEqualTo(15));
      expect(categories.any((c) => c.name == 'Salario'), true);
      expect(categories.any((c) => c.name == 'Alimentación'), true);
    });

    test('Should create a new account', () async {
      final newAccount = Account(
        id: null,
        name: 'Test Account',
        type: 'savings',
        balance: 1000.0,
        currency: 'PEN',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final created = await accountRepo.create(newAccount);
      
      expect(created.id, greaterThan(0));
      expect(created.name, 'Test Account');
      expect(created.balance, 1000.0);
    });

    test('Should update account balance', () async {
      final accounts = await accountRepo.getAll();
      final account = accounts.first;
      
      final updated = account.copyWith(balance: 5000.0);
      await accountRepo.update(updated);
      
      final fetched = await accountRepo.getById(account.id!);
      expect(fetched?.balance, 5000.0);
    });

    test('Should create transaction and update account balance', () async {
      final accounts = await accountRepo.getAll();
      final account = accounts.first;
      final initialBalance = account.balance;

      final categories = await categoryRepo.getAll();
      final category = categories.first;

      final transaction = models.Transaction(
        id: null,
        accountId: account.id!,
        categoryId: category.id.toString(),
        type: 'income',
        amount: 500.0,
        description: 'Test income',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await transactionRepo.create(transaction);

      // Verificar que el balance de la cuenta aumentó
      final updatedAccount = await accountRepo.getById(account.id!);
      expect(updatedAccount?.balance, initialBalance + 500.0);
    });

    test('Should get recent transactions', () async {
      final accounts = await accountRepo.getAll();
      final categories = await categoryRepo.getAll();

      // Crear varias transacciones
      for (int i = 0; i < 5; i++) {
        final transaction = models.Transaction(
          id: null,
          accountId: accounts.first.id!,
          categoryId: categories.first.id.toString(),
          type: i % 2 == 0 ? 'income' : 'expense',
          amount: 100.0 * (i + 1),
          description: 'Test transaction $i',
          date: DateTime.now().subtract(Duration(days: i)),
          createdAt: DateTime.now(),
        );
        await transactionRepo.create(transaction);
      }

      final recent = await transactionRepo.getRecent(limit: 3);
      expect(recent.length, 3);
    });

    test('Should get transactions by date range', () async {
      final accounts = await accountRepo.getAll();
      final categories = await categoryRepo.getAll();

      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final twoDaysAgo = now.subtract(const Duration(days: 2));

      // Crear transacciones en diferentes fechas
      await transactionRepo.create(models.Transaction(
        id: null,
        accountId: accounts.first.id!,
        categoryId: categories.first.id.toString(),
        type: 'income',
        amount: 100.0,
        description: 'Today',
        date: now,
        createdAt: now,
      ));

      await transactionRepo.create(models.Transaction(
        id: null,
        accountId: accounts.first.id!,
        categoryId: categories.first.id.toString(),
        type: 'expense',
        amount: 50.0,
        description: 'Yesterday',
        date: yesterday,
        createdAt: now,
      ));

      final rangeTransactions = await transactionRepo.getByDateRange(
        yesterday.subtract(const Duration(hours: 1)),
        now.add(const Duration(hours: 1)),
      );

      expect(rangeTransactions.length, 2);
    });

    test('Should calculate total balance across all accounts', () async {
      final totalBalance = await accountRepo.getTotalBalance();
      expect(totalBalance, greaterThan(0));
    });

    test('Should delete transaction and restore account balance', () async {
      final accounts = await accountRepo.getAll();
      final account = accounts.first;
      final initialBalance = account.balance;

      final categories = await categoryRepo.getAll();
      
      // Crear transacción de gasto
      final transaction = models.Transaction(
        id: null,
        accountId: account.id!,
        categoryId: categories.first.id.toString(),
        type: 'expense',
        amount: 200.0,
        description: 'Test expense',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final created = await transactionRepo.create(transaction);
      
      // Verificar que el balance disminuyó
      var updatedAccount = await accountRepo.getById(account.id!);
      expect(updatedAccount?.balance, initialBalance - 200.0);

      // Eliminar la transacción
      await transactionRepo.delete(created.id!);

      // Verificar que el balance se restauró
      updatedAccount = await accountRepo.getById(account.id!);
      expect(updatedAccount?.balance, initialBalance);
    });
  });
}
