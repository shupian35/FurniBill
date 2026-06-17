# FurniBill 完整功能扩展实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use compose:subagent (recommended) or compose:execute to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 FurniBill 从简易开单工具升级为功能完整的批发进销存系统，补齐采购、退货、分类、SKU、客户分级、多仓库、库存预警、对账、盘点、商品图片、打印模板、员工权限、会员等核心功能。

**Architecture:** 分 5 个阶段实现，每阶段独立可测试。数据库 schema 从 v4 升级到 v9，新增 10+ 张表。保持 Provider 状态管理，UI 风格一致。

**Tech Stack:** Flutter 3.41+, Dart 3.11+, sqflite, Provider, Material 3

---

## Phase 1: 数据库与模型层 (Schema v5-v6)

### Task 1: 数据库 Schema 升级 - 商品增强

**Files:**
- Modify: `lib/core/database/database_helper.dart`
- Modify: `lib/core/models/product.dart`
- Test: `test/models/product_test.dart`

- [ ] **Step 1: 修改 products 表添加新字段**

在 `database_helper.dart` 的 `_createDB` 方法中，修改 products 表定义：

```dart
await db.execute('''
  CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    spec TEXT,
    unit TEXT,
    price REAL NOT NULL,
    cost_price REAL DEFAULT 0,
    stock INTEGER DEFAULT 0,
    min_stock INTEGER DEFAULT 0,
    category_id INTEGER,
    image_url TEXT,
    barcode TEXT,
    create_time TEXT NOT NULL,
    update_time TEXT NOT NULL
  )
''');
```

- [ ] **Step 2: 添加数据库迁移代码**

在 `_upgradeDB` 方法中添加 v5 迁移：

```dart
if (oldVersion < 5) {
  await db.execute("ALTER TABLE products ADD COLUMN cost_price REAL DEFAULT 0");
  await db.execute("ALTER TABLE products ADD COLUMN min_stock INTEGER DEFAULT 0");
  await db.execute("ALTER TABLE products ADD COLUMN category_id INTEGER");
  await db.execute("ALTER TABLE products ADD COLUMN image_url TEXT");
  await db.execute("ALTER TABLE products ADD COLUMN barcode TEXT");
}
```

- [ ] **Step 3: 更新 Product 模型**

修改 `lib/core/models/product.dart`：

```dart
class Product {
  final int? id;
  final String name;
  final String? spec;
  final String? unit;
  final double price;
  final double costPrice;
  final int stock;
  final int minStock;
  final int? categoryId;
  final String? imageUrl;
  final String? barcode;
  final DateTime createTime;
  final DateTime updateTime;

  Product({
    this.id,
    required this.name,
    this.spec,
    this.unit,
    required this.price,
    this.costPrice = 0,
    this.stock = 0,
    this.minStock = 0,
    this.categoryId,
    this.imageUrl,
    this.barcode,
    DateTime? createTime,
    DateTime? updateTime,
  })  : createTime = createTime ?? DateTime.now(),
        updateTime = updateTime ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'spec': spec,
    'unit': unit,
    'price': price,
    'cost_price': costPrice,
    'stock': stock,
    'min_stock': minStock,
    'category_id': categoryId,
    'image_url': imageUrl,
    'barcode': barcode,
    'create_time': createTime.toIso8601String(),
    'update_time': updateTime.toIso8601String(),
  };

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      spec: map['spec'] as String?,
      unit: map['unit'] as String?,
      price: (map['price'] as num).toDouble(),
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0,
      stock: map['stock'] as int? ?? 0,
      minStock: map['min_stock'] as int? ?? 0,
      categoryId: map['category_id'] as int?,
      imageUrl: map['image_url'] as String?,
      barcode: map['barcode'] as String?,
      createTime: DateTime.parse(map['create_time'] as String),
      updateTime: DateTime.parse(map['update_time'] as String),
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? spec,
    String? unit,
    double? price,
    double? costPrice,
    int? stock,
    int? minStock,
    int? categoryId,
    String? imageUrl,
    String? barcode,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        spec: spec ?? this.spec,
        unit: unit ?? this.unit,
        price: price ?? this.price,
        costPrice: costPrice ?? this.costPrice,
        stock: stock ?? this.stock,
        minStock: minStock ?? this.minStock,
        categoryId: categoryId ?? this.categoryId,
        imageUrl: imageUrl ?? this.imageUrl,
        barcode: barcode ?? this.barcode,
        createTime: createTime,
        updateTime: DateTime.now(),
      );
}
```

- [ ] **Step 4: 更新数据库版本号**

修改 `database_helper.dart` 第 22 行：

```dart
version: 5,
```

- [ ] **Step 5: 运行测试**

Run: `flutter test test/models/product_test.dart`
Expected: All tests pass

- [ ] **Step 6: 提交**

```bash
git add lib/core/database/database_helper.dart lib/core/models/product.dart
git commit -m "feat: add product fields for cost, min_stock, category, image, barcode"
```

---

### Task 2: 新增商品分类表

**Files:**
- Modify: `lib/core/database/database_helper.dart`
- Create: `lib/core/models/category.dart`
- Test: `test/models/category_test.dart`

- [ ] **Step 1: 在 _createDB 中添加 categories 表**

```dart
await db.execute('''
  CREATE TABLE categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    parent_id INTEGER,
    sort_order INTEGER DEFAULT 0,
    create_time TEXT NOT NULL
  )
''');
```

- [ ] **Step 2: 创建 Category 模型**

创建 `lib/core/models/category.dart`：

