import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/category.dart' as models;

class CategoryProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<models.Category> _categories = [];
  bool _loading = false;

  List<models.Category> get categories => _categories;
  bool get loading => _loading;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    await _loadCategories();
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadCategories() async {
    final rows = await _db.query('categories', orderBy: 'sort_order ASC');
    _categories = rows.map((r) => models.Category.fromMap(r)).toList();
  }

  Future<int> addCategory(models.Category category) async {
    final id = await _db.insert('categories', category.toMap());
    await _loadCategories();
    notifyListeners();
    return id;
  }

  Future<void> updateCategory(models.Category category) async {
    await _db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    await _loadCategories();
    notifyListeners();
  }

  Future<void> deleteCategory(int id) async {
    await _db.delete('categories', where: 'id = ?', whereArgs: [id]);
    await _loadCategories();
    notifyListeners();
  }
}
