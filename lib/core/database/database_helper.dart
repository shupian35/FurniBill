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
      version: 8,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        spec TEXT,
        unit TEXT,
        price REAL NOT NULL,
        stock INTEGER DEFAULT 0,
        cost_price REAL DEFAULT 0,
        min_stock INTEGER DEFAULT 0,
        category_id INTEGER,
        image_url TEXT,
        barcode TEXT,
        warehouse_id INTEGER DEFAULT 1,
        create_time TEXT NOT NULL,
        update_time TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT,
        tier TEXT DEFAULT '普通',
        credit_limit REAL DEFAULT 0,
        due_days INTEGER DEFAULT 0,
        total_owing REAL DEFAULT 0,
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

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        parent_id INTEGER,
        sort_order INTEGER DEFAULT 0,
        create_time TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE warehouses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        is_default INTEGER DEFAULT 0,
        create_time TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE purchase_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_no TEXT NOT NULL UNIQUE,
        supplier_name TEXT,
        supplier_phone TEXT,
        warehouse_id INTEGER DEFAULT 1,
        items TEXT,
        total_amount REAL DEFAULT 0,
        paid_amount REAL DEFAULT 0,
        owing_amount REAL DEFAULT 0,
        status TEXT DEFAULT 'draft',
        remark TEXT,
        create_time TEXT NOT NULL,
        complete_time TEXT,
        FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE return_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_no TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        original_order_id INTEGER,
        customer_id INTEGER,
        supplier_name TEXT,
        items TEXT,
        total_amount REAL DEFAULT 0,
        status TEXT DEFAULT 'pending',
        reason TEXT,
        remark TEXT,
        create_time TEXT NOT NULL,
        complete_time TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory_checks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        check_no TEXT NOT NULL UNIQUE,
        warehouse_id INTEGER DEFAULT 1,
        status TEXT DEFAULT 'draft',
        remark TEXT,
        create_time TEXT NOT NULL,
        complete_time TEXT,
        FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory_check_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        check_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        system_stock INTEGER NOT NULL,
        actual_stock INTEGER,
        difference INTEGER,
        remark TEXT,
        FOREIGN KEY (check_id) REFERENCES inventory_checks(id),
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE customer_prices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        price REAL NOT NULL,
        create_time TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(id),
        FOREIGN KEY (product_id) REFERENCES products(id),
        UNIQUE(customer_id, product_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        member_no TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        phone TEXT,
        points INTEGER DEFAULT 0,
        level TEXT DEFAULT '普通会员',
        create_time TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await db.execute("ALTER TABLE products ADD COLUMN cost_price REAL DEFAULT 0");
      await db.execute("ALTER TABLE products ADD COLUMN min_stock INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE products ADD COLUMN category_id INTEGER");
      await db.execute("ALTER TABLE products ADD COLUMN image_url TEXT");
      await db.execute("ALTER TABLE products ADD COLUMN barcode TEXT");
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE warehouses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          address TEXT,
          phone TEXT,
          is_default INTEGER DEFAULT 0,
          create_time TEXT NOT NULL
        )
      ''');
      await db.execute("ALTER TABLE products ADD COLUMN warehouse_id INTEGER DEFAULT 1");
      await db.execute("ALTER TABLE customers ADD COLUMN tier TEXT DEFAULT '普通'");
      await db.execute("ALTER TABLE customers ADD COLUMN credit_limit REAL DEFAULT 0");
      await db.execute("ALTER TABLE customers ADD COLUMN due_days INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE customers ADD COLUMN total_owing REAL DEFAULT 0");
      await db.insert('warehouses', {
        'name': '默认仓库',
        'is_default': 1,
        'create_time': DateTime.now().toIso8601String(),
      });
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE purchase_orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_no TEXT NOT NULL UNIQUE,
          supplier_name TEXT,
          supplier_phone TEXT,
          warehouse_id INTEGER DEFAULT 1,
          items TEXT,
          total_amount REAL DEFAULT 0,
          paid_amount REAL DEFAULT 0,
          owing_amount REAL DEFAULT 0,
          status TEXT DEFAULT 'draft',
          remark TEXT,
          create_time TEXT NOT NULL,
          complete_time TEXT,
          FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
        )
      ''');
      await db.execute('''
        CREATE TABLE return_orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_no TEXT NOT NULL UNIQUE,
          type TEXT NOT NULL,
          original_order_id INTEGER,
          customer_id INTEGER,
          supplier_name TEXT,
          items TEXT,
          total_amount REAL DEFAULT 0,
          status TEXT DEFAULT 'pending',
          reason TEXT,
          remark TEXT,
          create_time TEXT NOT NULL,
          complete_time TEXT
        )
      ''');
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          parent_id INTEGER,
          sort_order INTEGER DEFAULT 0,
          create_time TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE inventory_checks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          check_no TEXT NOT NULL UNIQUE,
          warehouse_id INTEGER DEFAULT 1,
          status TEXT DEFAULT 'draft',
          remark TEXT,
          create_time TEXT NOT NULL,
          complete_time TEXT,
          FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
        )
      ''');
      await db.execute('''
        CREATE TABLE inventory_check_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          check_id INTEGER NOT NULL,
          product_id INTEGER NOT NULL,
          system_stock INTEGER NOT NULL,
          actual_stock INTEGER,
          difference INTEGER,
          remark TEXT,
          FOREIGN KEY (check_id) REFERENCES inventory_checks(id),
          FOREIGN KEY (product_id) REFERENCES products(id)
        )
      ''');
      await db.execute('''
        CREATE TABLE customer_prices (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_id INTEGER NOT NULL,
          product_id INTEGER NOT NULL,
          price REAL NOT NULL,
          create_time TEXT NOT NULL,
          FOREIGN KEY (customer_id) REFERENCES customers(id),
          FOREIGN KEY (product_id) REFERENCES products(id),
          UNIQUE(customer_id, product_id)
        )
      ''');
      await db.execute('''
        CREATE TABLE members (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_id INTEGER,
          member_no TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          phone TEXT,
          points INTEGER DEFAULT 0,
          level TEXT DEFAULT '普通会员',
          create_time TEXT NOT NULL,
          FOREIGN KEY (customer_id) REFERENCES customers(id)
        )
      ''');
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

  Future<int> rawUpdate(String sql, [List<dynamic>? args]) async {
    final db = await database;
    return db.rawUpdate(sql, args);
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
