import 'package:equatable/equatable.dart';

/// Modelo de dominio para una cuenta
class Account extends Equatable {
  final String? id; // UUID from Supabase (nullable for new accounts)
  final String name;
  final String type;
  final double balance;
  final String currency;
  final bool isActive;
  final DateTime createdAt;

  const Account({
    this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    required this.isActive,
    required this.createdAt,
  });

  Account copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    String? currency,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// To JSON for local database (sqflite)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// From JSON (local sqflite format)
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id']?.toString(),
      name: json['name'] as String,
      type: json['type'] as String,
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String,
      isActive: (json['isActive'] as int) == 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// From Supabase JSON (uses snake_case)
  factory Account.fromSupabase(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, name, type, balance, currency, isActive, createdAt];
}
