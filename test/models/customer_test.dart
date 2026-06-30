import 'package:flutter_test/flutter_test.dart';
import 'package:furni_bill/core/models/customer.dart';

void main() {
  group('Customer', () {
    final sampleCustomer = Customer(
      id: 1,
      name: '张老板',
      phone: '13800138000',
      address: '佛山市顺德区乐从镇',
    );

    test('toMap / fromMap roundtrip', () {
      final map = sampleCustomer.toMap();
      final restored = Customer.fromMap(map);

      expect(restored.id, 1);
      expect(restored.name, '张老板');
      expect(restored.phone, '13800138000');
      expect(restored.address, '佛山市顺德区乐从镇');
    });

    test('address can be null', () {
      final customer = Customer(name: '新客户', phone: '13900000000');
      expect(customer.address, isNull);
    });

    test('copyWith updates specific fields', () {
      final updated = sampleCustomer.copyWith(name: '李老板', address: '广州市白云区');

      expect(updated.name, '李老板');
      expect(updated.address, '广州市白云区');
      expect(updated.id, 1);
      expect(updated.phone, '13800138000');
    });

    test('copyWith preserves createTime', () {
      final updated = sampleCustomer.copyWith(name: '新名字');
      expect(updated.createTime, sampleCustomer.createTime);
    });

    test('id is null for new entities', () {
      final customer = Customer(name: '临时', phone: '10086');
      expect(customer.id, isNull);
      final map = customer.toMap();
      expect(map.containsKey('id'), false);
    });
  });
}
