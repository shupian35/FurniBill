import 'package:flutter_test/flutter_test.dart';
import 'package:furni_bill/core/models/product.dart';

void main() {
  group('Product', () {
    final sampleProduct = Product(
      id: 1,
      name: '真皮沙发',
      spec: '三人位 2.2m',
      unit: '套',
      price: 3500.0,
      stock: 15,
    );

    test('toMap / fromMap roundtrip', () {
      final map = sampleProduct.toMap();
      final restored = Product.fromMap(map);

      expect(restored.id, 1);
      expect(restored.name, '真皮沙发');
      expect(restored.spec, '三人位 2.2m');
      expect(restored.unit, '套');
      expect(restored.price, 3500.0);
      expect(restored.stock, 15);
    });

    test('spec and unit default to null', () {
      final product = Product(name: '简单商品', price: 100.0);
      expect(product.spec, isNull);
      expect(product.unit, isNull);
    });

    test('default stock is 0', () {
      final product = Product(name: '测试', price: 50.0);
      expect(product.stock, 0);
    });

    test('copyWith updates fields', () {
      final updated = sampleProduct.copyWith(
        name: '科技布沙发',
        price: 2800.0,
        stock: 20,
      );

      expect(updated.name, '科技布沙发');
      expect(updated.price, 2800.0);
      expect(updated.stock, 20);
      expect(updated.spec, '三人位 2.2m');
      expect(updated.unit, '套');
    });

    test('copyWith preserves createTime', () {
      final updated = sampleProduct.copyWith(name: '新名称');
      expect(updated.createTime, sampleProduct.createTime);
    });

    test('id is null for new products', () {
      final product = Product(name: '新品', price: 500.0);
      expect(product.id, isNull);
      final map = product.toMap();
      expect(map.containsKey('id'), false);
    });
  });
}
