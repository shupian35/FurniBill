import 'package:intl/intl.dart';
import '../models/return_order.dart';
import '../services/stock_manager.dart';
import '../database/database_helper.dart';
import 'crud_provider.dart';

class ReturnProvider extends CrudProvider<ReturnOrder> {
  final _stockManager = StockManager();
  final _db = DatabaseHelper.instance;

  @override
  String get tableName => 'return_orders';

  @override
  ReturnOrder fromMap(Map<String, dynamic> map) => ReturnOrder.fromMap(map);

  @override
  Map<String, dynamic> toMap(ReturnOrder item) => item.toMap();

  @override
  int? getItemId(ReturnOrder item) => item.id;

  List<ReturnOrder> get returns => items;

  Future<void> deleteReturn(int id) => delete(id);

  String generateOrderNo() {
    final now = DateTime.now();
    final date = DateFormat('yyyyMMdd').format(now);
    final time = DateFormat('HHmmss').format(now);
    return 'RO$date$time';
  }

  Future<void> completeReturn(
    ReturnOrder returnOrder,
    Map<int, int> stockChanges,
  ) async {
    await _db.update(
      'return_orders',
      {
        'status': 'completed',
        'complete_time': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [returnOrder.id],
    );
    final reason = returnOrder.type == 'sales_return' ? '销售退货入库' : '采购退货出库';
    await _stockManager.adjustStockBatch(
      stockChanges,
      orderNo: returnOrder.orderNo,
      reason: reason,
    );
    await refresh();
  }
}
