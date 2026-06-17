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
  final String type;
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
