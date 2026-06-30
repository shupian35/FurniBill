import '../models/product.dart';
import '../services/stock_manager.dart';
import 'crud_provider.dart';

class ProductProvider extends CrudProvider<Product> {
  final _stockManager = StockManager();
  String _searchQuery = '';

  @override
  String get tableName => 'products';

  @override
  String get defaultOrderBy => 'update_time DESC';

  @override
  Product fromMap(Map<String, dynamic> map) => Product.fromMap(map);

  @override
  Map<String, dynamic> toMap(Product item) => item.toMap();

  @override
  int? getItemId(Product item) => item.id;

  List<Product> get products => items;

  List<Product> get filteredProducts {
    if (_searchQuery.isEmpty) return items;
    final q = _searchQuery.toLowerCase();
    return items.where((p) {
      return p.name.toLowerCase().contains(q) ||
          (p.spec?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<int> addProduct(Product product) => add(product);

  Future<void> updateProduct(Product product) => update(product);

  Future<void> deleteProduct(int id) => delete(id);

  Future<void> updateStock(
    int productId,
    int change, {
    String? orderNo,
    String? reason,
  }) async {
    await _stockManager.adjustStock(
      productId,
      change,
      orderNo: orderNo,
      reason: reason ?? (change > 0 ? '补货' : '销售出库'),
    );
    await refresh();
  }
}
