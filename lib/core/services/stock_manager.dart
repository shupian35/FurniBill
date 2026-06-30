import '../database/database_helper.dart';
import '../models/order.dart';

class StockManager {
  final DatabaseHelper db;

  StockManager({DatabaseHelper? db}) : db = db ?? DatabaseHelper.instance;

  Future<void> adjustStock(
    int productId,
    int change, {
    String? orderNo,
    required String reason,
  }) async {
    await db.transaction((txn) async {
      final rows = await txn.query(
        'products',
        columns: ['stock'],
        where: 'id = ?',
        whereArgs: [productId],
      );
      if (rows.isEmpty) {
        throw StateError('商品不存在: productId=$productId');
      }
      final currentStock = rows.first['stock'] as int;
      final newStock = currentStock + change;

      await txn.update(
        'products',
        {'stock': newStock},
        where: 'id = ?',
        whereArgs: [productId],
      );
      await txn.insert('inventory_logs', {
        'product_id': productId,
        'change_amount': change,
        'after_stock': newStock,
        'reason': reason,
        'order_no': orderNo,
        'create_time': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> adjustStockBatch(
    Map<int, int> changes, {
    String? orderNo,
    required String reason,
  }) async {
    await db.transaction((txn) async {
      for (final entry in changes.entries) {
        final productId = entry.key;
        final change = entry.value;

        final rows = await txn.query(
          'products',
          columns: ['stock'],
          where: 'id = ?',
          whereArgs: [productId],
        );
        if (rows.isEmpty) {
          throw StateError('商品不存在: productId=$productId');
        }
        final currentStock = rows.first['stock'] as int;
        final newStock = currentStock + change;

        await txn.update(
          'products',
          {'stock': newStock},
          where: 'id = ?',
          whereArgs: [productId],
        );
        await txn.insert('inventory_logs', {
          'product_id': productId,
          'change_amount': change,
          'after_stock': newStock,
          'reason': reason,
          'order_no': orderNo,
          'create_time': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  Future<void> restoreOrderStock(
    List<OrderItem> items, {
    String? orderNo,
    required String reason,
  }) async {
    final Map<int, int> aggregated = {};
    for (final item in items) {
      if (item.productId == null) continue;
      aggregated[item.productId!] =
          (aggregated[item.productId!] ?? 0) + item.quantity.toInt();
    }
    if (aggregated.isEmpty) return;
    await adjustStockBatch(aggregated, orderNo: orderNo, reason: reason);
  }

  Future<bool> checkStock(int productId, int requiredQty) async {
    final rows = await db.query(
      'products',
      columns: ['stock'],
      where: 'id = ?',
      whereArgs: [productId],
    );
    if (rows.isEmpty) return false;
    final stock = rows.first['stock'] as int;
    return stock >= requiredQty;
  }
}
