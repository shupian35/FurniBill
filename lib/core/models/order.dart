/// 订单商品明细
class OrderItem {
  int? productId;
  int? skuId;
  String name;
  String? specSummary;
  String? unit;
  double quantity;
  double price;
  double discount;
  double amount;
  String? remark;

  OrderItem({
    this.productId,
    this.skuId,
    required this.name,
    this.specSummary,
    this.unit,
    required this.quantity,
    required this.price,
    this.discount = 1.0,
    double? amount,
    this.remark,
  }) : amount = amount ?? (quantity * price * discount);

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'sku_id': skuId,
        'name': name,
        'spec_summary': specSummary,
        'unit': unit,
        'quantity': quantity,
        'price': price,
        'discount': discount,
        'amount': amount,
        'remark': remark,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] as int?,
      skuId: json['sku_id'] as int?,
      name: json['name'] as String,
      specSummary: json['spec_summary'] as String?,
      unit: json['unit'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 1.0,
      amount: (json['amount'] as num).toDouble(),
      remark: json['remark'] as String?,
    );
  }
}

/// 订单模型
class Order {
  final int? id;
  final String orderNo;
  final int customerId;
  final String? customerName;
  final List<OrderItem> items;
  final double totalAmount;
  final double orderDiscount;
  final double discountAmount;
  final double roundOff;
  final double receivable;
  final double received;
  final double owing;
  final String status; // draft, completed, cancelled
  final String? clerk;
  final String? remark;
  final String? paymentMethod;
  final bool isDraft;
  final DateTime createTime;
  final DateTime? completeTime;

  Order({
    this.id,
    required this.orderNo,
    required this.customerId,
    this.customerName,
    this.items = const [],
    this.totalAmount = 0,
    this.orderDiscount = 1.0,
    this.discountAmount = 0,
    this.roundOff = 0,
    this.receivable = 0,
    this.received = 0,
    this.owing = 0,
    this.status = 'draft',
    this.clerk,
    this.remark,
    this.paymentMethod,
    this.isDraft = true,
    DateTime? createTime,
    this.completeTime,
  }) : createTime = createTime ?? DateTime.now();

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity.toInt());

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'order_no': orderNo,
        'customer_id': customerId,
        'customer_name': customerName,
        'items': items.map((i) => i.toJson()).toList().toString(),
        'total_amount': totalAmount,
        'order_discount': orderDiscount,
        'discount_amount': discountAmount,
        'round_off': roundOff,
        'receivable': receivable,
        'received': received,
        'owing': owing,
        'status': status,
        'clerk': clerk,
        'remark': remark,
        'payment_method': paymentMethod,
        'is_draft': isDraft ? 1 : 0,
        'create_time': createTime.toIso8601String(),
        'complete_time': completeTime?.toIso8601String(),
      };

  factory Order.fromMap(Map<String, dynamic> map) {
    List<OrderItem> parsedItems = [];
    final raw = map['items']?.toString() ?? '';
    if (raw.isNotEmpty && raw != '[]') {
      try {
        final list = _parseOrderItems(raw);
        parsedItems = list;
      } catch (_) {}
    }
    return Order(
      id: map['id'] as int?,
      orderNo: map['order_no'] as String,
      customerId: map['customer_id'] as int,
      customerName: map['customer_name'] as String?,
      items: parsedItems,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      orderDiscount: (map['order_discount'] as num?)?.toDouble() ?? 1.0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      roundOff: (map['round_off'] as num?)?.toDouble() ?? 0,
      receivable: (map['receivable'] as num?)?.toDouble() ?? 0,
      received: (map['received'] as num?)?.toDouble() ?? 0,
      owing: (map['owing'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'draft',
      clerk: map['clerk'] as String?,
      remark: map['remark'] as String?,
      paymentMethod: map['payment_method'] as String?,
      isDraft: map['is_draft'] == 1,
      createTime: DateTime.parse(map['create_time'] as String),
      completeTime: map['complete_time'] != null
          ? DateTime.parse(map['complete_time'] as String)
          : null,
    );
  }
}

List<OrderItem> _parseOrderItems(String raw) {
  return [];
}