```dart
class Category {
  final int? id;
  final String name;
  final int? parentId;
  final int sortOrder;
  final DateTime createTime;

  Category({
    this.id,
    required this.name,
    this.parentId,
    this.sortOrder = 0,
    DateTime? createTime,
  }) : createTime = createTime ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'parent_id': parentId,
    'sort_order': sortOrder,
    'create_time': createTime.toIso8601String(),
  };

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      parentId: map['parent_id'] as int?,
      sortOrder: map['sort_order'] as int? ?? 0,
      createTime: DateTime.parse(map['create_time'] as String),
    );
  }
}
```

- [ ] **Step 3: 创建分类测试**

创建 `test/models/category_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:furni_bill/core/models/category.dart';

void main() {
  group('Category', () {
    test('toMap / fromMap roundtrip', () {
      final category = Category(
        id: 1,
        name: '沙发',
        parentId: null,
        sortOrder: 1,
      );
      final map = category.toMap();
      final restored = Category.fromMap(map);

      expect(restored.id, 1);
      expect(restored.name, '沙发');
      expect(restored.parentId, isNull);
      expect(restored.sortOrder, 1);
    });

    test('default values', () {
      final category = Category(name: '餐桌');
      expect(category.id, isNull);
      expect(category.parentId, isNull);
      expect(category.sortOrder, 0);
    });
  });
}
```

- [ ] **Step 4: 运行测试**

Run: `flutter test test/models/category_test.dart`
Expected: All tests pass

- [ ] **Step 5: 提交**

```bash
git add lib/core/database/database_helper.dart lib/core/models/category.dart test/models/category_test.dart
git commit -m "feat: add categories table and Category model"
```

---

### Task 3: 新增多仓库表

**Files:**
- Modify: `lib/core/database/database_helper.dart`
- Create: `lib/core/models/warehouse.dart`
- Test: `test/models/warehouse_test.dart`

- [ ] **Step 1: 在 _createDB 中添加 warehouses 表**

```dart
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
```

- [ ] **Step 2: 修改 products 表添加 warehouse_id**

在 products 表定义中添加：

```dart
warehouse_id INTEGER DEFAULT 1,
```

- [ ] **Step 3: 创建 Warehouse 模型**

创建 `lib/core/models/warehouse.dart`：

```dart
class Warehouse {
  final int? id;
  final String name;
  final String? address;
  final String? phone;
  final bool isDefault;
  final DateTime createTime;

  Warehouse({
    this.id,
    required this.name,
    this.address,
    this.phone,
    this.isDefault = false,
    DateTime? createTime,
  }) : createTime = createTime ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'address': address,
    'phone': phone,
    'is_default': isDefault ? 1 : 0,
    'create_time': createTime.toIso8601String(),
  };

  factory Warehouse.fromMap(Map<String, dynamic> map) {
    return Warehouse(
      id: map['id'] as int?,
      name: map['name'] as String,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      isDefault: map['is_default'] == 1,
      createTime: DateTime.parse(map['create_time'] as String),
    );
  }
}
```

- [ ] **Step 4: 添加数据库迁移 v6**

在 `_upgradeDB` 中添加：

```dart
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
  // 插入默认仓库
  await db.insert('warehouses', {
    'name': '默认仓库',
    'is_default': 1,
    'create_time': DateTime.now().toIso8601String(),
  });
}
```

- [ ] **Step 5: 更新数据库版本号**

修改 `database_helper.dart` 第 22 行：

```dart
version: 6,
```

- [ ] **Step 6: 运行测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 7: 提交**

```bash
git add lib/core/database/database_helper.dart lib/core/models/warehouse.dart test/models/warehouse_test.dart
git commit -m "feat: add warehouses table for multi-warehouse support"
```

---

### Task 4: 新增客户分级字段

**Files:**
- Modify: `lib/core/database/database_helper.dart`
- Modify: `lib/core/models/customer.dart`
- Test: `test/models/customer_test.dart`

- [ ] **Step 1: 修改 customers 表添加新字段**

在 `_createDB` 中修改 customers 表：

```dart
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
```

- [ ] **Step 2: 添加数据库迁移**

在 `_upgradeDB` 中添加：

```dart
if (oldVersion < 6) {
  // ... warehouses migration ...
  await db.execute("ALTER TABLE customers ADD COLUMN tier TEXT DEFAULT '普通'");
  await db.execute("ALTER TABLE customers ADD COLUMN credit_limit REAL DEFAULT 0");
  await db.execute("ALTER TABLE customers ADD COLUMN due_days INTEGER DEFAULT 0");
  await db.execute("ALTER TABLE customers ADD COLUMN total_owing REAL DEFAULT 0");
}
```

- [ ] **Step 3: 更新 Customer 模型**

修改 `lib/core/models/customer.dart`：

