import 'package:flutter_test/flutter_test.dart';
import 'package:furni_bill/core/models/payment.dart';

void main() {
  group('Payment', () {
    final samplePayment = Payment(
      id: 1,
      orderId: 10,
      customerId: 5,
      amount: 3500.0,
      method: '微信',
      remark: '尾款',
    );

    test('toMap / fromMap roundtrip', () {
      final map = samplePayment.toMap();
      final restored = Payment.fromMap(map);

      expect(restored.id, 1);
      expect(restored.orderId, 10);
      expect(restored.customerId, 5);
      expect(restored.amount, 3500.0);
      expect(restored.method, '微信');
      expect(restored.remark, '尾款');
    });

    test('id is null for new payment', () {
      final payment = Payment(
        orderId: 1,
        customerId: 1,
        amount: 100.0,
        method: '现金',
      );
      expect(payment.id, isNull);
    });

    test('remark is optional', () {
      final payment = Payment(
        orderId: 1,
        customerId: 1,
        amount: 500.0,
        method: '转账',
      );
      expect(payment.remark, isNull);
    });

    test('createTime auto-generated', () {
      final before = DateTime.now();
      final payment = Payment(
        orderId: 1,
        customerId: 1,
        amount: 200.0,
        method: '支付宝',
      );
      final after = DateTime.now();

      expect(
        payment.createTime.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        payment.createTime.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });
  });
}
