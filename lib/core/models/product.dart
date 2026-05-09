/// 商品模型
class Product {
  final int? id;
  final String name;
  final String? spec;
  final String? unit;
  final double price;
  final int stock;
  final DateTime createTime;
  final DateTime updateTime;

  Product({
    this.id,
    required this.name,
    this.spec,
    this.unit,
    required this.price,
    this.stock = 0,
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
        'stock': stock,
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
      stock: map['stock'] as int? ?? 0,
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
    int? stock,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        spec: spec ?? this.spec,
        unit: unit ?? this.unit,
        price: price ?? this.price,
        stock: stock ?? this.stock,
        createTime: createTime,
        updateTime: DateTime.now(),
      );
}
