import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../../core/models/member.dart';
import '../../core/providers/member_provider.dart';
import '../../widgets/common/widgets.dart';
import 'member_edit_page.dart';

class MemberListPage extends StatelessWidget {
  const MemberListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MemberProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('会员管理')),
          body: SafeArea(
            child: Column(
              children: [
                AppSearchBar(
                  hintText: '搜索会员编号/姓名/电话',
                  onChanged: provider.setSearch,
                  onClear: () => provider.setSearch(''),
                ),
                Expanded(child: _buildList(context, provider)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _navigateToEdit(context),
            tooltip: '添加会员',
            child: const Icon(Icons.person_add),
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, MemberProvider provider) {
    final members = provider.filteredMembers;
    if (provider.loading) return const LoadingIndicator();
    if (members.isEmpty) {
      return EmptyState(
        icon: Icons.badge_outlined,
        message: '暂无会员',
        actionLabel: '添加会员',
        onAction: () => _navigateToEdit(context),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: members.length,
      itemBuilder: (context, index) {
        return _MemberCard(member: members[index]);
      },
    );
  }

  void _navigateToEdit(BuildContext context, [Member? member]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MemberEditPage(member: member)),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final Member member;
  const _MemberCard({required this.member});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除会员「${member.name}」吗？\n\n此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<MemberProvider>().deleteMember(member.id!);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已删除「${member.name}」')),
              );
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Color _levelColor(String level) {
    switch (level) {
      case '金卡会员':
        return Colors.amber;
      case '银卡会员':
        return Colors.grey;
      case 'VIP会员':
        return Colors.deepPurple;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _levelColor(member.level);
    return Slidable(
      key: ValueKey(member.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _confirmDelete(context),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: '删除',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              member.name.isNotEmpty ? member.name[0] : '?',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  member.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  member.level,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 2),
              Text('编号：${member.memberNo}'),
              if (member.phone != null && member.phone!.isNotEmpty)
                Text('电话：${member.phone}'),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${member.points}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                '积分',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MemberEditPage(member: member)),
            );
          },
        ),
      ),
    );
  }
}
