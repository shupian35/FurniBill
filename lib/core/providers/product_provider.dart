import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<Product> _products = [];
  bool _loading = false;
  String _searchQuery = '';

  List<Product> get products => _products;
  bool get loading => _loading;

  List<Product> get filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    final q = _searchQuery.toLowerCase();
    return _products.where((p) {
      return p.name.toLowerCase().contains(q) ||
          (p.spec?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    await _loadProducts();
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadProducts() async {
    final rows = await _db.query('products', orderBy: 'update_time DESC');
    _products = rows.map((r) => Product.fromMap(r)).toList();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<int> addProduct(Product product) async {
    final id = await _db.insert('products', product.toMap());
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
    await _loadProducts();
    notifyListeners();
  }

  Future<void> updateStock(int productId, int change, {String? orderNo}) async {
    final product = _products.firstWhere((p) => p.id == productId);
    final newStock = product.stock + change;
    await _db.update('products', {'stock': newStock},
        where: 'id = ?', whereArgs: [productId]);
    await _db.insert('inventory_logs', {
      'product_id': productId,
      'change_amount': change,
      'after_stock': newStock,
      'reason': change > 0 ? '补货' : '销售出库',
      'order_no': orderNo,
      'create_time': DateTime.now().toIso8601String(),
    });
    await _loadProducts();
    notifyListeners();
  }
}
