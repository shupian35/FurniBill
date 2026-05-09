import 'package:flutter_test/flutter_test.dart';
import 'package:furni_bill/core/models/product.dart';

void main() {
  group('ProductAttribute', () {
    test('toJson / fromJson roundtrip', () {
      final attr = ProductAttribute(
        key: 'color',
        label: '颜色',
        type: 'single_select',
        options: ['红色', '蓝色', '白色'],
        affectsPrice: true,
        priceMap: {'红色': 100.0, '蓝色': 0.0},
      );

      final json = attr.toJson();
      final restored = ProductAttribute.fromJson(json);

      expect(restored.key, 'color');
      expect(restored.label, '颜色');
      expect(restored.type, 'single_select');
      expect(restored.options, ['红色', '蓝色', '白色']);
      expect(restored.affectsPrice, true);
      expect(restored.priceMap, {'红色': 100.0, '蓝色': 0.0});
    });

    test('defaults for optional fields', () {
      final attr = ProductAttribute(
        key: 'material',
        label: '材质',
        type: 'text',
      );

      expect(attr.options, isNull);
      expect(attr.affectsPrice, false);
      expect(attr.priceMap, isNull);
    });
  });

  group('Product', () {
    final sampleProduct = Product(
      id: 1,
      name: '真皮沙发',
      code: 'SF001',
      spec: '三人位 2.2m',
      unit: '套',
      categoryId: 1,
      wholesalePrice: 3500.0,
      retailPrice: 4500.0,
      costPrice: 2800.0,
      stock: 15,
      stockAlert: 5,
      remark: '进口头层牛皮',
    );

    test('toMap / fromMap roundtrip', () {
      final map = sampleProduct.toMap();
      final restored = Product.fromMap(map);

      expect(restored.id, 1);
      expect(restored.name, '真皮沙发');
      expect(restored.code, 'SF001');
      expect(restored.categoryId, 1);
      expect(restored.wholesalePrice, 3500.0);
      expect(restored.retailPrice, 4500.0);
      expect(restored.costPrice, 2800.0);
      expect(restored.stock, 15);
      expect(restored.stockAlert, 5);
      expect(restored.remark, '进口头层牛皮');
    });

    test('spec and unit roundtrip', () {
      final map = sampleProduct.toMap();
      final restored = Product.fromMap(map);
      expect(restored.spec, '三人位 2.2m');
      expect(restored.unit, '套');
    });

    test('spec and unit default to null', () {
      final product = Product(
        name: '简单商品',
        code: 'S001',
        wholesalePrice: 100.0,
      );
      expect(product.spec, isNull);
      expect(product.unit, isNull);
    });

    test('default values', () {
      final product = Product(
        name: '测试商品',
        code: 'T001',
        wholesalePrice: 100.0,
      );

      expect(product.categoryId, 0);
      expect(product.stock, 0);
      expect(product.stockAlert, 0);
      expect(product.skuEnabled, false);
      expect(product.attributesSchema, isEmpty);
      expect(product.imagePath, isNull);
    });

    test('copyWith updates fields', () {
      final updated = sampleProduct.copyWith(
        name: '科技布沙发',
        wholesalePrice: 2800.0,
        stock: 20,
      );

      expect(updated.id, 1);
      expect(updated.name, '科技布沙发');
      expect(updated.wholesalePrice, 2800.0);
      expect(updated.stock, 20);
      // unchanged
      expect(updated.code, 'SF001');
      expect(updated.remark, '进口头层牛皮');
    });

    test('copyWith preserves createTime', () {
      final updated = sampleProduct.copyWith(name: '新名称');
      expect(updated.createTime, sampleProduct.createTime);
    });

    test('id is null for new products', () {
      final product = Product(
        name: '新品',
        code: 'N001',
        wholesalePrice: 500.0,
      );
      expect(product.id, isNull);
      final map = product.toMap();
      expect(map.containsKey('id'), false);
    });

    test('with attributes schema', () {
      final product = Product(
        name: '多功能床',
        code: 'BD001',
        wholesalePrice: 2200.0,
        skuEnabled: true,
        attributesSchema: [
          ProductAttribute(
            key: 'size',
            label: '尺寸',
            type: 'single_select',
            options: ['1.5m', '1.8m', '2.0m'],
            affectsPrice: true,
            priceMap: {'1.5m': 0.0, '1.8m': 200.0, '2.0m': 400.0},
          ),
        ],
      );

      expect(product.skuEnabled, true);
      expect(product.attributesSchema.length, 1);
      expect(product.attributesSchema.first.key, 'size');
    });
  });
}