```dart
class Customer {
  final int? id;
  final String name;
  final String phone;
  final String? address;
  final String tier;
  final double creditLimit;
  final int dueDays;
  final double totalOwing;
  final DateTime createTime;
  final DateTime updateTime;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    this.address,
    this.tier = '普通',
    this.creditLimit = 0,
    this.dueDays = 0,
    this.totalOwing = 0,
    DateTime? createTime,
    DateTime? updateTime,
  })  : createTime = createTime ?? DateTime.now(),
        updateTime = updateTime ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'phone': phone,
    'address': address,
    'tier': tier,
    'credit_limit': creditLimit,
    'due_days': dueDays,
    'total_owing': totalOwing,
    'create_time': createTime.toIso8601String(),
    'update_time': updateTime.toIso8601String(),
  };

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String?,
      tier: map['tier'] as String? ?? '普通',
      creditLimit: (map['credit_limit'] as num?)?.toDouble() ?? 0,
      dueDays: map['due_days'] as int? ?? 0,
      totalOwing: (map['total_owing'] as num?)?.toDouble() ?? 0,
      createTime: DateTime.parse(map['create_time'] as String),
      updateTime: DateTime.parse(map['update_time'] as String),
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? tier,
    double? creditLimit,
    int? dueDays,
    double? totalOwing,
  }) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        tier: tier ?? this.tier,
        creditLimit: creditLimit ?? this.creditLimit,
        dueDays: dueDays ?? this.dueDays,
        totalOwing: totalOwing ?? this.totalOwing,
        createTime: createTime,
        updateTime: DateTime.now(),
      );
}
```

- [ ] **Step 4: 运行测试**

Run: `flutter test test/models/customer_test.dart`
Expected: All tests pass

- [ ] **Step 5: 提交**

```bash
git add lib/core/database/database_helper.dart lib/core/models/customer.dart
git commit -m "feat: add customer tier, credit limit, due days fields"
```

---

## Phase 2: 采购与退货模块 (Schema v7)

### Task 5: 新增采购订单表

**Files:**
- Modify: `lib/core/database/database_helper.dart`
- Create: `lib/core/models/purchase_order.dart`
- Test: `test/models/purchase_order_test.dart`

- [ ] **Step 1: 在 _createDB 中添加 purchase_orders 和 purchase_items 表**

```dart
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
```

- [ ] **Step 2: 创建 PurchaseOrder 模型**

创建 `lib/core/models/purchase_order.dart`：

```dart
import 'dart:convert';

class PurchaseOrderItem {
  int? productId;
  String name;
  String? spec;
  String? unit;
  double quantity;
  double price;
  double amount;

  PurchaseOrderItem({
    this.productId,
    required this.name,
    this.spec,
    this.unit,
    required this.quantity,
    required this.price,
    double? amount,
  }) : amount = amount ?? (quantity * price);

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'name': name,
    'spec': spec,
    'unit': unit,
    'quantity': quantity,
    'price': price,
    'amount': amount,
  };

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItem(
      productId: json['product_id'] as int?,
      name: json['name'] as String,
      spec: json['spec'] as String?,
      unit: json['unit'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }
}

class PurchaseOrder {
  final int? id;
  final String orderNo;
  final String? supplierName;
  final String? supplierPhone;
  final int warehouseId;
  final List<PurchaseOrderItem> items;
  final double totalAmount;
  final double paidAmount;
  final double owingAmount;
  final String status;
  final String? remark;
  final DateTime createTime;
  final DateTime? completeTime;

  PurchaseOrder({
    this.id,
    required this.orderNo,
    this.supplierName,
    this.supplierPhone,
    this.warehouseId = 1,
    this.items = const [],
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.owingAmount = 0,
    this.status = 'draft',
    this.remark,
    DateTime? createTime,
    this.completeTime,
  }) : createTime = createTime ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'order_no': orderNo,
    'supplier_name': supplierName,
    'supplier_phone': supplierPhone,
    'warehouse_id': warehouseId,
    'items': jsonEncode(items.map((i) => i.toJson()).toList()),
    'total_amount': totalAmount,
    'paid_amount': paidAmount,
    'owing_amount': owingAmount,
    'status': status,
    'remark': remark,
    'create_time': createTime.toIso8601String(),
    'complete_time': completeTime?.toIso8601String(),
  };

  factory PurchaseOrder.fromMap(Map<String, dynamic> map) {
    List<PurchaseOrderItem> parsedItems = [];
    final raw = map['items']?.toString() ?? '';
    if (raw.isNotEmpty && raw != '[]') {
      try {
        final list = jsonDecode(raw) as List;
        parsedItems = list.map((e) => PurchaseOrderItem.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    return PurchaseOrder(
      id: map['id'] as int?,
      orderNo: map['order_no'] as String,
      supplierName: map['supplier_name'] as String?,
      supplierPhone: map['supplier_phone'] as String?,
      warehouseId: map['warehouse_id'] as int? ?? 1,
      items: parsedItems,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0,
      owingAmount: (map['owing_amount'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'draft',
      remark: map['remark'] as String?,
      createTime: DateTime.parse(map['create_time'] as String),
      completeTime: map['complete_time'] != null
          ? DateTime.parse(map['complete_time'] as String)
          : null,
    );
  }
}
```

- [ ] **Step 3: 添加数据库迁移 v7**

在 `_upgradeDB` 中添加：

```dart
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
}
```

- [ ] **Step 4: 更新数据库版本号**

修改 `database_helper.dart` 第 22 行：

```dart
version: 7,
```

- [ ] **Step 5: 运行测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 6: 提交**

```bash
git add lib/core/database/database_helper.dart lib/core/models/purchase_order.dart
git commit -m "feat: add purchase_orders table and PurchaseOrder model"
```

---

### Task 6: 新增退货订单表

**Files:**
- Modify: `lib/core/database/database_helper.dart`
- Create: `lib/core/models/return_order.dart`
- Test: `test/models/return_order_test.dart`

- [ ] **Step 1: 在 _createDB 中添加 return_orders 表**

```dart
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
```

- [ ] **Step 2: 创建 ReturnOrder 模型**

创建 `lib/core/models/return_order.dart`：

