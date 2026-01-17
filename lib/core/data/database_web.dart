/// Almacenamiento en memoria para Web (sqflite no funciona en web)
class WebDatabaseHelper {
  static final WebDatabaseHelper instance = WebDatabaseHelper._init();
  
  // Datos en memoria
  final List<Map<String, dynamic>> _accounts = [];
  final List<Map<String, dynamic>> _categories = [];
  final List<Map<String, dynamic>> _transactions = [];
  
  int _accountIdCounter = 1;
  int _categoryIdCounter = 1;
  int _transactionIdCounter = 1;
  
  bool _initialized = false;

  WebDatabaseHelper._init();

  Future<void> initialize() async {
    if (_initialized) return;
    await _seedData();
    _initialized = true;
  }

  // ========== ACCOUNTS ==========
  
  Future<List<Map<String, dynamic>>> getAccounts() async {
    await initialize();
    return List.from(_accounts);
  }

  Future<Map<String, dynamic>?> getAccountById(int id) async {
    await initialize();
    try {
      return _accounts.firstWhere((a) => a['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> insertAccount(Map<String, dynamic> data) async {
    await initialize();
    final account = {...data, 'id': _accountIdCounter++};
    _accounts.add(account);
    return account;
  }

  Future<Map<String, dynamic>> updateAccount(Map<String, dynamic> data) async {
    await initialize();
    final index = _accounts.indexWhere((a) => a['id'] == data['id']);
    if (index != -1) {
      _accounts[index] = data;
    }
    return data;
  }

  Future<void> deleteAccount(int id) async {
    await initialize();
    _accounts.removeWhere((a) => a['id'] == id);
  }

  // ========== CATEGORIES ==========
  
  Future<List<Map<String, dynamic>>> getCategories() async {
    await initialize();
    return List.from(_categories);
  }

  Future<Map<String, dynamic>?> getCategoryById(int id) async {
    await initialize();
    try {
      return _categories.firstWhere((c) => c['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getCategoriesByType(String type) async {
    await initialize();
    return _categories.where((c) => c['type'] == type).toList();
  }

  Future<Map<String, dynamic>> insertCategory(Map<String, dynamic> data) async {
    await initialize();
    final category = {...data, 'id': _categoryIdCounter++};
    _categories.add(category);
    return category;
  }

  // ========== TRANSACTIONS ==========
  
  Future<List<Map<String, dynamic>>> getTransactions() async {
    await initialize();
    return List.from(_transactions)..sort((a, b) => 
      DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
  }

  Future<Map<String, dynamic>?> getTransactionById(int id) async {
    await initialize();
    try {
      return _transactions.firstWhere((t) => t['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getRecentTransactions({int limit = 10}) async {
    await initialize();
    final sorted = List<Map<String, dynamic>>.from(_transactions)
      ..sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    return sorted.take(limit).toList();
  }

  Future<List<Map<String, dynamic>>> getTransactionsByDateRange(DateTime start, DateTime end) async {
    await initialize();
    return _transactions.where((t) {
      final date = DateTime.parse(t['date']);
      return date.isAfter(start.subtract(const Duration(days: 1))) && 
             date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getTransactionsByAccount(int accountId) async {
    await initialize();
    return _transactions.where((t) => t['accountId'] == accountId).toList();
  }

  Future<Map<String, dynamic>> insertTransaction(Map<String, dynamic> data) async {
    await initialize();
    final transaction = {...data, 'id': _transactionIdCounter++};
    _transactions.add(transaction);
    
    // Actualizar balance de cuenta
    final accountIndex = _accounts.indexWhere((a) => a['id'] == data['accountId']);
    if (accountIndex != -1) {
      final account = _accounts[accountIndex];
      double newBalance = (account['balance'] as num).toDouble();
      if (data['type'] == 'income') {
        newBalance += (data['amount'] as num).toDouble();
      } else if (data['type'] == 'expense') {
        newBalance -= (data['amount'] as num).toDouble();
      }
      _accounts[accountIndex] = {...account, 'balance': newBalance};
    }
    
    return transaction;
  }

  Future<void> deleteTransaction(int id) async {
    await initialize();
    final tx = _transactions.firstWhere((t) => t['id'] == id, orElse: () => {});
    if (tx.isNotEmpty) {
      // Revertir balance
      final accountIndex = _accounts.indexWhere((a) => a['id'] == tx['accountId']);
      if (accountIndex != -1) {
        final account = _accounts[accountIndex];
        double newBalance = (account['balance'] as num).toDouble();
        if (tx['type'] == 'income') {
          newBalance -= (tx['amount'] as num).toDouble();
        } else if (tx['type'] == 'expense') {
          newBalance += (tx['amount'] as num).toDouble();
        }
        _accounts[accountIndex] = {...account, 'balance': newBalance};
      }
    }
    _transactions.removeWhere((t) => t['id'] == id);
  }

  // ========== SEED DATA ==========
  
  Future<void> _seedData() async {
    // Cuentas
    _accounts.addAll([
      {'id': _accountIdCounter++, 'name': 'Efectivo', 'type': 'cash', 'balance': 500.0, 'currency': 'PEN', 'isActive': 1, 'createdAt': DateTime.now().toIso8601String()},
      {'id': _accountIdCounter++, 'name': 'Banco BCP', 'type': 'bank', 'balance': 2500.0, 'currency': 'PEN', 'isActive': 1, 'createdAt': DateTime.now().toIso8601String()},
      {'id': _accountIdCounter++, 'name': 'Tarjeta Visa', 'type': 'credit_card', 'balance': -800.0, 'currency': 'PEN', 'isActive': 1, 'createdAt': DateTime.now().toIso8601String()},
      {'id': _accountIdCounter++, 'name': 'Ahorros', 'type': 'savings', 'balance': 5000.0, 'currency': 'PEN', 'isActive': 1, 'createdAt': DateTime.now().toIso8601String()},
    ]);

    // Categorías
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
    
    for (final cat in categories) {
      _categories.add({...cat, 'id': _categoryIdCounter++, 'isActive': 1});
    }

    // Transacciones de prueba
    final now = DateTime.now();
    final txs = [
      {'accountId': 2, 'categoryId': 9, 'type': 'income', 'amount': 3500.0, 'description': 'Salario Enero', 'date': now.subtract(const Duration(days: 15))},
      {'accountId': 2, 'categoryId': 10, 'type': 'income', 'amount': 800.0, 'description': 'Proyecto freelance web', 'date': now.subtract(const Duration(days: 10))},
      {'accountId': 1, 'categoryId': 12, 'type': 'income', 'amount': 150.0, 'description': 'Venta de artículos usados', 'date': now.subtract(const Duration(days: 5))},
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
    ];

    for (final tx in txs) {
      _transactions.add({
        'id': _transactionIdCounter++,
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
}
