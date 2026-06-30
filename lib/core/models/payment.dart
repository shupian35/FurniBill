/// 收款记录
class Payment {
  final int? id;
  final int orderId;
  final int customerId;
  final double amount;
  final String method; // cash, wechat, alipay, transfer, credit
  final String? remark;
  final DateTime createTime;

  Payment({
    this.id,
    required this.orderId,
    required this.customerId,
    required this.amount,
    required this.method,
    this.remark,
    DateTime? createTime,
  }) : createTime = createTime ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'order_id': orderId,
    'customer_id': customerId,
    'amount': amount,
    'method': method,
    'remark': remark,
    'create_time': createTime.toIso8601String(),
  };

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      orderId: map['order_id'] as int,
      customerId: map['customer_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      method: map['method'] as String,
      remark: map['remark'] as String?,
      createTime: DateTime.parse(map['create_time'] as String),
    );
  }
}
