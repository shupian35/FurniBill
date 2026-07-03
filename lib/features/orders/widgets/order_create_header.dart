import 'package:flutter/material.dart';
import '../../../core/models/customer.dart';

/// 开单页头部：客户选择卡片
class OrderCreateHeader extends StatelessWidget {
  final Customer? customer;
  final VoidCallback onTap;

  const OrderCreateHeader({super.key, required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person),
        title: Text(customer?.name ?? '选择客户'),
        subtitle: customer != null ? Text(customer!.phone) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
