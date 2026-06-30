import '../database/database_helper.dart';
import '../models/inventory_check.dart';
import 'crud_provider.dart';

class InventoryCheckProvider extends CrudProvider<InventoryCheck> {
  final _db = DatabaseHelper.instance;

  @override
  String get tableName => 'inventory_checks';

  @override
  InventoryCheck fromMap(Map<String, dynamic> map) =>
      InventoryCheck.fromMap(map);

  @override
  Map<String, dynamic> toMap(InventoryCheck item) => item.toMap();

  @override
  int? getItemId(InventoryCheck item) => item.id;

  List<InventoryCheck> get checks => items;

  Future<int> saveCheck(
    InventoryCheck check,
    List<InventoryCheckItem> checkItems,
  ) async {
    final db = await _db.database;
    final checkId = await db.transaction((txn) async {
      final id = await txn.insert('inventory_checks', check.toMap());
      for (final item in checkItems) {
        await txn.insert('inventory_check_items', {
          'check_id': id,
          'product_id': item.productId,
          'system_stock': item.systemStock,
          'actual_stock': item.actualStock,
          'difference': item.difference,
          'remark': item.remark,
        });
      }
      return id;
    });
    await refresh();
    return checkId;
  }

  Future<List<InventoryCheckItem>> getCheckItems(int checkId) async {
    final rows = await _db.query(
      'inventory_check_items',
      where: 'check_id = ?',
      whereArgs: [checkId],
    );
    return rows.map((r) => InventoryCheckItem.fromMap(r)).toList();
  }

  Future<void> deleteCheck(int id) async {
    await _db.delete(
      'inventory_check_items',
      where: 'check_id = ?',
      whereArgs: [id],
    );
    await _db.delete('inventory_checks', where: 'id = ?', whereArgs: [id]);
    await refresh();
  }
}
