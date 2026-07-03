import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';

/// 通用 CRUD Provider 基类
///
/// 9 个 Provider 高度雷同：都做 init / add / update / delete + notifyListeners，
/// 唯一不同的就是表名和 Model 类。把这些样板抽出来。
///
/// 子类需要实现：
///   String get tableName         -- 数据库表名
///   T fromMap(`Map<String, dynamic>` map)  -- 行到 Model 的映射
///   String? get orderByClause    -- 可选排序子句
///   `Map<String, dynamic> toMap(T item)`  -- Model 到 map 的映射
abstract class BaseCrudProvider<T> extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<T> _items = [];
  bool _loading = false;

  List<T> get items => _items;
  bool get loading => _loading;

  String get tableName;
  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T item);
  String? get orderByClause => null;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    await _load();
    _loading = false;
    notifyListeners();
  }

  Future<void> _load() async {
    final rows = await _db.query(
      tableName,
      orderBy: orderByClause,
    );
    _items = rows.map(fromMap).toList();
  }

  Future<int> addItem(T item) async {
    final id = await _db.insert(tableName, toMap(item));
    await _load();
    notifyListeners();
    return id;
  }

  Future<void> updateItem(T item) async {
    final map = toMap(item);
    final id = map['id'];
    await _db.update(
      tableName,
      map,
      where: 'id = ?',
      whereArgs: [id],
    );
    await _load();
    notifyListeners();
  }

  Future<void> deleteItemById(int id) async {
    await _db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    await _load();
    notifyListeners();
  }

  Future<void> refresh() async {
    await _load();
    notifyListeners();
  }
}
