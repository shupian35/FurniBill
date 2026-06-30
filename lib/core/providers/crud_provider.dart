import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';

abstract class CrudProvider<T> extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<T> _items = [];
  bool _loading = false;

  String get tableName;
  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T item);
  int? getItemId(T item);
  String get defaultOrderBy => 'create_time DESC';

  List<T> get items => _items;
  bool get loading => _loading;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    try {
      await _loadItems();
    } catch (e) {
      debugPrint('$tableName init failed: $e');
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadItems() async {
    final rows = await _db.query(tableName, orderBy: defaultOrderBy);
    _items = rows.map((r) => fromMap(r)).toList();
  }

  Future<int> add(T item) async {
    final id = await _db.insert(tableName, toMap(item));
    _items.insert(0, item);
    notifyListeners();
    return id;
  }

  Future<void> update(T item) async {
    final id = getItemId(item);
    if (id == null) return;
    await _db.update(tableName, toMap(item), where: 'id = ?', whereArgs: [id]);
    final index = _items.indexWhere((i) => getItemId(i) == id);
    if (index != -1) _items[index] = item;
    notifyListeners();
  }

  Future<void> delete(int id) async {
    await _db.delete(tableName, where: 'id = ?', whereArgs: [id]);
    _items.removeWhere((i) => getItemId(i) == id);
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      await _loadItems();
      notifyListeners();
    } catch (e) {
      debugPrint('$tableName refresh failed: $e');
    }
  }
}
