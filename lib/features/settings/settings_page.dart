import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';
import 'shop_info_page.dart';
import 'print_settings_page.dart';
import '../sync/webdav_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            children: [
              // 店铺信息
              ListTile(
                leading: const Icon(Icons.store),
                title: const Text('店铺信息'),
                subtitle: Text(settings.shopName.isNotEmpty ? settings.shopName : '未设置'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopInfoPage())),
              ),
              const Divider(),
              // 打印设置
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('打印设置'),
                subtitle: Text(settings.paperType),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrintSettingsPage())),
              ),
              const Divider(),
              // 操作偏好
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text('深色模式'),
                value: settings.darkMode,
                onChanged: settings.setDarkMode,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.inventory_2_outlined),
                title: const Text('允许负库存'),
                subtitle: const Text('开启后库存不足仍可开单'),
                value: settings.negativeStock,
                onChanged: settings.setNegativeStock,
              ),
              ListTile(
                leading: const Icon(Icons.format_list_numbered),
                title: const Text('小数位数'),
                subtitle: Text('${settings.decimalPlaces} 位'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDecimalPicker(context, settings),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.volume_up),
                title: const Text('收款语音播报'),
                value: settings.voiceAnnounce,
                onChanged: settings.setVoiceAnnounce,
              ),
              const Divider(),
              // WebDAV
              ListTile(
                leading: const Icon(Icons.cloud_sync),
                title: const Text('WebDAV 备份同步'),
                subtitle: Text(settings.webdavUrl.isNotEmpty ? '已配置' : '未配置'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WebdavPage())),
              ),
              const Divider(),
              // 三联单显示选项
              SwitchListTile(
                secondary: const Icon(Icons.visibility),
                title: const Text('显示零售价'),
                subtitle: const Text('三联单中显示零售价列'),
                value: settings.showRetailPrice,
                onChanged: settings.setShowRetailPrice,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.visibility_off),
                title: const Text('显示成本价'),
                subtitle: const Text('三联单中显示成本价列'),
                value: settings.showCostPrice,
                onChanged: settings.setShowCostPrice,
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDecimalPicker(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择小数位数'),
        children: [0, 1, 2, 3].map((n) => SimpleDialogOption(
          onPressed: () {
            settings.setDecimalPlaces(n);
            Navigator.pop(ctx);
          },
          child: Text('$n 位小数', style: TextStyle(fontWeight: settings.decimalPlaces == n ? FontWeight.bold : FontWeight.normal)),
        )).toList(),
      ),
    );
  }
}
