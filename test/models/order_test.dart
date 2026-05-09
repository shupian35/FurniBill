import 'package:flutter_test/flutter_test.dart';
import 'package:furni_bill/core/models/order.dart';

void main() {
  group('OrderItem', () {
    test('toJson / fromJson roundtrip', () {
      final item = OrderItem(
        productId: 1,
        name: '真皮沙发',
        specSummary: '棕色 / 三人位',
        quantity: 2,
        price: 3500.0,
        discount: 0.9,
        remark: '加急',
      );

      final json = item.toJson();
      final restored = OrderItem.fromJson(json);

      expect(restored.productId, 1);
      expect(restored.name, '真皮沙发');
      expect(restored.specSummary, '棕色 / 三人位');
      expect(restored.quantity, 2.0);
      expect(restored.price, 3500.0);
      expect(restored.discount, 0.9);
      expect(restored.amount, 2 * 3500.0 * 0.9); // 6300.0
      expect(restored.remark, '加急');
    });

    test('amount is calculated automatically', () {
      final item = OrderItem(
        productId: 1,
        name: '餐桌',
        quantity: 3,
        price: 1200.0,
      );
      expect(item.amount, 3 * 1200.0 * 1.0); // 3600.0
    });

    test('explicit amount overrides calculation', () {
      final item = OrderItem(
        productId: 1,
        name: '茶几',
        quantity: 1,
        price: 800.0,
        amount: 750.0, // 手动优惠后
      );
      expect(item.amount, 750.0);
    });

    test('optional fields can be null', () {
      final item = OrderItem(
        name: '临时商品',
        quantity: 1,
        price: 100.0,
      );

      expect(item.productId, isNull);
      expect(item.skuId, isNull);
      expect(item.specSummary, isNull);
      expect(item.remark, isNull);
    });

    test('default discount is 1.0', () {
      final item = OrderItem(
        productId: 5,
        name: '书桌',
        quantity: 1,
        price: 500.0,
      );
      expect(item.discount, 1.0);
      expect(item.amount, 500.0);
    });
  });

  group('Order', () {
    final sampleItems = [
      OrderItem(productId: 1, name: '沙发', quantity: 1, price: 3500.0),
      OrderItem(productId: 2, name: '茶几', quantity: 2, price: 800.0),
    ];

    final sampleOrder = Order(
      id: 1,
      orderNo: 'FB20260509120000',
      customerId: 1,
      customerName: '张老板',
      items: sampleItems,
      totalAmount: 5100.0,
      orderDiscount: 0.95,
      discountAmount: 255.0,
      roundOff: 4.0,
      receivable: 4841.0,
      received: 4841.0,
      owing: 0.0,
      status: 'completed',
      clerk: '小李',
      paymentMethod: '微信',
      isDraft: false,
    );

    test('itemCount sums quantities correctly', () {
      expect(sampleOrder.itemCount, 1 + 2); // 3
    });

    test('itemCount with empty items', () {
      final order = Order(
        orderNo: 'FB0001',
        customerId: 1,
        items: [],
      );
      expect(order.itemCount, 0);
    });

    test('toMap / fromMap roundtrip', () {
      final map = sampleOrder.toMap();
      final restored = Order.fromMap(map);

      expect(restored.id, 1);
      expect(restored.orderNo, 'FB20260509120000');
      expect(restored.customerId, 1);
      expect(restored.customerName, '张老板');
      expect(restored.totalAmount, 5100.0);
      expect(restored.orderDiscount, 0.95);
      expect(restored.discountAmount, 255.0);
      expect(restored.roundOff, 4.0);
      expect(restored.receivable, 4841.0);
      expect(restored.received, 4841.0);
      expect(restored.owing, 0.0);
      expect(restored.status, 'completed');
      expect(restored.clerk, '小李');
      expect(restored.paymentMethod, '微信');
      expect(restored.isDraft, false);
    });

    test('default values for new order', () {
      final order = Order(
        orderNo: 'FB001',
        customerId: 2,
      );

      expect(order.items, isEmpty);
      expect(order.totalAmount, 0.0);
      expect(order.orderDiscount, 1.0);
      expect(order.discountAmount, 0.0);
      expect(order.roundOff, 0.0);
      expect(order.receivable, 0.0);
      expect(order.received, 0.0);
      expect(order.owing, 0.0);
      expect(order.status, 'draft');
      expect(order.isDraft, true);
      expect(order.completeTime, isNull);
    });

    test('draft flag in toMap', () {
      final draft = Order(orderNo: 'FB001', customerId: 1, isDraft: true);
      expect(draft.toMap()['is_draft'], 1);

      final completed = Order(orderNo: 'FB002', customerId: 1, isDraft: false);
      expect(completed.toMap()['is_draft'], 0);
    });

    test('fromMap handles null completeTime', () {
      final map = sampleOrder.toMap();
      final restored = Order.fromMap(map);
      expect(restored.completeTime, isNull);
    });

    test('fromMap handles empty items', () {
      final map = sampleOrder.toMap();
      map['items'] = '[]';
      final restored = Order.fromMap(map);
      expect(restored.items, isEmpty);
    });
  });
}
