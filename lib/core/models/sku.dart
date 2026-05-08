/// SKU 模型
class Sku {
  final int? id;
  final int productId;
  final Map<String, String> attrs; // {"颜色":"红色","尺寸":"1.8m"}
  final String attrsSummary; // 红色 / 1.8m
  final double price;
  final int stock;
  final String? barcode;
  final DateTime createTime;

  Sku({
    this.id,
    required this.productId,
    required this.attrs,
    required this.attrsSummary,
    required this.price,
    this.stock = 0,
    this.barcode,
    DateTime? createTime,
  }) : createTime = createTime ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'product_id': productId,
        'attrs': attrs.toString(),
        'attrs_summary': attrsSummary,
        'price': price,
        'stock': stock,
        'barcode': barcode,
        'create_time': createTime.toIso8601String(),
      };

  factory Sku.fromMap(Map<String, dynamic> map) {
    Map<String, String> attrsMap = {};
    final raw = map['attrs']?.toString() ?? '';
    if (raw.isNotEmpty) {
      // Parse "{key: value, ...}" format
      final trimmed = raw.substring(1, raw.length - 1);
      for (final part in trimmed.split(', ')) {
        final kv = part.split(': ');
        if (kv.length == 2) {
          attrsMap[kv[0]] = kv[1];
        }
      }
    }
    return Sku(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      attrs: attrsMap,
      attrsSummary: map['attrs_summary'] as String? ?? '',
      price: (map['price'] as num).toDouble(),
      stock: map['stock'] as int? ?? 0,
      barcode: map['barcode'] as String?,
      createTime: DateTime.parse(map['create_time'] as String),
    );
  }
}
