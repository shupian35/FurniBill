import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/return_order.dart';

class ReturnProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<ReturnOrder> _returns = [];
  bool _loading = false;

  List<ReturnOrder> get returns => _returns;
  bool get loading => _loading;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    await _loadReturns();
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadReturns() async {
    final rows = await _db.query('return_orders', orderBy: 'create_time DESC');
    _returns = rows.map((r) => ReturnOrder.fromMap(r)).toList();
  }

  String generateOrderNo() {
    final now = DateTime.now();
    final date = DateFormat('yyyyMMdd').format(now);
    final time = DateFormat('HHmmss').format(now);
    return 'RO$date$time';
  }

  Future<int> saveReturn(ReturnOrder returnOrder) async {
    final id = await _db.insert('return_orders', returnOrder.toMap());
    await refresh();
    return id;
  }

  Future<void> updateReturn(ReturnOrder returnOrder) async {
    await _db.update(
      'return_orders',
      returnOrder.toMap(),
      where: 'id = ?',
      whereArgs: [returnOrder.id],
    );
    await refresh();
  }

  Future<void> deleteReturn(int id) async {
    await _db.delete('return_orders', where: 'id = ?', whereArgs: [id]);
    await refresh();
  }

  Future<void> completeReturn(ReturnOrder returnOrder) async {
    await _db.update(
      'return_orders',
      {'status': 'completed', 'complete_time': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [returnOrder.id],
    );
    await refresh();
  }

  Future<void> refresh() async {
    await _loadReturns();
    notifyListeners();
  }
}
