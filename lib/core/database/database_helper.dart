import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('furni_bill.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0,
        create_time TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL UNIQUE,
        spec TEXT,
        unit TEXT DEFAULT '件',
        category_id INTEGER DEFAULT 0,
        image_path TEXT,
        wholesale_price REAL NOT NULL,
        retail_price REAL,
        cost_price REAL,
        stock INTEGER DEFAULT 0,
        stock_alert INTEGER DEFAULT 0,
        sku_enabled INTEGER DEFAULT 0,
        attributes_schema TEXT,
        remark TEXT,
        create_time TEXT NOT NULL,
        update_time TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE skus (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        attrs TEXT NOT NULL,
        attrs_summary TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER DEFAULT 0,
        barcode TEXT,
        create_time TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT,
        create_time TEXT NOT NULL,
        update_time TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_no TEXT NOT NULL UNIQUE,
        customer_id INTEGER NOT NULL,
        customer_name TEXT,
        items TEXT,
        total_amount REAL DEFAULT 0,
        order_discount REAL DEFAULT 1.0,
        discount_amount REAL DEFAULT 0,
        round_off REAL DEFAULT 0,
        receivable REAL DEFAULT 0,
        received REAL DEFAULT 0,
        owing REAL DEFAULT 0,
        status TEXT DEFAULT 'draft',
        clerk TEXT,
        remark TEXT,
        payment_method TEXT,
        is_draft INTEGER DEFAULT 1,
        create_time TEXT NOT NULL,
        complete_time TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        customer_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        method TEXT NOT NULL,
        remark TEXT,
        create_time TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id),
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER,
        sku_id INTEGER,
        change_amount INTEGER NOT NULL,
        after_stock INTEGER NOT NULL,
        reason TEXT NOT NULL,
        order_no TEXT,
        create_time TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE backup_metas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_name TEXT NOT NULL,
        device_id TEXT NOT NULL,
        device_name TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        create_time TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        role TEXT DEFAULT '操作员',
        is_active INTEGER DEFAULT 1,
        create_time TEXT NOT NULL
      )
    ''');

    // 插入默认分类
    final defaultCategories = [
      '沙发', '床', '餐桌', '柜类', '办公家具', '茶几', '电视柜', '鞋柜', '其他'
    ];
    for (var i = 0; i < defaultCategories.length; i++) {
      await db.insert('categories', {
        'name': defaultCategories[i],
        'sort_order': i,
        'create_time': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE products ADD COLUMN spec TEXT");
      await db.execute("ALTER TABLE products ADD COLUMN unit TEXT DEFAULT '件'");
    }
    if (oldVersion < 3) {
      // Recreate customers table with simplified schema
      await db.execute('''
        CREATE TABLE customers_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT NOT NULL,
          address TEXT,
          create_time TEXT NOT NULL,
          update_time TEXT NOT NULL
        )
      ''');
      await db.execute(
        'INSERT INTO customers_new (id, name, phone, address, create_time, update_time) '
        'SELECT id, name, phone, address, create_time, update_time FROM customers'
      );
      await db.execute('DROP TABLE customers');
      await db.execute('ALTER TABLE customers_new RENAME TO customers');
    }
  }

  // ========== JSON 序列化工具 ==========

  static String encodeJson(dynamic value) {
    return jsonEncode(value);
  }

  static dynamic decodeJson(String raw) {
    if (raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  // ========== 通用查询 ==========

  Future<List<Map<String, dynamic>>> query(String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return db.insert(table, values);
  }

  Future<int> update(String table, Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? args]) async {
    final db = await database;
    return db.rawQuery(sql, args);
  }

  Future<void> rawInsert(String sql, [List<dynamic>? args]) async {
    final db = await database;
    await db.rawInsert(sql, args);
  }

  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'furni_bill.db');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
