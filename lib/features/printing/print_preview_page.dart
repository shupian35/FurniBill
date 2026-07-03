import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../../core/models/order.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/print_service.dart';

/// 打印预览页 - UI 壳
///
/// 业务逻辑（PDF 渲染、字体加载、中文大写金额、三联单）已全部抽到
/// [PrintService]。本类只剩 30 行：搭一个 PdfPreview，把订单 + 设置丢给
/// service 拿回字节流，交给 printing 插件展示。
class PrintPreviewPage extends StatelessWidget {
  final Order order;
  const PrintPreviewPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final printService = const PrintService();
    return Scaffold(
      appBar: AppBar(title: const Text('打印预览')),
      body: PdfPreview(
        build: (format) => printService.buildPdf(order, settings, format: format),
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}
