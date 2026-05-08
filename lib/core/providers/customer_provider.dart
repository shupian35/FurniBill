import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';

class CustomerProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<Customer> _customers = [];
  bool _loading = false;
  String _searchQuery = '';
  String _regionFilter = '';

  List<Customer> get customers => _customers;
  bool get loading => _loading;
  String get regionFilter => _regionFilter;

  List<Customer> get filteredCustomers {
    var result = _customers;
    if (_regionFilter.isNotEmpty) {
      result = result.where((c) => c.region == _regionFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.phone.contains(q) ||
            (c.region?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return result;
  }

  List<String> get regions {
    final set = _customers
        .map((c) => c.region)
        .where((r) => r != null && r.isNotEmpty)
        .toSet();
    return set.cast<String>().toList()..sort();
  }

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    await _loadCustomers();
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadCustomers() async {
    final rows = await _db.query('customers', orderBy: 'update_time DESC');
    _customers = rows.map((r) => Customer.fromMap(r)).toList();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setRegionFilter(String region) {
    _regionFilter = region == _regionFilter ? '' : region;
    notifyListeners();
  }

  Future<int> addCustomer(Customer customer) async {
    final id = await _db.insert('customers', customer.toMap());
    await _loadCustomers();
    notifyListeners();
    return id;
  }

  Future<void> updateCustomer(Customer customer) async {
    await _db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
    await _loadCustomers();
    notifyListeners();
  }

  Future<void> deleteCustomer(int id) async {
    await _db.delete('customers', where: 'id = ?', whereArgs: [id]);
    await _loadCustomers();
    notifyListeners();
  }

  Future<void> updateOwing(int customerId, double amount) async {
    final customer = _customers.firstWhere((c) => c.id == customerId);
    final newOwing = customer.owing + amount;
    await _db.update(
      'customers',
      {'owing': newOwing},
      where: 'id = ?',
      whereArgs: [customerId],
    );
    await _loadCustomers();
    notifyListeners();
  }

  Customer? getById(int id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
