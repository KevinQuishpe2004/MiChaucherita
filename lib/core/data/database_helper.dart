import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mi_chaucherita.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;

    // Para desarrollo en Windows/Desktop
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    } else {
      // Para Android/iOS usar path_provider
      final dbPath = await getApplicationDocumentsDirectory();
      path = join(dbPath.path, filePath);
    }

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Agregar tabla de usuarios
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          name TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          lastLoginAt TEXT
        )
      ''');

      // Agregar columna userId a las tablas existentes
      await db.execute('ALTER TABLE accounts ADD COLUMN userId INTEGER');
      await db.execute('ALTER TABLE transactions ADD COLUMN userId INTEGER');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabla Users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        lastLoginAt TEXT
      )
    ''');

    // Tabla Accounts
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        currency TEXT NOT NULL DEFAULT 'PEN',
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Tabla Categories
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Tabla Transactions
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        accountId INTEGER NOT NULL,
        categoryId INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        userId INTEGER,
        FOREIGN KEY (accountId) REFERENCES accounts (id),
        FOREIGN KEY (categoryId) REFERENCES categories (id),
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');
  }

  Future<void> _onOpen(Database db) async {
    // Verificar si ya hay datos
    final accountsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM accounts'),
    );

    if (accountsCount == 0) {
      // Seed inicial
      await _seedData(db);
    }
  }

  Future<void> _seedData(Database db) async {
    // Insertar cuentas
    await db.insert('accounts', {
      'name': 'Efectivo',
      'type': 'cash',
      'balance': 500.0,
      'currency': 'PEN',
      'isActive': 1,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await db.insert('accounts', {
      'name': 'Banco BCP',
      'type': 'bank',
      'balance': 2500.0,
      'currency': 'PEN',
      'isActive': 1,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await db.insert('accounts', {
      'name': 'Tarjeta Visa',
      'type': 'credit_card',
      'balance': -800.0,
      'currency': 'PEN',
      'isActive': 1,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await db.insert('accounts', {
      'name': 'Ahorros',
      'type': 'savings',
      'balance': 5000.0,
      'currency': 'PEN',
      'isActive': 1,
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Insertar categorías
    final categories = [
      {'name': 'Alimentación', 'type': 'expense', 'icon': '🍔', 'color': '#FF5252'},
      {'name': 'Transporte', 'type': 'expense', 'icon': '🚗', 'color': '#FF9800'},
      {'name': 'Vivienda', 'type': 'expense', 'icon': '🏠', 'color': '#9C27B0'},
      {'name': 'Servicios', 'type': 'expense', 'icon': '💡', 'color': '#2196F3'},
      {'name': 'Salud', 'type': 'expense', 'icon': '💊', 'color': '#4CAF50'},
      {'name': 'Educación', 'type': 'expense', 'icon': '📚', 'color': '#00BCD4'},
      {'name': 'Entretenimiento', 'type': 'expense', 'icon': '🎮', 'color': '#E91E63'},
      {'name': 'Compras', 'type': 'expense', 'icon': '🛍️', 'color': '#FFC107'},
      {'name': 'Salario', 'type': 'income', 'icon': '💰', 'color': '#4CAF50'},
      {'name': 'Freelance', 'type': 'income', 'icon': '💼', 'color': '#2196F3'},
      {'name': 'Inversiones', 'type': 'income', 'icon': '📈', 'color': '#9C27B0'},
      {'name': 'Otros Ingresos', 'type': 'income', 'icon': '💵', 'color': '#00BCD4'},
      {'name': 'Transferencia', 'type': 'transfer', 'icon': '🔄', 'color': '#607D8B'},
      {'name': 'Ajuste', 'type': 'transfer', 'icon': '⚙️', 'color': '#9E9E9E'},
      {'name': 'Otros Gastos', 'type': 'expense', 'icon': '📦', 'color': '#795548'},
    ];

    for (final category in categories) {
      await db.insert('categories', {
        ...category,
        'isActive': 1,
      });
    }

    // Insertar transacciones de prueba
    final now = DateTime.now();
    final transactions = [
      // Ingresos del mes
      {'accountId': 2, 'categoryId': 9, 'type': 'income', 'amount': 3500.0, 'description': 'Salario Enero', 'date': now.subtract(const Duration(days: 15))},
      {'accountId': 2, 'categoryId': 10, 'type': 'income', 'amount': 800.0, 'description': 'Proyecto freelance web', 'date': now.subtract(const Duration(days: 10))},
      {'accountId': 1, 'categoryId': 12, 'type': 'income', 'amount': 150.0, 'description': 'Venta de artículos usados', 'date': now.subtract(const Duration(days: 5))},
      
      // Gastos variados
      {'accountId': 1, 'categoryId': 1, 'type': 'expense', 'amount': 45.50, 'description': 'Almuerzo en restaurante', 'date': now.subtract(const Duration(days: 1))},
      {'accountId': 1, 'categoryId': 1, 'type': 'expense', 'amount': 120.0, 'description': 'Compras supermercado', 'date': now.subtract(const Duration(days: 2))},
      {'accountId': 2, 'categoryId': 2, 'type': 'expense', 'amount': 50.0, 'description': 'Gasolina', 'date': now.subtract(const Duration(days: 3))},
      {'accountId': 2, 'categoryId': 4, 'type': 'expense', 'amount': 89.90, 'description': 'Recibo de luz', 'date': now.subtract(const Duration(days: 4))},
      {'accountId': 2, 'categoryId': 4, 'type': 'expense', 'amount': 65.0, 'description': 'Recibo de agua', 'date': now.subtract(const Duration(days: 4))},
      {'accountId': 2, 'categoryId': 4, 'type': 'expense', 'amount': 99.0, 'description': 'Internet y cable', 'date': now.subtract(const Duration(days: 5))},
      {'accountId': 3, 'categoryId': 7, 'type': 'expense', 'amount': 35.0, 'description': 'Netflix', 'date': now.subtract(const Duration(days: 6))},
      {'accountId': 3, 'categoryId': 7, 'type': 'expense', 'amount': 19.90, 'description': 'Spotify', 'date': now.subtract(const Duration(days: 6))},
      {'accountId': 1, 'categoryId': 1, 'type': 'expense', 'amount': 25.0, 'description': 'Café y snacks', 'date': now.subtract(const Duration(days: 7))},
      {'accountId': 2, 'categoryId': 5, 'type': 'expense', 'amount': 150.0, 'description': 'Medicinas', 'date': now.subtract(const Duration(days: 8))},
      {'accountId': 1, 'categoryId': 2, 'type': 'expense', 'amount': 8.50, 'description': 'Taxi', 'date': now.subtract(const Duration(days: 9))},
      {'accountId': 2, 'categoryId': 6, 'type': 'expense', 'amount': 200.0, 'description': 'Curso online', 'date': now.subtract(const Duration(days: 12))},
      {'accountId': 3, 'categoryId': 8, 'type': 'expense', 'amount': 180.0, 'description': 'Ropa nueva', 'date': now.subtract(const Duration(days: 14))},
    ];

    for (final tx in transactions) {
      await db.insert('transactions', {
        'accountId': tx['accountId'],
        'categoryId': tx['categoryId'],
        'type': tx['type'],
        'amount': tx['amount'],
        'description': tx['description'],
        'date': (tx['date'] as DateTime).toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
