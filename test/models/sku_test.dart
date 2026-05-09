import 'package:flutter_test/flutter_test.dart';
import 'package:furni_bill/core/models/sku.dart';

void main() {
  group('Sku', () {
    final sampleSku = Sku(
      id: 1,
      productId: 10,
      attrs: {'颜色': '红色', '尺寸': '1.8m'},
      attrsSummary: '红色 / 1.8m',
      price: 3800.0,
      stock: 8,
      barcode: '6901234567890',
    );

    test('toMap / fromMap roundtrip', () {
      final map = sampleSku.toMap();
      final restored = Sku.fromMap(map);

      expect(restored.id, 1);
      expect(restored.productId, 10);
      expect(restored.attrs, {'颜色': '红色', '尺寸': '1.8m'});
      expect(restored.attrsSummary, '红色 / 1.8m');
      expect(restored.price, 3800.0);
      expect(restored.stock, 8);
      expect(restored.barcode, '6901234567890');
    });

    test('default stock is 0', () {
      final sku = Sku(
        productId: 1,
        attrs: {'颜色': '蓝色'},
        attrsSummary: '蓝色',
        price: 500.0,
      );

      expect(sku.stock, 0);
      expect(sku.barcode, isNull);
    });

    test('id is null for new sku', () {
      final sku = Sku(
        productId: 1,
        attrs: {'材质': '实木'},
        attrsSummary: '实木',
        price: 1200.0,
      );
      expect(sku.id, isNull);
    });

    test('fromMap handles empty attrs', () {
      final map = <String, dynamic>{
        'id': 1,
        'product_id': 2,
        'attrs': '{}',
        'attrs_summary': '',
        'price': 100.0,
        'stock': 0,
        'barcode': null,
        'create_time': DateTime.now().toIso8601String(),
      };
      final sku = Sku.fromMap(map);
      expect(sku.attrs, isEmpty);
    });
  });
}
