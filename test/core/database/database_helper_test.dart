// 数据库迁移测试：用 sqflite_common_ffi 跑内存 SQLite
//
// 测试策略：
// 1) 模拟 v4 schema
// 2) 跑 Migrations.v4ToV5 / v5ToV6 / v6ToV7 / v7ToV8
// 3) 用 PRAGMA table_info 和 sqlite_master 验证终点 schema

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:furni_bill/core/database/migrations.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<Database> openAtVersion(int version, Future<void> Function(Database, int) onCreate) async {
    return databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: version, onCreate: onCreate),
    );
  }

  Future<List<String>> columnNames(Database db, String table) async {
    final rows = await db.rawQuery("PRAGMA table_info(" + table + ")");
    return rows.map((r) => r["name"] as String).toList();
  }

  Future<List<String>> tableNames(Database db) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );
    return rows.map((r) => r["name"] as String).toList();
  }

  Future<void> createV4Products(Database db) => db.execute('''CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    spec TEXT,
    unit TEXT,
    price REAL NOT NULL,
    stock INTEGER DEFAULT 0,
    create_time TEXT NOT NULL,
    update_time TEXT NOT NULL
  )''');

  Future<void> createV4Customers(Database db) => db.execute('''CREATE TABLE customers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    address TEXT,
    create_time TEXT NOT NULL,
    update_time TEXT NOT NULL
  )''');

  Future<void> createV4(Database db, int version) async {
    await createV4Products(db);
    await createV4Customers(db);
  }

  group('v4 -> v5', () {
    test('products 加 5 个字段', () async {
      final db = await openAtVersion(4, createV4);
      try {
        await Migrations.v4ToV5(db);
        final cols = await columnNames(db, 'products');
        expect(cols, contains('cost_price'));
        expect(cols, contains('min_stock'));
        expect(cols, contains('category_id'));
        expect(cols, contains('image_url'));
        expect(cols, contains('barcode'));
      } finally {
        await db.close();
      }
    });

    test('customers 字段不变', () async {
      final db = await openAtVersion(4, createV4);
      try {
        await Migrations.v4ToV5(db);
        final cols = await columnNames(db, 'customers');
        expect(cols, isNot(contains('tier')));
        expect(cols, isNot(contains('credit_limit')));
      } finally {
        await db.close();
      }
    });
  });

  group('v5 -> v6', () {
    test('warehouses 表创建 + 默认仓库入库', () async {
      final db = await openAtVersion(4, createV4);
      try {
        await Migrations.v4ToV5(db);
        await Migrations.v5ToV6(db);
        final tables = await tableNames(db);
        expect(tables, contains('warehouses'));
        final wh = await db.query('warehouses');
        expect(wh, hasLength(1));
        expect(wh.first['is_default'], 1);
        expect(wh.first['name'], '默认仓库');
      } finally {
        await db.close();
      }
    });

    test('products 加 warehouse_id、customers 加 4 个字段', () async {
      final db = await openAtVersion(4, createV4);
      try {
        await Migrations.v4ToV5(db);
        await Migrations.v5ToV6(db);
        final pCols = await columnNames(db, 'products');
        expect(pCols, contains('warehouse_id'));
        final cCols = await columnNames(db, 'customers');
        expect(cCols, contains('tier'));
        expect(cCols, contains('credit_limit'));
        expect(cCols, contains('due_days'));
        expect(cCols, contains('total_owing'));
      } finally {
        await db.close();
      }
    });
  });

  group('v6 -> v7', () {
    test('加 purchase_orders 和 return_orders 表', () async {
      final db = await openAtVersion(4, createV4);
      try {
        await Migrations.v4ToV5(db);
        await Migrations.v5ToV6(db);
        await Migrations.v6ToV7(db);
        final tables = await tableNames(db);
        expect(tables, contains('purchase_orders'));
        expect(tables, contains('return_orders'));
      } finally {
        await db.close();
      }
    });
  });

  group('v7 -> v8', () {
    test('加 5 个新表', () async {
      final db = await openAtVersion(4, createV4);
      try {
        await Migrations.v4ToV5(db);
        await Migrations.v5ToV6(db);
        await Migrations.v6ToV7(db);
        await Migrations.v7ToV8(db);
        final tables = await tableNames(db);
        expect(tables, contains('categories'));
        expect(tables, contains('inventory_checks'));
        expect(tables, contains('inventory_check_items'));
        expect(tables, contains('customer_prices'));
        expect(tables, contains('members'));
      } finally {
        await db.close();
      }
    });
  });

  group('end-to-end: v4 -> v8', () {
    test('4 步迁移后是 v8 schema', () async {
      final db = await openAtVersion(4, createV4);
      try {
        await Migrations.v4ToV5(db);
        await Migrations.v5ToV6(db);
        await Migrations.v6ToV7(db);
        await Migrations.v7ToV8(db);
        final tables = await tableNames(db);
        for (final t in ['products', 'customers', 'warehouses',
            'purchase_orders', 'return_orders', 'categories',
            'inventory_checks', 'inventory_check_items', 'customer_prices', 'members']) {
          expect(tables, contains(t), reason: "table $t missing");
        }
      } finally {
        await db.close();
      }
    });
  });
}
