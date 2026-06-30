import 'package:intl/intl.dart';
import '../models/purchase_order.dart';
import '../services/stock_manager.dart';
import '../database/database_helper.dart';
import 'crud_provider.dart';

class PurchaseProvider extends CrudProvider<PurchaseOrder> {
  final _stockManager = StockManager();
  final _db = DatabaseHelper.instance;

  @override
  String get tableName => 'purchase_orders';

  @override
  PurchaseOrder fromMap(Map<String, dynamic> map) => PurchaseOrder.fromMap(map);

  @override
  Map<String, dynamic> toMap(PurchaseOrder item) => item.toMap();

  @override
  int? getItemId(PurchaseOrder item) => item.id;

  List<PurchaseOrder> get orders => items;

  Future<void> deleteOrder(int id) => delete(id);

  String generateOrderNo() {
    final now = DateTime.now();
    final date = DateFormat('yyyyMMdd').format(now);
    final time = DateFormat('HHmmss').format(now);
    return 'PO$date$time';
  }

  Future<void> completeOrder(
    PurchaseOrder order,
    Map<int, int> stockChanges,
  ) async {
    await _db.update(
      'purchase_orders',
      {
        'status': 'completed',
        'complete_time': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [order.id],
    );
    await _stockManager.adjustStockBatch(
      stockChanges,
      orderNo: order.orderNo,
      reason: '采购入库',
    );
    await refresh();
  }
}
