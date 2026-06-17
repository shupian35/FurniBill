import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webdav_client/webdav_client.dart';
import '../../core/database/database_helper.dart';
import '../../core/providers/settings_provider.dart';

class WebdavPage extends StatefulWidget {
  const WebdavPage({super.key});

  @override
  State<WebdavPage> createState() => _WebdavPageState();
}

class _WebdavPageState extends State<WebdavPage> {
  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _testing = false;
  bool _backingUp = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>();
    _urlCtrl.text = s.webdavUrl;
    _userCtrl.text = s.webdavUser;
    _passwordCtrl.text = s.webdavPassword;
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    final s = context.read<SettingsProvider>();
    await s.setWebdavUrl(_urlCtrl.text.trim());
    await s.setWebdavUser(_userCtrl.text.trim());
    await s.setWebdavPassword(_passwordCtrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('配置已保存')));
    }
  }

  Future<void> _testConnection() async {
    setState(() => _testing = true);
    try {
      final s = context.read<SettingsProvider>();
      final client = newClient(
        s.webdavUrl,
        user: s.webdavUser,
        password: s.webdavPassword,
      );
      await client.ping();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('连接成功')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('连接失败: $e'), backgroundColor: Colors.red));
      }
    }
    setState(() => _testing = false);
  }

  Future<void> _backup() async {
    setState(() => _backingUp = true);
    try {
      final s = context.read<SettingsProvider>();
      final client = newClient(
        s.webdavUrl,
        user: s.webdavUser,
        password: s.webdavPassword,
      );

      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      final now = DateTime.now();
      final fileName =
          'furni_bill_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.db';

      await client.writeFromFile(dbPath, '/$fileName');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('备份完成: $fileName')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('备份失败: $e'), backgroundColor: Colors.red));
      }
    }
    setState(() => _backingUp = false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('WebDAV 备份同步')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('服务器配置', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'WebDAV 地址',
                    border: OutlineInputBorder(),
                    hintText: 'https://dav.jianguoyun.com/dav/',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: _userCtrl, decoration: const InputDecoration(labelText: '用户名', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _passwordCtrl, decoration: const InputDecoration(labelText: '密码', border: OutlineInputBorder()), obscureText: true),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: _saveConfig, child: const Text('保存配置'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: _testing ? null : _testConnection,
                      child: _testing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('测试连接'),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('备份与恢复', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('数据库文件将被加密打包上传至 WebDAV。', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _backingUp ? null : _backup,
                  icon: _backingUp
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cloud_upload),
                  label: Text(_backingUp ? '备份中...' : '手动备份'),
                  style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('恢复功能 - 选择云端备份文件')));
                  },
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('从云端恢复'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('自动备份'),
            subtitle: const Text('每次开单后自动备份'),
            value: settings.autoBackup,
            onChanged: settings.setAutoBackup,
          ),
          if (settings.autoBackup)
            ListTile(
              title: const Text('备份频率'),
              trailing: DropdownButton<String>(
                value: settings.backupFrequency,
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('每日')),
                  DropdownMenuItem(value: 'weekly', child: Text('每周')),
                ],
                onChanged: (v) => settings.setBackupFrequency(v!),
              ),
            ),
        ],
      ),
    );
  }
}
