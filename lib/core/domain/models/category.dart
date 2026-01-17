import 'package:equatable/equatable.dart';

/// Modelo de dominio para una categoría
class Category extends Equatable {
  final String id;  // UUID from Supabase
  final String name;
  final String type;
  final String? icon;
  final String? color;
  final bool isDefault;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.isDefault = false,
  });

  Category copyWith({
    String? id,
    String? name,
    String? type,
    String? icon,
    String? color,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'is_default': isDefault,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, name, type, icon, color, isDefault];
}