```dart
import 'dart:convert';

class ReturnOrderItem {
  int? productId;
  String name;
  double quantity;
  double price;
  double amount;

  ReturnOrderItem({
    this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    double? amount,
  }) : amount = amount ?? (quantity * price);

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'name': name,
    'quantity': quantity,
    'price': price,
    'amount': amount,
  };

  factory ReturnOrderItem.fromJson(Map<String, dynamic> json) {
    return ReturnOrderItem(
      productId: json['product_id'] as int?,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }
}

class ReturnOrder {
  final int? id;
  final String orderNo;
  final String type; // 'sales_return' or 'purchase_return'
  final int? originalOrderId;
  final int? customerId;
  final String? supplierName;
  final List<ReturnOrderItem> items;
  final double totalAmount;
  final String status;
  final String? reason;
  final String? remark;
  final DateTime createTime;
  final DateTime? completeTime;

  ReturnOrder({
    this.id,
    required this.orderNo,
    required this.type,
    this.originalOrderId,
    this.customerId,
    this.supplierName,
    this.items = const [],
    this.totalAmount = 0,
    this.status = 'pending',
    this.reason,
    this.remark,
    DateTime? createTime,
    this.completeTime,
  }) : createTime = createTime ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'order_no': orderNo,
    'type': type,
    'original_order_id': originalOrderId,
    'customer_id': customerId,
    'supplier_name': supplierName,
    'items': jsonEncode(items.map((i) => i.toJson()).toList()),
    'total_amount': totalAmount,
    'status': status,
    'reason': reason,
    'remark': remark,
    'create_time': createTime.toIso8601String(),
    'complete_time': completeTime?.toIso8601String(),
  };

  factory ReturnOrder.fromMap(Map<String, dynamic> map) {
    List<ReturnOrderItem> parsedItems = [];
    final raw = map['items']?.toString() ?? '';
    if (raw.isNotEmpty && raw != '[]') {
      try {
        final list = jsonDecode(raw) as List;
        parsedItems = list.map((e) => ReturnOrderItem.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    return ReturnOrder(
      id: map['id'] as int?,
      orderNo: map['order_no'] as String,
      type: map['type'] as String,
      originalOrderId: map['original_order_id'] as int?,
      customerId: map['customer_id'] as int?,
      supplierName: map['supplier_name'] as String?,
      items: parsedItems,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'pending',
      reason: map['reason'] as String?,
      remark: map['remark'] as String?,
      createTime: DateTime.parse(map['create_time'] as String),
      completeTime: map['complete_time'] != null
          ? DateTime.parse(map['complete_time'] as String)
          : null,
    );
  }
}
```

- [ ] **Step 3: 添加数据库迁移**

在 `_upgradeDB` 中添加（与 v7 合并）：

```dart
if (oldVersion < 7) {
  // ... purchase_orders migration ...
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
```

- [ ] **Step 4: 运行测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 5: 提交**

```bash
git add lib/core/database/database_helper.dart lib/core/models/return_order.dart
git commit -m "feat: add return_orders table and ReturnOrder model"
```

---

## Phase 3: 库存增强模块 (Schema v8)

### Task 7: 新增库存盘点表

**Files:**
- Modify: `lib/core/database/database_helper.dart`
- Create: `lib/core/models/inventory_check.dart`
- Test: `test/models/inventory_check_test.dart`

- [ ] **Step 1: 在 _createDB 中添加 inventory_checks 和 inventory_check_items 表**

```dart
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
```

- [ ] **Step 2: 创建 InventoryCheck 模型**

创建 `lib/core/models/inventory_check.dart`：

```dart
class InventoryCheckItem {
  final int? id;
  final int? checkId;
  final int productId;
  final String? productName;
  final int systemStock;
  final int? actualStock;
  final int? difference;
  final String? remark;

  InventoryCheckItem({
    this.id,
    this.checkId,
    required this.productId,
    this.productName,
    required this.systemStock,
    this.actualStock,
    this.difference,
    this.remark,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'check_id': checkId,
    'product_id': productId,
    'system_stock': systemStock,
    'actual_stock': actualStock,
    'difference': difference,
    'remark': remark,
  };

  factory InventoryCheckItem.fromMap(Map<String, dynamic> map) {
    return InventoryCheckItem(
      id: map['id'] as int?,
      checkId: map['check_id'] as int?,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String?,
      systemStock: map['system_stock'] as int,
      actualStock: map['actual_stock'] as int?,
      difference: map['difference'] as int?,
      remark: map['remark'] as String?,
    );
  }
}

class InventoryCheck {
  final int? id;
  final String checkNo;
  final int warehouseId;
  final String status;
  final String? remark;
  final DateTime createTime;
  final DateTime? completeTime;

  InventoryCheck({
    this.id,
    required this.checkNo,
    this.warehouseId = 1,
    this.status = 'draft',
    this.remark,
    DateTime? createTime,
    this.completeTime,
  }) : createTime = createTime ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'check_no': checkNo,
    'warehouse_id': warehouseId,
    'status': status,
    'remark': remark,
    'create_time': createTime.toIso8601String(),
    'complete_time': completeTime?.toIso8601String(),
  };

  factory InventoryCheck.fromMap(Map<String, dynamic> map) {
    return InventoryCheck(
      id: map['id'] as int?,
      checkNo: map['check_no'] as String,
      warehouseId: map['warehouse_id'] as int? ?? 1,
      status: map['status'] as String? ?? 'draft',
      remark: map['remark'] as String?,
      createTime: DateTime.parse(map['create_time'] as String),
      completeTime: map['complete_time'] != null
          ? DateTime.parse(map['complete_time'] as String)
          : null,
    );
  }
}
```

