import 'package:equatable/equatable.dart';

/// Modelo de dominio para una transacción
class Transaction extends Equatable {
  final String? id; // UUID from Supabase
  final String accountId; // UUID de la cuenta
  final String categoryId; // UUID de la categoría
  final String type;
  final double amount;
  final String? description;
  final DateTime date;
  final DateTime createdAt;

  const Transaction({
    this.id,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    this.description,
    required this.date,
    required this.createdAt,
  });

  Transaction copyWith({
    String? id,
    String? accountId,
    String? categoryId,
    String? type,
    double? amount,
    String? description,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// To JSON for local database (sqflite)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'accountId': accountId,
      'categoryId': categoryId,
      'type': type,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// From JSON (local sqflite format)
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id']?.toString(),
      accountId: json['accountId']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// From Supabase JSON (uses snake_case)
  factory Transaction.fromSupabase(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      accountId: json['account_id'] as String,
      categoryId: json['category_id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, accountId, categoryId, type, amount, description, date, createdAt];
}

