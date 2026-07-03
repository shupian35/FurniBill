import 'package:sqflite_common/sqlite_api.dart';

class Migrations {
  const Migrations._();

  static Future<void> v4ToV5(Database db) async {
    await db.execute('ALTER TABLE products ADD COLUMN cost_price REAL DEFAULT 0');
    await db.execute('ALTER TABLE products ADD COLUMN min_stock INTEGER DEFAULT 0');
    await db.execute('ALTER TABLE products ADD COLUMN category_id INTEGER');
    await db.execute('ALTER TABLE products ADD COLUMN image_url TEXT');
    await db.execute('ALTER TABLE products ADD COLUMN barcode TEXT');
  }

  static Future<void> v5ToV6(Database db) async {
    await db.execute('CREATE TABLE warehouses (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, address TEXT, phone TEXT, is_default INTEGER DEFAULT 0, create_time TEXT NOT NULL)');
    await db.execute('ALTER TABLE products ADD COLUMN warehouse_id INTEGER DEFAULT 1');
    await db.execute("ALTER TABLE customers ADD COLUMN tier TEXT DEFAULT '普通'");
    await db.execute('ALTER TABLE customers ADD COLUMN credit_limit REAL DEFAULT 0');
    await db.execute('ALTER TABLE customers ADD COLUMN due_days INTEGER DEFAULT 0');
    await db.execute('ALTER TABLE customers ADD COLUMN total_owing REAL DEFAULT 0');
    await db.insert('warehouses', {'name': '默认仓库', 'is_default': 1, 'create_time': DateTime.now().toIso8601String()});
  }

  static Future<void> v6ToV7(Database db) async {
    await db.execute("CREATE TABLE purchase_orders (id INTEGER PRIMARY KEY AUTOINCREMENT, order_no TEXT NOT NULL UNIQUE, supplier_name TEXT, supplier_phone TEXT, warehouse_id INTEGER DEFAULT 1, items TEXT, total_amount REAL DEFAULT 0, paid_amount REAL DEFAULT 0, owing_amount REAL DEFAULT 0, status TEXT DEFAULT ' draft ', remark TEXT, create_time TEXT NOT NULL, complete_time TEXT, FOREIGN KEY (warehouse_id) REFERENCES warehouses(id))");
    await db.execute("CREATE TABLE return_orders (id INTEGER PRIMARY KEY AUTOINCREMENT, order_no TEXT NOT NULL UNIQUE, type TEXT NOT NULL, original_order_id INTEGER, customer_id INTEGER, supplier_name TEXT, items TEXT, total_amount REAL DEFAULT 0, status TEXT DEFAULT ' pending ', reason TEXT, remark TEXT, create_time TEXT NOT NULL, complete_time TEXT)");
  }

  static Future<void> v7ToV8(Database db) async {
    await db.execute("CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, parent_id INTEGER, sort_order INTEGER DEFAULT 0, create_time TEXT NOT NULL)");
    await db.execute("CREATE TABLE inventory_checks (id INTEGER PRIMARY KEY AUTOINCREMENT, check_no TEXT NOT NULL UNIQUE, warehouse_id INTEGER DEFAULT 1, status TEXT DEFAULT ' draft ', remark TEXT, create_time TEXT NOT NULL, complete_time TEXT, FOREIGN KEY (warehouse_id) REFERENCES warehouses(id))");
    await db.execute('CREATE TABLE inventory_check_items (id INTEGER PRIMARY KEY AUTOINCREMENT, check_id INTEGER NOT NULL, product_id INTEGER NOT NULL, system_stock INTEGER NOT NULL, actual_stock INTEGER, difference INTEGER, remark TEXT, FOREIGN KEY (check_id) REFERENCES inventory_checks(id), FOREIGN KEY (product_id) REFERENCES products(id))');
    await db.execute('CREATE TABLE customer_prices (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER NOT NULL, product_id INTEGER NOT NULL, price REAL NOT NULL, create_time TEXT NOT NULL, FOREIGN KEY (customer_id) REFERENCES customers(id), FOREIGN KEY (product_id) REFERENCES products(id), UNIQUE(customer_id, product_id))');
    await db.execute("CREATE TABLE members (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, member_no TEXT NOT NULL UNIQUE, name TEXT NOT NULL, phone TEXT, points INTEGER DEFAULT 0, level TEXT DEFAULT '普通会员', create_time TEXT NOT NULL, FOREIGN KEY (customer_id) REFERENCES customers(id))");
  }
}
