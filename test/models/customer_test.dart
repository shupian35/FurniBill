import 'package:flutter_test/flutter_test.dart';
import 'package:furni_bill/core/models/customer.dart';

void main() {
  group('Customer', () {
    final sampleCustomer = Customer(
      id: 1,
      name: '张老板',
      companyName: '张氏家具城',
      phone: '13800138000',
      region: '广东省',
      address: '佛山市顺德区乐从镇',
      grade: '批发商',
      discount: 0.88,
      creditLimit: 50000.0,
      owing: 3200.0,
      remark: '老客户，月结',
    );

    test('toMap / fromMap roundtrip', () {
      final map = sampleCustomer.toMap();
      final restored = Customer.fromMap(map);

      expect(restored.id, 1);
      expect(restored.name, '张老板');
      expect(restored.companyName, '张氏家具城');
      expect(restored.phone, '13800138000');
      expect(restored.region, '广东省');
      expect(restored.address, '佛山市顺德区乐从镇');
      expect(restored.grade, '批发商');
      expect(restored.discount, 0.88);
      expect(restored.creditLimit, 50000.0);
      expect(restored.owing, 3200.0);
      expect(restored.remark, '老客户，月结');
    });

    test('default values for new customer', () {
      final customer = Customer(
        name: '新客户',
        phone: '13900000000',
      );

      expect(customer.grade, '普通');
      expect(customer.discount, 1.0);
      expect(customer.owing, 0.0);
      expect(customer.companyName, isNull);
      expect(customer.region, isNull);
      expect(customer.address, isNull);
      expect(customer.creditLimit, isNull);
      expect(customer.remark, isNull);
    });

    test('copyWith updates specific fields', () {
      final updated = sampleCustomer.copyWith(
        grade: 'VIP',
        discount: 0.95,
        owing: 0.0,
      );

      expect(updated.grade, 'VIP');
      expect(updated.discount, 0.95);
      expect(updated.owing, 0.0);
      expect(updated.id, 1);
      expect(updated.name, '张老板');
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
