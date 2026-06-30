import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../services/order_no_generator.dart';
import '../models/order.dart';
import '../models/payment.dart';

class OrderProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<Order> _orders = [];
  List<Order> _drafts = [];
  bool _loading = false;
  String _statusFilter = '';
  int? _customerFilter;

  List<Order> get orders => _orders;
  List<Order> get drafts => _drafts;
  bool get loading => _loading;
  String get statusFilter => _statusFilter;

  List<Order> get filteredOrders {
    var result = _orders.where((o) => !o.isDraft).toList();
    if (_statusFilter.isNotEmpty) {
      result = result.where((o) {
        if (_statusFilter == 'paid') return o.owing <= 0;
        if (_statusFilter == 'partial') return o.owing > 0 && o.received > 0;
        if (_statusFilter == 'unpaid') return o.received <= 0;
        return true;
      }).toList();
    }
    if (_customerFilter != null) {
      result = result.where((o) => o.customerId == _customerFilter).toList();
    }
    return result;
  }

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    await Future.wait([_loadOrders(), _loadDrafts()]);
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadOrders() async {
    final rows = await _db.query(
      'orders',
      where: 'is_draft = 0',
      orderBy: 'create_time DESC',
    );
    _orders = rows.map((r) => Order.fromMap(r)).toList();
  }

  Future<void> _loadDrafts() async {
    final rows = await _db.query(
      'orders',
      where: 'is_draft = 1',
      orderBy: 'create_time DESC',
    );
    _drafts = rows.map((r) => Order.fromMap(r)).toList();
  }

  void setStatusFilter(String status) {
    _statusFilter = _statusFilter == status ? '' : status;
    notifyListeners();
  }

  void setCustomerFilter(int? customerId) {
    _customerFilter = customerId;
    notifyListeners();
  }

  String generateOrderNo() {
    return OrderNoGenerator.generate('FB');
  }

  Future<int> saveOrder(Order order) async {
    final id = await _db.insert('orders', order.toMap());
    await refresh();
    return id;
  }

  Future<void> updateOrder(Order order) async {
    await _db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
    await refresh();
  }

  Future<void> deleteOrder(int id) async {
    await _db.delete('orders', where: 'id = ?', whereArgs: [id]);
    await refresh();
  }

  Future<void> cancelOrder(int id) async {
    await _db.update(
      'orders',
      {'status': 'cancelled', 'is_draft': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    await refresh();
  }

  Future<int> addPayment(Payment payment) async {
    final id = await _db.insert('payments', payment.toMap());
    await refresh();
    return id;
  }

  Future<List<Payment>> getPayments(int orderId) async {
    final rows = await _db.query(
      'payments',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
    return rows.map((r) => Payment.fromMap(r)).toList();
  }

  Future<List<Payment>> getCustomerPayments(int customerId) async {
    final rows = await _db.query(
      'payments',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'create_time DESC',
    );
    return rows.map((r) => Payment.fromMap(r)).toList();
  }

  // 统计
  Future<Map<String, double>> getTodayStats() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final rows = await _db.rawQuery(
      '''
      SELECT 
        COUNT(*) as order_count,
        COALESCE(SUM(receivable), 0) as total_sales,
        COALESCE(SUM(received), 0) as total_received,
        COALESCE(SUM(owing), 0) as total_owing
      FROM orders
      WHERE is_draft = 0 AND status != 'cancelled'
        AND date(create_time) = ?
    ''',
      [today],
    );
    if (rows.isEmpty) {
      return {
        'order_count': 0,
        'total_sales': 0,
        'total_received': 0,
        'total_owing': 0,
      };
    }
    final r = rows.first;
    return {
      'order_count': (r['order_count'] as int).toDouble(),
      'total_sales': (r['total_sales'] as num).toDouble(),
      'total_received': (r['total_received'] as num).toDouble(),
      'total_owing': (r['total_owing'] as num).toDouble(),
    };
  }

  Future<List<Map<String, dynamic>>> getSalesTrend(String period) async {
    String dateFormat;
    switch (period) {
      case 'week':
        dateFormat = '%Y-%m-%d';
        break;
      case 'month':
        dateFormat = '%Y-%m';
        break;
      default:
        dateFormat = '%Y-%m-%d';
    }
    return _db.rawQuery('''
      SELECT 
        strftime('$dateFormat', create_time) as period,
        COUNT(*) as count,
        SUM(receivable) as amount
      FROM orders
      WHERE is_draft = 0 AND status != 'cancelled'
      GROUP BY period
      ORDER BY period DESC
      LIMIT 30
    ''');
  }

  Future<void> refresh() async {
    await Future.wait([_loadOrders(), _loadDrafts()]);
    notifyListeners();
  }
}
