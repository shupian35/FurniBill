import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';

class CustomerProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<Customer> _customers = [];
  bool _loading = false;
  String _searchQuery = '';

  List<Customer> get customers => _customers;
  bool get loading => _loading;

  List<Customer> get filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    final q = _searchQuery.toLowerCase();
    return _customers.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.phone.contains(q) ||
          (c.address?.toLowerCase().contains(q) ?? false);
    }).toList();
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

  Customer? getById(int id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