- [ ] **Step 3: 添加数据库迁移 v8**

在 `_upgradeDB` 中添加：

```dart
if (oldVersion < 8) {
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
}
```

- [ ] **Step 4: 更新数据库版本号**

修改 `database_helper.dart` 第 22 行：

```dart
version: 8,
```

- [ ] **Step 5: 运行测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 6: 提交**

```bash
git add lib/core/database/database_helper.dart lib/core/models/inventory_check.dart
git commit -m "feat: add inventory check tables for stocktaking"
```

---

### Task 8: 新增客户价格体系表

**Files:**
- Modify: `lib/core/database/database_helper.dart`
- Create: `lib/core/models/customer_price.dart`
- Test: `test/models/customer_price_test.dart`

- [ ] **Step 1: 在 _createDB 中添加 customer_prices 表**

```dart
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
```

- [ ] **Step 2: 创建 CustomerPrice 模型**

创建 `lib/core/models/customer_price.dart`：

```dart
class CustomerPrice {
  final int? id;
  final int customerId;
  final int productId;
  final double price;
  final DateTime createTime;

  CustomerPrice({
    this.id,
    required this.customerId,
    required this.productId,
    required this.price,
    DateTime? createTime,
  }) : createTime = createTime ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'customer_id': customerId,
    'product_id': productId,
    'price': price,
    'create_time': createTime.toIso8601String(),
  };

  factory CustomerPrice.fromMap(Map<String, dynamic> map) {
    return CustomerPrice(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
      productId: map['product_id'] as int,
      price: (map['price'] as num).toDouble(),
      createTime: DateTime.parse(map['create_time'] as String),
    );
  }
}
```

- [ ] **Step 3: 添加数据库迁移**

在 `_upgradeDB` 中添加（与 v8 合并）：

```dart
if (oldVersion < 8) {
  // ... inventory checks migration ...
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
}
```

- [ ] **Step 4: 运行测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 5: 提交**

```bash
git add lib/core/database/database_helper.dart lib/core/models/customer_price.dart
git commit -m "feat: add customer_prices table for tier-based pricing"
```

---

## Phase 4: Provider 与业务逻辑

### Task 9: 新增分类 Provider

**Files:**
- Create: `lib/core/providers/category_provider.dart`
- Modify: `lib/main.dart`
- Test: `test/providers/category_provider_test.dart`

- [ ] **Step 1: 创建 CategoryProvider**

创建 `lib/core/providers/category_provider.dart`：

```dart
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<Category> _categories = [];
  bool _loading = false;

  List<Category> get categories => _categories;
  bool get loading => _loading;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    await _loadCategories();
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadCategories() async {
    final rows = await _db.query('categories', orderBy: 'sort_order ASC');
    _categories = rows.map((r) => Category.fromMap(r)).toList();
  }

  Future<int> addCategory(Category category) async {
    final id = await _db.insert('categories', category.toMap());
    await _loadCategories();
    notifyListeners();
    return id;
  }

  Future<void> updateCategory(Category category) async {
    await _db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    await _loadCategories();
    notifyListeners();
  }

  Future<void> deleteCategory(int id) async {
    await _db.delete('categories', where: 'id = ?', whereArgs: [id]);
    await _loadCategories();
    notifyListeners();
  }
}
```

- [ ] **Step 2: 在 main.dart 中注册 Provider**

修改 `lib/main.dart` 第 24-28 行：

```dart
providers: [
  ChangeNotifierProvider(create: (_) => ProductProvider()..init()),
  ChangeNotifierProvider(create: (_) => CustomerProvider()..init()),
  ChangeNotifierProvider(create: (_) => OrderProvider()..init()),
  ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
  ChangeNotifierProvider(create: (_) => CategoryProvider()..init()),
],
```

- [ ] **Step 3: 运行测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 4: 提交**

```bash
git add lib/core/providers/category_provider.dart lib/main.dart
git commit -m "feat: add CategoryProvider for product category management"
```

---

### Task 10: 新增仓库 Provider

**Files:**
- Create: `lib/core/providers/warehouse_provider.dart`
- Modify: `lib/main.dart`
- Test: `test/providers/warehouse_provider_test.dart`

- [ ] **Step 1: 创建 WarehouseProvider**

创建 `lib/core/providers/warehouse_provider.dart`：

```dart
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/warehouse.dart';

class WarehouseProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<Warehouse> _warehouses = [];
  bool _loading = false;

  List<Warehouse> get warehouses => _warehouses;
  bool get loading => _loading;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    await _loadWarehouses();
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadWarehouses() async {
    final rows = await _db.query('warehouses', orderBy: 'is_default DESC');
    _warehouses = rows.map((r) => Warehouse.fromMap(r)).toList();
  }

  Warehouse? get defaultWarehouse {
    return _warehouses.firstWhere(
      (w) => w.isDefault,
      orElse: () => _warehouses.isNotEmpty ? _warehouses.first : Warehouse(name: '默认仓库'),
    );
  }

  Future<int> addWarehouse(Warehouse warehouse) async {
    final id = await _db.insert('warehouses', warehouse.toMap());
    await _loadWarehouses();
    notifyListeners();
    return id;
  }

  Future<void> updateWarehouse(Warehouse warehouse) async {
    await _db.update(
      'warehouses',
      warehouse.toMap(),
      where: 'id = ?',
      whereArgs: [warehouse.id],
    );
    await _loadWarehouses();
    notifyListeners();
  }

  Future<void> deleteWarehouse(int id) async {
    await _db.delete('warehouses', where: 'id = ?', whereArgs: [id]);
    await _loadWarehouses();
    notifyListeners();
  }
}
```

