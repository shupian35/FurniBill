/// 商品模型
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
