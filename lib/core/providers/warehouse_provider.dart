import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/warehouse.dart';

class WarehouseProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<Warehouse> _warehouses = [];
  bool _loading = false;

  List<Warehouse> get warehouses => _warehouses;
  bool get loading => _loading;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    await _loadWarehouses();
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadWarehouses() async {
    final rows = await _db.query('warehouses', orderBy: 'is_default DESC');
    _warehouses = rows.map((r) => Warehouse.fromMap(r)).toList();
  }

  Warehouse? get defaultWarehouse {
    return _warehouses.firstWhere(
      (w) => w.isDefault,
      orElse: () => _warehouses.isNotEmpty ? _warehouses.first : Warehouse(name: '默认仓库'),
    );
  }

  Future<int> addWarehouse(Warehouse warehouse) async {
    final id = await _db.insert('warehouses', warehouse.toMap());
    await _loadWarehouses();
    notifyListeners();
    return id;
  }

  Future<void> updateWarehouse(Warehouse warehouse) async {
    await _db.update(
      'warehouses',
      warehouse.toMap(),
      where: 'id = ?',
      whereArgs: [warehouse.id],
    );
    await _loadWarehouses();
    notifyListeners();
  }

  Future<void> deleteWarehouse(int id) async {
    await _db.delete('warehouses', where: 'id = ?', whereArgs: [id]);
    await _loadWarehouses();
    notifyListeners();
  }
}
