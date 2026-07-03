import '../models/category.dart' as models;
import 'base_crud_provider.dart';

class CategoryProvider extends BaseCrudProvider<models.Category> {
  @override
  String get tableName => 'categories';

  @override
  String? get orderByClause => 'sort_order ASC';

  @override
  models.Category fromMap(Map<String, dynamic> map) => models.Category.fromMap(map);

  @override
  Map<String, dynamic> toMap(models.Category item) => item.toMap();

  // Backwards-compatible aliases (existing callers used these names)
  List<models.Category> get categories => items;

  Future<int> addCategory(models.Category category) => addItem(category);
  Future<void> updateCategory(models.Category category) => updateItem(category);
  Future<void> deleteCategory(int id) => deleteItemById(id);
}
