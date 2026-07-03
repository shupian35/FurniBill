import 'package:flutter_test/flutter_test.dart';
import 'package:furni_bill/core/services/order_calculator.dart';
import 'package:furni_bill/features/orders/widgets/order_create_models.dart';
import 'package:furni_bill/core/models/order.dart';

void main() {
  const calc = OrderCalculator();

  group('totalAmount', () {
    test('空明细返回 0', () {
      expect(calc.totalAmount([]), 0.0);
    });

    test('单条：price*quantity*discount', () {
      final items = [OrderItemData(name: 'a', price: 100, quantity: 2, discount: 0.9)];
      expect(calc.totalAmount(items), closeTo(180.0, 1e-9));
    });

    test('多条累加', () {
      final items = [
        OrderItemData(name: 'a', price: 100, quantity: 2, discount: 1.0),
        OrderItemData(name: 'b', price: 50, quantity: 3, discount: 0.5),
      ];
      expect(calc.totalAmount(items), closeTo(275.0, 1e-9));
    });
  });

  group('discountAmount', () {
    test('100% 折扣时为 0', () {
      expect(calc.discountAmount(100, 1.0), 0.0);
    });

    test('9 折：total*0.1', () {
      expect(calc.discountAmount(100, 0.9), closeTo(10.0, 1e-9));
    });
  });

  group('afterDiscount', () {
    test('10 折：不变', () {
      expect(calc.afterDiscount(100, 1.0), 100.0);
    });

    test('9 折：打 9 折', () {
      expect(calc.afterDiscount(100, 0.9), closeTo(90.0, 1e-9));
    });
  });

  group('receivable', () {
    test('无抹零等于 afterDiscount', () {
      expect(calc.receivable(100, 0), 100.0);
    });

    test('抹零 0.3 应收 99.7', () {
      expect(calc.receivable(100, 0.3), closeTo(99.7, 1e-9));
    });
  });

  group('owing', () {
    test('实收 = 应收：欠款 0', () {
      expect(calc.owing(100, 100), 0.0);
    });

    test('实收 0：全额欠款', () {
      expect(calc.owing(100, 0), 100.0);
    });

    test('实收大于应收：负数（找零）', () {
      expect(calc.owing(100, 150), -50.0);
    });
  });

  group('compute (一次性算完)', () {
    test('正常场景：100 元 9 折抹零 0.3 实收 89.7', () {
      final items = [OrderItem(productId: 1, name: 'a', quantity: 1, price: 100, discount: 1.0, amount: 100)];
      final t = calc.compute(items: items, orderDiscount: 0.9, roundOff: 0.3, received: 89.7);
      expect(t.totalAmount, 100.0);
      expect(t.discountAmount, closeTo(10.0, 1e-9));
      expect(t.receivable, closeTo(89.7, 1e-9));
      expect(t.received, 89.7);
      expect(t.owing, 0.0);
    });

    test('全免：100% 折扣 + 抹零 = 0 应收', () {
      final items = [OrderItem(productId: 1, name: 'a', quantity: 1, price: 100, discount: 1.0, amount: 100)];
      final t = calc.compute(items: items, orderDiscount: 1.0, roundOff: 0, received: 0);
      expect(t.discountAmount, 0.0);
      expect(t.receivable, 100.0);
      expect(t.owing, 100.0);
    });
  });
}
