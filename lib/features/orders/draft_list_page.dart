import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/providers/order_provider.dart';
import '../../widgets/common/widgets.dart';
import 'order_create_page.dart';

class DraftListPage extends StatelessWidget {
  const DraftListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        final drafts = provider.drafts;
        if (drafts.isEmpty) {
          return EmptyState(
            icon: Icons.bookmark_border,
            message: '暂无草稿',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: drafts.length,
          itemBuilder: (context, index) {
            final d = drafts[index];
            return Slidable(
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) => provider.deleteOrder(d.id!),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    icon: Icons.delete_outline,
                    label: '删除',
                  ),
                ],
              ),
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: Text(d.orderNo, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (d.customerName != null) Text(d.customerName!),
                      Row(children: [
                        Text('${d.items.length}种'),
                        const SizedBox(width: 16),
                        AmountText(amount: d.totalAmount),
                        const SizedBox(width: 8),
                        Text(d.createTime.toString().substring(5, 16),
                            style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12)),
                      ]),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => OrderCreatePage(draft: d)),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
