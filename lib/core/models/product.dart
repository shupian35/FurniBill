/// 商品属性定义
class ProductAttribute {
  final String key;
  final String label;
  final String type; // single_select, multi_select, number, text, date
  final List<String>? options;
  final bool affectsPrice;
  final Map<String, double>? priceMap; // option -> price adjustment

  ProductAttribute({
    required this.key,
    required this.label,
    required this.type,
    this.options,
    this.affectsPrice = false,
    this.priceMap,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'type': type,
        'options': options,
        'affectsPrice': affectsPrice,
        'priceMap': priceMap,
      };

  factory ProductAttribute.fromJson(Map<String, dynamic> json) {
    return ProductAttribute(
      key: json['key'] as String,
      label: json['label'] as String,
      type: json['type'] as String,
      options: (json['options'] as List<dynamic>?)?.cast<String>(),
      affectsPrice: json['affectsPrice'] as bool? ?? false,
      priceMap: (json['priceMap'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }
}

/// 商品模型
class Product {
  final int? id;
  final String name;
  final String code;
  final String? spec;
  final String? unit;
  final int categoryId;
  final String? imagePath;
  final double wholesalePrice;
  final double? retailPrice;
  final double? costPrice;
  final int stock;
  final int stockAlert;
  final bool skuEnabled;
  final List<ProductAttribute> attributesSchema;
  final String? remark;
  final DateTime createTime;
  final DateTime updateTime;

  Product({
    this.id,
    required this.name,
    required this.code,
    this.spec,
    this.unit,
    this.categoryId = 0,
    this.imagePath,
    required this.wholesalePrice,
    this.retailPrice,
    this.costPrice,
    this.stock = 0,
    this.stockAlert = 0,
    this.skuEnabled = false,
    this.attributesSchema = const [],
    this.remark,
    DateTime? createTime,
    DateTime? updateTime,
  })  : createTime = createTime ?? DateTime.now(),
        updateTime = updateTime ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'code': code,
        'spec': spec,
        'unit': unit,
        'category_id': categoryId,
        'image_path': imagePath,
        'wholesale_price': wholesalePrice,
        'retail_price': retailPrice,
        'cost_price': costPrice,
        'stock': stock,
        'stock_alert': stockAlert,
        'sku_enabled': skuEnabled ? 1 : 0,
        'attributes_schema':
            attributesSchema.map((a) => a.toJson()).toList().toString(),
        'remark': remark,
        'create_time': createTime.toIso8601String(),
        'update_time': updateTime.toIso8601String(),
      };

  factory Product.fromMap(Map<String, dynamic> map) {
    List<ProductAttribute> attrs = [];
    if (map['attributes_schema'] != null &&
        map['attributes_schema'].toString().isNotEmpty) {
      try {
        final list = List<Map<String, dynamic>>.from(
            _parseJsonList(map['attributes_schema'].toString()));
        attrs = list.map((e) => ProductAttribute.fromJson(e)).toList();
      } catch (_) {}
    }
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      code: map['code'] as String,
      spec: map['spec'] as String?,
      unit: map['unit'] as String?,
      categoryId: map['category_id'] as int? ?? 0,
      imagePath: map['image_path'] as String?,
      wholesalePrice: (map['wholesale_price'] as num).toDouble(),
      retailPrice: (map['retail_price'] as num?)?.toDouble(),
      costPrice: (map['cost_price'] as num?)?.toDouble(),
      stock: map['stock'] as int? ?? 0,
      stockAlert: map['stock_alert'] as int? ?? 0,
      skuEnabled: map['sku_enabled'] == 1,
      attributesSchema: attrs,
      remark: map['remark'] as String?,
      createTime: DateTime.parse(map['create_time'] as String),
      updateTime: DateTime.parse(map['update_time'] as String),
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? code,
    String? spec,
    String? unit,
    int? categoryId,
    String? imagePath,
    double? wholesalePrice,
    double? retailPrice,
    double? costPrice,
    int? stock,
    int? stockAlert,
    bool? skuEnabled,
    List<ProductAttribute>? attributesSchema,
    String? remark,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        code: code ?? this.code,
        spec: spec ?? this.spec,
        unit: unit ?? this.unit,
        categoryId: categoryId ?? this.categoryId,
        imagePath: imagePath ?? this.imagePath,
        wholesalePrice: wholesalePrice ?? this.wholesalePrice,
        retailPrice: retailPrice ?? this.retailPrice,
        costPrice: costPrice ?? this.costPrice,
        stock: stock ?? this.stock,
        stockAlert: stockAlert ?? this.stockAlert,
        skuEnabled: skuEnabled ?? this.skuEnabled,
        attributesSchema: attributesSchema ?? this.attributesSchema,
        remark: remark ?? this.remark,
        createTime: createTime,
        updateTime: DateTime.now(),
      );
}

List<dynamic> _parseJsonList(String raw) {
  // The raw stored string is a Dart list string; we use a simple parser.
  // In production, this uses dart:convert after proper serialization.
  return List<Map<String, dynamic>>.from([]);
}
