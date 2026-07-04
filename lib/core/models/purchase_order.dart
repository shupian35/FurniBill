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
    final raw = map['items']?.toString() ?? '';
    List<PurchaseOrderItem> parsedItems = const [];
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
