import '../../domain/models/category.dart';
import '../../../core/config/supabase_config.dart';

class CategoryRepository {
  // Obtener todas las categorías por defecto
  Future<List<Category>> getAll() async {
    try {
      final response = await SupabaseConfig.client
          .from('categories')
          .select()
          .eq('is_default', true)
          .order('name');
      
      return (response as List)
          .map((json) => Category.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener categorías: $e');
    }
  }

  // Obtener categoría por ID
  Future<Category?> getById(String id) async {
    try {
      final response = await SupabaseConfig.client
          .from('categories')
          .select()
          .eq('id', id)
          .single();
      
      return Category.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Obtener categorías por tipo (income/expense)
  Future<List<Category>> getByType(String type) async {
    try {
      final response = await SupabaseConfig.client
          .from('categories')
          .select()
          .eq('type', type)
          .eq('is_default', true)
          .order('name');
      
      return (response as List)
          .map((json) => Category.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener categorías por tipo: $e');
    }
  }

  // Crear nueva categoría (custom)
  Future<Category> create(Category category) async {
    try {
      final data = {
        'name': category.name,
        'type': category.type,
        'icon': category.icon,
        'color': category.color,
        'is_default': false, // Las categorías creadas por usuario no son default
      };
      
      final response = await SupabaseConfig.client
          .from('categories')
          .insert(data)
          .select()
          .single();
      
      return Category.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear categoría: $e');
    }
  }

  // Actualizar categoría
  Future<Category> update(Category category) async {
    try {
      final data = {
        'name': category.name,
        'type': category.type,
        'icon': category.icon,
        'color': category.color,
      };
      
      final response = await SupabaseConfig.client
          .from('categories')
          .update(data)
          .eq('id', category.id)
          .select()
          .single();
      
      return Category.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar categoría: $e');
    }
  }

  // Eliminar categoría
  Future<void> delete(String id) async {
    try {
      await SupabaseConfig.client
          .from('categories')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar categoría: $e');
    }
  }

  // Stream de categorías
  Stream<List<Category>> watchAll() {
    return SupabaseConfig.client
        .from('categories')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((data) => data
            .where((json) => json['is_default'] == true)
            .map((json) => Category.fromJson(json))
            .toList());
  }
  
  // Stream de categorías por tipo
  Stream<List<Category>> watchByType(String type) {
    return SupabaseConfig.client
        .from('categories')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((data) => data
            .where((json) => json['type'] == type && json['is_default'] == true)
            .map((json) => Category.fromJson(json))
            .toList());
  }
}
