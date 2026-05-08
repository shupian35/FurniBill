import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/sku.dart';

class ProductProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<Product> _products = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = false;
  String _searchQuery = '';
  int _categoryFilter = 0;

  List<Product> get products => _products;
  List<Map<String, dynamic>> get categories => _categories;
  bool get loading => _loading;
  int get categoryFilter => _categoryFilter;
  String get searchQuery => _searchQuery;

  List<Product> get filteredProducts {
    var result = _products;
    if (_categoryFilter > 0) {
      result = result.where((p) => p.categoryId == _categoryFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.code.toLowerCase().contains(q);
      }).toList();
    }
    return result;
  }

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    await Future.wait([_loadProducts(), _loadCategories()]);
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadProducts() async {
    final rows = await _db.query('products', orderBy: 'update_time DESC');
    _products = rows.map((r) => Product.fromMap(r)).toList();
  }

  Future<void> _loadCategories() async {
    _categories = await _db.query('categories', orderBy: 'sort_order ASC');
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(int categoryId) {
    _categoryFilter = categoryId;
    notifyListeners();
  }

  Future<int> addProduct(Product product) async {
    final code = product.code.isEmpty
        ? 'FB${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}'
        : product.code;
    final p = Product(
      name: product.name,
      code: code,
      categoryId: product.categoryId,
      imagePath: product.imagePath,
      wholesalePrice: product.wholesalePrice,
      retailPrice: product.retailPrice,
      costPrice: product.costPrice,
      stock: product.stock,
      stockAlert: product.stockAlert,
      skuEnabled: product.skuEnabled,
      attributesSchema: product.attributesSchema,
      remark: product.remark,
    );
    final id = await _db.insert('products', p.toMap());
    await _loadProducts();
    notifyListeners();
    return id;
  }

  Future<void> updateProduct(Product product) async {
    await _db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
    await _loadProducts();
    notifyListeners();
  }

  Future<void> deleteProduct(int id) async {
    await _db.delete('products', where: 'id = ?', whereArgs: [id]);
    await _db.delete('skus', where: 'product_id = ?', whereArgs: [id]);
    await _loadProducts();
    notifyListeners();
  }

  Future<List<Sku>> getSkus(int productId) async {
    final rows = await _db.query('skus',
        where: 'product_id = ?', whereArgs: [productId]);
    return rows.map((r) => Sku.fromMap(r)).toList();
  }

  Future<void> addSku(Sku sku) async {
    await _db.insert('skus', sku.toMap());
  }

  Future<void> updateSku(Sku sku) async {
    await _db.update('skus', sku.toMap(),
        where: 'id = ?', whereArgs: [sku.id]);
  }

  Future<void> deleteSku(int skuId) async {
    await _db.delete('skus', where: 'id = ?', whereArgs: [skuId]);
  }

  Future<void> updateStock(int productId, int? skuId, int change) async {
    if (skuId != null) {
      final skus = await getSkus(productId);
      final sku = skus.firstWhere((s) => s.id == skuId);
      await _db.update('skus', {'stock': sku.stock + change},
          where: 'id = ?', whereArgs: [skuId]);
    } else {
      final product = _products.firstWhere((p) => p.id == productId);
      await _db.update('products', {'stock': product.stock + change},
          where: 'id = ?', whereArgs: [productId]);
    }
    await _loadProducts();
    notifyListeners();
  }

  // 添加分类
  Future<int> addCategory(String name) async {
    final maxOrder = _categories.isEmpty
        ? 0
        : (_categories.map((c) => c['sort_order'] as int).reduce((a, b) => a > b ? a : b));
    final id = await _db.insert('categories', {
      'name': name,
      'sort_order': maxOrder + 1,
      'create_time': DateTime.now().toIso8601String(),
    });
    await _loadCategories();
    notifyListeners();
    return id;
  }

  Future<void> deleteCategory(int id) async {
    await _db.delete('categories', where: 'id = ?', whereArgs: [id]);
    await _loadCategories();
    notifyListeners();
  }
}
