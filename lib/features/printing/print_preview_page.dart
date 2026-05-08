import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/models/order.dart';
import '../../core/providers/settings_provider.dart';
import 'package:intl/intl.dart';

class PrintPreviewPage extends StatelessWidget {
  final Order order;
  const PrintPreviewPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('三联单打印')),
      body: PdfPreview(
        build: (format) => _buildPdf(format, settings),
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }

  Future<Uint8List> _buildPdf(PdfPageFormat format, SettingsProvider settings) async {
    final pdf = pw.Document();
    final shopName = settings.shopName.isNotEmpty ? settings.shopName : '店铺名称';
    final shopPhone = settings.shopPhone.isNotEmpty ? settings.shopPhone : null;
    final shopAddress = settings.shopAddress.isNotEmpty ? settings.shopAddress : null;
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(order.completeTime ?? order.createTime);

    final colors = [PdfColors.black, PdfColors.red, PdfColors.blue];
    final labels = ['存根联(白)', '客户联(红)', '记账联(蓝)'];

    for (var i = 0; i < 3; i++) {
      final isFirst = i == 0;
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 三联标签
                if (!isFirst)
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.only(top: 10),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(color: PdfColors.grey, width: 0.5)),
                    ),
                  ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(labels[i], style: pw.TextStyle(color: colors[i], fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text('NO. ${order.orderNo}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.SizedBox(height: 8),
                // 抬头
                pw.Center(child: pw.Text(shopName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
                if (shopPhone != null || shopAddress != null)
                  pw.Center(
                    child: pw.Text(
                      [shopPhone, shopAddress].where((s) => s != null && s.isNotEmpty).join('  |  '),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                pw.SizedBox(height: 8),
                pw.Divider(),
                // 客户信息 / 单据信息
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('客户: ${order.customerName ?? ""}', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text('日期: $dateStr', style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
                if (order.clerk != null)
                  pw.Text('经手人: ${order.clerk}', style: const pw.TextStyle(fontSize: 11)),
                pw.SizedBox(height: 8),
                // 商品表格
                _buildTable(ctx),
                pw.SizedBox(height: 8),
                // 合计
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        _buildTotalRow('总额', order.totalAmount),
                        if (order.orderDiscount < 1.0)
                          _buildTotalRow('折扣 -${((1 - order.orderDiscount) * 100).toStringAsFixed(0)}%', -order.discountAmount),
                        if (order.roundOff > 0) _buildTotalRow('抹零', -order.roundOff),
                        pw.Divider(),
                        _buildTotalRow('应收', order.receivable, bold: true),
                        _buildTotalRow('实收', order.received),
                        if (order.owing > 0) _buildTotalRow('欠款', order.owing),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                // 签收栏
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('客户签收: ____________', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text('日期: ____________', style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Divider(),
                // 底部
                pw.Center(
                  child: pw.Text(
                    settings.footerText,
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    '备注: ${order.remark ?? ""}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
                  ),
                ),
              ],
            ),
          );
        },
      ));
    }
    return pdf.save();
  }

  pw.Widget _buildTable(pw.Context ctx) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // 表头
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell('品名', bold: true),
            _cell('规格', bold: true),
            _cell('数量', bold: true),
            _cell('单价', bold: true),
            _cell('金额', bold: true),
          ],
        ),
        // 数据行
        ...order.items.map((item) => pw.TableRow(
          children: [
            _cell(item.name),
            _cell(item.specSummary ?? ''),
            _cell(item.quantity.toString()),
            _cell('¥${item.price.toStringAsFixed(2)}'),
            _cell('¥${item.amount.toStringAsFixed(2)}'),
          ],
        )),
      ],
    );
  }

  pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }

  pw.Widget _buildTotalRow(String label, double amount, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(width: 120, child: pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal), textAlign: pw.TextAlign.right)),
          pw.SizedBox(width: 8),
          pw.SizedBox(width: 80, child: pw.Text('¥${amount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal), textAlign: pw.TextAlign.right)),
        ],
      ),
    );
  }
}
