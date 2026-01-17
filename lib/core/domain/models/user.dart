import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int? id;
  final String email;
  final String password;
  final String name;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const User({
    this.id,
    required this.email,
    required this.password,
    required this.name,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      email: map['email'] as String,
      password: map['password'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.parse(map['lastLoginAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'email': email,
      'password': password,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? password,
    String? name,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  // Usuario sin la contraseña para mostrar en UI
  User get withoutPassword {
    return User(
      id: id,
      email: email,
      password: '',
      name: name,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }

  @override
  List<Object?> get props => [id, email, name, createdAt, lastLoginAt];
}