- [ ] **Step 2: 在 main.dart 中注册 Provider**

修改 `lib/main.dart`：

```dart
providers: [
  ChangeNotifierProvider(create: (_) => ProductProvider()..init()),
  ChangeNotifierProvider(create: (_) => CustomerProvider()..init()),
  ChangeNotifierProvider(create: (_) => OrderProvider()..init()),
  ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
  ChangeNotifierProvider(create: (_) => CategoryProvider()..init()),
  ChangeNotifierProvider(create: (_) => WarehouseProvider()..init()),
],
```

- [ ] **Step 3: 运行测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 4: 提交**

```bash
git add lib/core/providers/warehouse_provider.dart lib/main.dart
git commit -m "feat: add WarehouseProvider for multi-warehouse support"
```

---

### Task 11: 新增采购 Provider

**Files:**
- Create: `lib/core/providers/purchase_provider.dart`
- Modify: `lib/main.dart`
- Test: `test/providers/purchase_provider_test.dart`

- [ ] **Step 1: 创建 PurchaseProvider**

创建 `lib/core/providers/purchase_provider.dart`：

```dart
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/purchase_order.dart';

class PurchaseProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<PurchaseOrder> _orders = [];
  bool _loading = false;

  List<PurchaseOrder> get orders => _orders;
  bool get loading => _loading;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    await _loadOrders();
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadOrders() async {
    final rows = await _db.query('purchase_orders', orderBy: 'create_time DESC');
    _orders = rows.map((r) => PurchaseOrder.fromMap(r)).toList();
  }

  String generateOrderNo() {
    final now = DateTime.now();
    final date = DateFormat('yyyyMMdd').format(now);
    final time = DateFormat('HHmmss').format(now);
    return 'PO$date$time';
  }

  Future<int> saveOrder(PurchaseOrder order) async {
    final id = await _db.insert('purchase_orders', order.toMap());
    await refresh();
    return id;
  }

  Future<void> updateOrder(PurchaseOrder order) async {
    await _db.update(
      'purchase_orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
    await refresh();
  }

  Future<void> deleteOrder(int id) async {
    await _db.delete('purchase_orders', where: 'id = ?', whereArgs: [id]);
    await refresh();
  }

  Future<void> completeOrder(PurchaseOrder order, Map<int, int> stockChanges) async {
    await _db.update(
      'purchase_orders',
      {'status': 'completed', 'complete_time': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [order.id],
    );
    // 增加库存
    for (final entry in stockChanges.entries) {
      await _db.rawUpdate(
        'UPDATE products SET stock = stock + ? WHERE id = ?',
        [entry.value, entry.key],
      );
    }
    await refresh();
  }

  Future<void> refresh() async {
    await _loadOrders();
    notifyListeners();
  }
}
```

- [ ] **Step 2: 在 main.dart 中注册 Provider**

修改 `lib/main.dart`：

```dart
providers: [
  ChangeNotifierProvider(create: (_) => ProductProvider()..init()),
  ChangeNotifierProvider(create: (_) => CustomerProvider()..init()),
  ChangeNotifierProvider(create: (_) => OrderProvider()..init()),
  ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
  ChangeNotifierProvider(create: (_) => CategoryProvider()..init()),
  ChangeNotifierProvider(create: (_) => WarehouseProvider()..init()),
  ChangeNotifierProvider(create: (_) => PurchaseProvider()..init()),
],
```

- [ ] **Step 3: 运行测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 4: 提交**

```bash
git add lib/core/providers/purchase_provider.dart lib/main.dart
git commit -m "feat: add PurchaseProvider for purchase order management"
```

---

### Task 12: 新增退货 Provider

**Files:**
- Create: `lib/core/providers/return_provider.dart`
- Modify: `lib/main.dart`
- Test: `test/providers/return_provider_test.dart`

- [ ] **Step 1: 创建 ReturnProvider**

创建 `lib/core/providers/return_provider.dart`：

```dart
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/return_order.dart';

class ReturnProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<ReturnOrder> _returns = [];
  bool _loading = false;

  List<ReturnOrder> get returns => _returns;
  bool get loading => _loading;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    await _loadReturns();
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadReturns() async {
    final rows = await _db.query('return_orders', orderBy: 'create_time DESC');
    _returns = rows.map((r) => ReturnOrder.fromMap(r)).toList();
  }

  String generateOrderNo() {
    final now = DateTime.now();
    final date = DateFormat('yyyyMMdd').format(now);
    final time = DateFormat('HHmmss').format(now);
    return 'RO$date$time';
  }

  Future<int> saveReturn(ReturnOrder returnOrder) async {
    final id = await _db.insert('return_orders', returnOrder.toMap());
    await refresh();
    return id;
  }

  Future<void> updateReturn(ReturnOrder returnOrder) async {
    await _db.update(
      'return_orders',
      returnOrder.toMap(),
      where: 'id = ?',
      whereArgs: [returnOrder.id],
    );
    await refresh();
  }

  Future<void> deleteReturn(int id) async {
    await _db.delete('return_orders', where: 'id = ?', whereArgs: [id]);
    await refresh();
  }

  Future<void> completeReturn(ReturnOrder returnOrder, Map<int, int> stockChanges) async {
    await _db.update(
      'return_orders',
      {'status': 'completed', 'complete_time': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [returnOrder.id],
    );
    // 调整库存
    for (final entry in stockChanges.entries) {
      await _db.rawUpdate(
        'UPDATE products SET stock = stock + ? WHERE id = ?',
        [entry.value, entry.key],
      );
    }
    await refresh();
  }

  Future<void> refresh() async {
    await _loadReturns();
    notifyListeners();
  }
}
```

