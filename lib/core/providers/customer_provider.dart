import '../models/customer.dart';
import 'crud_provider.dart';

class CustomerProvider extends CrudProvider<Customer> {
  String _searchQuery = '';

  @override
  String get tableName => 'customers';

  @override
  Customer fromMap(Map<String, dynamic> map) => Customer.fromMap(map);

  @override
  Map<String, dynamic> toMap(Customer item) => item.toMap();

  @override
  int? getItemId(Customer item) => item.id;

  List<Customer> get customers => items;

  List<Customer> get filteredCustomers {
    if (_searchQuery.isEmpty) return items;
    final q = _searchQuery.toLowerCase();
    return items.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.phone.contains(q) ||
          (c.address?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Customer? getById(int id) {
    try {
      return items.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<int> addCustomer(Customer customer) => add(customer);

  Future<void> updateCustomer(Customer customer) => update(customer);

  Future<void> deleteCustomer(int id) => delete(id);
}
