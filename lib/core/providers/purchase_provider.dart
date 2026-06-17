import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/purchase_order.dart';

class PurchaseProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<PurchaseOrder> _orders = [];
  bool _loading = false;

  List<PurchaseOrder> get orders => _orders;
  bool get loading => _loading;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    await _loadOrders();
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadOrders() async {
    final rows = await _db.query('purchase_orders', orderBy: 'create_time DESC');
    _orders = rows.map((r) => PurchaseOrder.fromMap(r)).toList();
  }

  String generateOrderNo() {
    final now = DateTime.now();
    final date = DateFormat('yyyyMMdd').format(now);
    final time = DateFormat('HHmmss').format(now);
    return 'PO$date$time';
  }

  Future<int> saveOrder(PurchaseOrder order) async {
    final id = await _db.insert('purchase_orders', order.toMap());
    await refresh();
    return id;
  }

  Future<void> updateOrder(PurchaseOrder order) async {
    await _db.update(
      'purchase_orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
    await refresh();
  }

  Future<void> deleteOrder(int id) async {
    await _db.delete('purchase_orders', where: 'id = ?', whereArgs: [id]);
    await refresh();
  }

  Future<void> completeOrder(PurchaseOrder order, Map<int, int> stockChanges) async {
    await _db.update(
      'purchase_orders',
      {'status': 'completed', 'complete_time': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [order.id],
    );
    for (final entry in stockChanges.entries) {
      await _db.rawUpdate(
        'UPDATE products SET stock = stock + ? WHERE id = ?',
        [entry.value, entry.key],
      );
    }
    await refresh();
  }

  Future<void> refresh() async {
    await _loadOrders();
    notifyListeners();
  }
}