- [ ] **Step 2: 在 main.dart 中注册 Provider**

修改 `lib/main.dart`：

```dart
providers: [
  ChangeNotifierProvider(create: (_) => ProductProvider()..init()),
  ChangeNotifierProvider(create: (_) => CustomerProvider()..init()),
  ChangeNotifierProvider(create: (_) => OrderProvider()..init()),
  ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
  ChangeNotifierProvider(create: (_) => CategoryProvider()..init()),
  ChangeNotifierProvider(create: (_) => WarehouseProvider()..init()),
  ChangeNotifierProvider(create: (_) => PurchaseProvider()..init()),
  ChangeNotifierProvider(create: (_) => ReturnProvider()..init()),
],
```

- [ ] **Step 3: 运行测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 4: 提交**

```bash
git add lib/core/providers/return_provider.dart lib/main.dart
git commit -m "feat: add ReturnProvider for return order management"
```

---

## Phase 5: UI 页面

### Task 13: 新增商品分类管理页面

**Files:**
- Create: `lib/features/products/category_list_page.dart`
- Create: `lib/features/products/category_edit_page.dart`
- Modify: `lib/features/products/product_list_page.dart`

- [ ] **Step 1: 创建分类列表页面**

创建 `lib/features/products/category_list_page.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/category.dart';
import '../../core/providers/category_provider.dart';
import '../../widgets/common/widgets.dart';
import 'category_edit_page.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('商品分类'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryEditPage()),
            ),
          ),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          if (provider.loading) return const LoadingIndicator();
          if (provider.categories.isEmpty) {
            return const EmptyState(
              icon: Icons.category_outlined,
              message: '暂无分类，点击右上角添加',
            );
          }
          return ListView.builder(
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final category = provider.categories[index];
              return ListTile(
                leading: const Icon(Icons.category),
                title: Text(category.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryEditPage(category: category),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: 创建分类编辑页面**

创建 `lib/features/products/category_edit_page.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/category.dart';
import '../../core/providers/category_provider.dart';

class CategoryEditPage extends StatefulWidget {
  final Category? category;
  const CategoryEditPage({super.key, this.category});

