import '../../domain/models/category.dart';
import '../../services/supabase_service.dart';
import '../../services/logger_service.dart';

class CategoryRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  // Categorías por defecto (fallback cuando no hay conexión a Supabase)
  static final List<Category> _defaultCategories = [
    // Categorías de GASTOS
    Category(id: 'cat-1', name: 'Alimentos', type: 'expense', icon: 'restaurant', color: '#FF6B6B'),
    Category(id: 'cat-2', name: 'Transporte', type: 'expense', icon: 'directions_car', color: '#4ECDC4'),
    Category(id: 'cat-3', name: 'Vivienda', type: 'expense', icon: 'home', color: '#45B7D1'),
    Category(id: 'cat-4', name: 'Servicios', type: 'expense', icon: 'receipt_long', color: '#FFA07A'),
    Category(id: 'cat-5', name: 'Salud', type: 'expense', icon: 'local_hospital', color: '#98D8C8'),
    Category(id: 'cat-6', name: 'Entretenimiento', type: 'expense', icon: 'movie', color: '#F7DC6F'),
    Category(id: 'cat-7', name: 'Educación', type: 'expense', icon: 'school', color: '#BB8FCE'),
    Category(id: 'cat-8', name: 'Compras', type: 'expense', icon: 'shopping_bag', color: '#F8B500'),
    Category(id: 'cat-9', name: 'Ropa', type: 'expense', icon: 'checkroom', color: '#EC7063'),
    Category(id: 'cat-10', name: 'Otros Gastos', type: 'expense', icon: 'more_horiz', color: '#95A5A6'),
    // Categorías de INGRESOS
    Category(id: 'cat-11', name: 'Salario', type: 'income', icon: 'payments', color: '#27AE60'),
    Category(id: 'cat-12', name: 'Freelance', type: 'income', icon: 'work', color: '#3498DB'),
    Category(id: 'cat-13', name: 'Inversiones', type: 'income', icon: 'trending_up', color: '#9B59B6'),
    Category(id: 'cat-14', name: 'Regalos', type: 'income', icon: 'card_giftcard', color: '#E74C3C'),
    Category(id: 'cat-15', name: 'Otros Ingresos', type: 'income', icon: 'attach_money', color: '#1ABC9C'),
  ];

  // Obtener todas las categorías por defecto
  Future<List<Category>> getAll() async {
    try {
      if (_supabase.isAuthenticated) {
        final response = await _supabase.client
            .from('categories')
            .select()
            .eq('is_default', true)
            .order('name');
        
        return (response as List)
            .map((json) => Category.fromJson(json))
            .toList();
      }
    } catch (e) {
      AppLogger.warning('Error al obtener categorías de Supabase, usando locales: $e');
    }
    
    // Fallback a categorías locales
    return _defaultCategories;
  }

  // Obtener categoría por ID
  Future<Category?> getById(String id) async {
    try {
      if (_supabase.isAuthenticated) {
        final response = await _supabase.client
            .from('categories')
            .select()
            .eq('id', id)
            .single();
        
        return Category.fromJson(response);
      }
    } catch (e) {
      AppLogger.warning('Error al obtener categoría: $e');
    }
    
    // Buscar en categorías locales
    return _defaultCategories.where((c) => c.id == id).firstOrNull;
  }

  // Obtener categorías por tipo (income/expense)
  Future<List<Category>> getByType(String type) async {
    try {
      if (_supabase.isAuthenticated) {
        final response = await _supabase.client
            .from('categories')
            .select()
            .eq('type', type)
            .eq('is_default', true)
            .order('name');
        
        return (response as List)
            .map((json) => Category.fromJson(json))
            .toList();
      }
    } catch (e) {
      AppLogger.warning('Error al obtener categorías por tipo: $e');
    }
    
    // Fallback a categorías locales filtradas por tipo
    return _defaultCategories.where((c) => c.type == type).toList();
  }

  // Crear nueva categoría (custom)
  Future<Category> create(Category category) async {
    try {
      if (_supabase.isAuthenticated) {
        final data = {
          'name': category.name,
          'type': category.type,
          'icon': category.icon,
          'color': category.color,
          'is_default': false, // Las categorías creadas por usuario no son default
        };
        
        final response = await _supabase.client
            .from('categories')
            .insert(data)
            .select()
            .single();
        
        return Category.fromJson(response);
      }
    } catch (e) {
      throw Exception('Error al crear categoría: $e');
    }
    
    throw Exception('No autenticado');
  }

  // Actualizar categoría
  Future<Category> update(Category category) async {
    try {
      if (_supabase.isAuthenticated) {
        final data = {
          'name': category.name,
          'type': category.type,
          'icon': category.icon,
          'color': category.color,
        };
        
        final response = await _supabase.client
            .from('categories')
            .update(data)
            .eq('id', category.id)
            .select()
            .single();
        
        return Category.fromJson(response);
      }
    } catch (e) {
      throw Exception('Error al actualizar categoría: $e');
    }
    
    throw Exception('No autenticado');
  }

  // Eliminar categoría
  Future<void> delete(String id) async {
    try {
      if (_supabase.isAuthenticated) {
        await _supabase.client
            .from('categories')
            .delete()
            .eq('id', id);
      }
    } catch (e) {
      throw Exception('Error al eliminar categoría: $e');
    }
  }

  // Stream de categorías
  Stream<List<Category>> watchAll() {
    if (!_supabase.isAuthenticated) {
      return Stream.value(_defaultCategories);
    }
    
    return _supabase.client
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
    if (!_supabase.isAuthenticated) {
      return Stream.value(_defaultCategories.where((c) => c.type == type).toList());
    }
    
    return _supabase.client
        .from('categories')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((data) => data
            .where((json) => json['type'] == type && json['is_default'] == true)
            .map((json) => Category.fromJson(json))
            .toList());
  }
}
