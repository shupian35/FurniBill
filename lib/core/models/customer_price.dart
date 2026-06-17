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