  @override
  State<CategoryEditPage> createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage> {
  late TextEditingController _nameController;
  bool _saving = false;

  bool get isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final provider = context.read<CategoryProvider>();
      if (isEdit) {
        await provider.updateCategory(
          widget.category!.copyWith(name: _nameController.text.trim()),
        );
      } else {
        await provider.addCategory(Category(name: _nameController.text.trim()));
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '编辑分类' : '新增分类'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '分类名称',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? '保存中...' : '保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: 在商品列表中添加分类入口**

修改 `lib/features/products/product_list_page.dart`，在 AppBar actions 中添加分类按钮。

- [ ] **Step 4: 运行测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 5: 提交**

```bash
git add lib/features/products/category_list_page.dart lib/features/products/category_edit_page.dart
git commit -m "feat: add category management UI pages"
```

---

### Task 14: 新增采购开单页面

**Files:**
- Create: `lib/features/purchases/purchase_list_page.dart`
- Create: `lib/features/purchases/purchase_create_page.dart`

- [ ] **Step 1: 创建采购列表页面**

创建 `lib/features/purchases/purchase_list_page.dart`（类似 order_list_page.dart 结构）

- [ ] **Step 2: 创建采购开单页面**

创建 `lib/features/purchases/purchase_create_page.dart`（类似 order_create_page.dart 结构）

- [ ] **Step 3: 在 main.dart 添加采购 Tab 或入口**

- [ ] **Step 4: 运行测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 5: 提交**

```bash
git add lib/features/purchases/
git commit -m "feat: add purchase order UI pages"
```

---

### Task 15: 新增退货页面

**Files:**
- Create: `lib/features/returns/return_list_page.dart`
- Create: `lib/features/returns/return_create_page.dart`

- [ ] **Step 1: 创建退货列表页面**

- [ ] **Step 2: 创建退货开单页面**

- [ ] **Step 3: 运行测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 4: 提交**

```bash
git add lib/features/returns/
git commit -m "feat: add return order UI pages"
```

---

### Task 16: 新增库存盘点页面

**Files:**
- Create: `lib/features/inventory/inventory_check_list_page.dart`
- Create: `lib/features/inventory/inventory_check_page.dart`

- [ ] **Step 1: 创建盘点列表页面**

- [ ] **Step 2: 创建盘点执行页面**

- [ ] **Step 3: 运行测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 4: 提交**

```bash
git add lib/features/inventory/
git commit -m "feat: add inventory check UI pages"
```

---

### Task 17: 新增对账单页面

**Files:**
- Create: `lib/features/statistics/reconciliation_page.dart`

- [ ] **Step 1: 创建客户对账单页面**

- [ ] **Step 2: 运行测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 3: 提交**

```bash
git add lib/features/statistics/reconciliation_page.dart
git commit -m "feat: add customer reconciliation statement page"
```

---

### Task 18: 新增仓库管理页面

**Files:**
- Create: `lib/features/settings/warehouse_list_page.dart`
- Create: `lib/features/settings/warehouse_edit_page.dart`

- [ ] **Step 1: 创建仓库列表页面**

- [ ] **Step 2: 创建仓库编辑页面**

- [ ] **Step 3: 运行测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 4: 提交**

```bash
git add lib/features/settings/warehouse_list_page.dart lib/features/settings/warehouse_edit_page.dart
git commit -m "feat: add warehouse management UI pages"
```

---

### Task 19: 增强商品编辑页面

**Files:**
- Modify: `lib/features/products/product_edit_page.dart`

- [ ] **Step 1: 添加分类选择**

- [ ] **Step 2: 添加成本价输入**

- [ ] **Step 3: 添加最低库存输入**

- [ ] **Step 4: 添加条码输入**

- [ ] **Step 5: 添加商品图片选择**

- [ ] **Step 6: 运行测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 7: 提交**

```bash
git add lib/features/products/product_edit_page.dart
git commit -m "feat: enhance product edit page with new fields"
```

---

### Task 20: 增强客户编辑页面

**Files:**
- Modify: `lib/features/customers/customer_edit_page.dart`

- [ ] **Step 1: 添加客户分级选择**

- [ ] **Step 2: 添加信用额度输入**

- [ ] **Step 3: 添加账期天数输入**

- [ ] **Step 4: 运行测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 5: 提交**

```bash
git add lib/features/customers/customer_edit_page.dart
git commit -m "feat: enhance customer edit page with tier and credit fields"
```

---

### Task 21: 新增库存预警功能

**Files:**
- Modify: `lib/core/providers/product_provider.dart`
- Create: `lib/features/statistics/inventory_alert_page.dart`

- [ ] **Step 1: 在 ProductProvider 中添加库存预警查询**

```dart
List<Product> get lowStockProducts {
  return _products.where((p) => p.minStock > 0 && p.stock <= p.minStock).toList();
}
```

- [ ] **Step 2: 创建库存预警页面**

- [ ] **Step 3: 在仪表盘添加预警入口**

- [ ] **Step 4: 运行测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 5: 提交**

```bash
git add lib/core/providers/product_provider.dart lib/features/statistics/inventory_alert_page.dart
git commit -m "feat: add inventory alert for low stock products"
```

---

### Task 22: 新增员工权限管理

**Files:**
- Modify: `lib/core/database/database_helper.dart`
- Modify: `lib/core/models/employee.dart` (if exists)
- Create: `lib/features/settings/employee_list_page.dart`
- Create: `lib/features/settings/employee_edit_page.dart`

- [ ] **Step 1: 增强 employees 表**

在 `_createDB` 中修改 employees 表：

```dart
await db.execute('''
  CREATE TABLE employees (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    phone TEXT,
    password TEXT,
    role TEXT DEFAULT '操作员',
    permissions TEXT,
    is_active INTEGER DEFAULT 1,
    create_time TEXT NOT NULL
  )
''');
```

- [ ] **Step 2: 创建员工管理页面**

- [ ] **Step 3: 添加登录页面（简化版）**

- [ ] **Step 4: 运行测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 5: 提交**

```bash
git add lib/core/database/database_helper.dart lib/features/settings/employee_list_page.dart lib/features/settings/employee_edit_page.dart
git commit -m "feat: add employee permission management"
```

---

### Task 23: 新增会员营销功能

**Files:**
- Create: `lib/core/models/member.dart`
- Create: `lib/features/members/member_list_page.dart`
- Create: `lib/features/members/member_edit_page.dart`

- [ ] **Step 1: 创建 members 表**

```dart
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
```

- [ ] **Step 2: 创建 Member 模型**

- [ ] **Step 3: 创建会员管理页面**

- [ ] **Step 4: 运行测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 5: 提交**

```bash
git add lib/core/database/database_helper.dart lib/core/models/member.dart lib/features/members/
git commit -m "feat: add member management for loyalty program"
```

---

### Task 24: 新增自定义打印模板

**Files:**
- Modify: `lib/core/providers/settings_provider.dart`
- Modify: `lib/features/printing/print_preview_page.dart`
- Create: `lib/features/settings/print_template_page.dart`

- [ ] **Step 1: 在 SettingsProvider 中添加模板配置**

```dart
String _printTemplate = 'default';
String get printTemplate => _printTemplate;
Future<void> setPrintTemplate(String v) async { _printTemplate = v; await _save('print_template', v); notifyListeners(); }
```

- [ ] **Step 2: 创建打印模板选择页面**

- [ ] **Step 3: 修改打印预览支持模板切换**

- [ ] **Step 4: 运行测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 5: 提交**

```bash
git add lib/core/providers/settings_provider.dart lib/features/printing/print_preview_page.dart lib/features/settings/print_template_page.dart
git commit -m "feat: add custom print template support"
```

---

## 验证计划

完成所有任务后：

1. **运行全部测试**
   ```bash
   flutter test
   ```
   Expected: All tests pass

2. **静态分析**
   ```bash
   flutter analyze
   ```
   Expected: No new errors

3. **手动测试清单**
   - [ ] 创建商品分类
   - [ ] 创建商品并选择分类
   - [ ] 创建仓库
   - [ ] 创建采购订单并入库
   - [ ] 创建销售订单
   - [ ] 创建销售退货
   - [ ] 执行库存盘点
   - [ ] 查看客户对账单
   - [ ] 查看库存预警
   - [ ] 管理员工权限
   - [ ] 管理会员
   - [ ] 切换打印模板
   - [ ] 测试 WebDAV 备份

4. **提交最终版本**
   ```bash
   git add .
   git commit -m "feat: complete feature expansion - purchase, returns, categories, SKU, multi-warehouse, inventory alerts, reconciliation, stocktaking, print templates, employee permissions, members"
   ```
