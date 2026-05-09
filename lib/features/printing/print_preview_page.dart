import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final font = await _loadChineseFont();

    // 便捷样式工厂
    pw.TextStyle ts(double size, {bool bold = false, PdfColor? color}) =>
        pw.TextStyle(font: font, fontSize: size, fontWeight: bold ? pw.FontWeight.bold : null, color: color);

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
                    pw.Text(labels[i], style: ts(12, bold: true, color: colors[i])),
                    pw.Text('NO. ${order.orderNo}', style: ts(10)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Center(child: pw.Text(shopName, style: ts(18, bold: true))),
                if (shopPhone != null || shopAddress != null)
                  pw.Center(
                    child: pw.Text(
                      [shopPhone, shopAddress].where((s) => s != null && s.isNotEmpty).join('  |  '),
                      style: ts(9),
                    ),
                  ),
                pw.SizedBox(height: 8),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('客户: ${order.customerName ?? ""}', style: ts(11)),
                    pw.Text('日期: $dateStr', style: ts(11)),
                  ],
                ),
                if (order.clerk != null)
                  pw.Text('经手人: ${order.clerk}', style: ts(11)),
                pw.SizedBox(height: 8),
                _buildTable(font),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        _buildTotalRow('总额', order.totalAmount, font),
                        if (order.orderDiscount < 1.0)
                          _buildTotalRow('折扣 -${((1 - order.orderDiscount) * 100).toStringAsFixed(0)}%', -order.discountAmount, font),
                        if (order.roundOff > 0) _buildTotalRow('抹零', -order.roundOff, font),
                        pw.Divider(),
                        _buildTotalRow('应收', order.receivable, font, bold: true),
                        _buildTotalRow('实收', order.received, font),
                        if (order.owing > 0) _buildTotalRow('欠款', order.owing, font),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('客户签收: ____________', style: ts(11)),
                    pw.Text('日期: ____________', style: ts(11)),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.Center(
                  child: pw.Text(settings.footerText, style: ts(9, color: PdfColors.grey)),
                ),
                pw.Center(
                  child: pw.Text('备注: ${order.remark ?? ""}', style: ts(9, color: PdfColors.grey)),
                ),
              ],
            ),
          );
        },
      ));
    }
    return pdf.save();
  }

  Future<pw.Font> _loadChineseFont() async {
    const candidates = [
      'assets/fonts/NotoSansSC-Regular.ttf',
      'assets/fonts/DroidSansFallback.ttf',
      'assets/fonts/chinese.ttf',
    ];
    for (final path in candidates) {
      try {
        return pw.Font.ttf(await rootBundle.load(path));
      } catch (_) {}
    }
    return pw.Font.helvetica();
  }

  pw.Widget _buildTable(pw.Font font) {
    pw.TextStyle ts(double size, {bool bold = false}) =>
        pw.TextStyle(font: font, fontSize: size, fontWeight: bold ? pw.FontWeight.bold : null);

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
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell('品名', font, bold: true),
            _cell('规格', font, bold: true),
            _cell('数量', font, bold: true),
            _cell('单价', font, bold: true),
            _cell('金额', font, bold: true),
          ],
        ),
        ...order.items.map((item) => pw.TableRow(
          children: [
            _cell(item.name, font),
            _cell(item.specSummary ?? '', font),
            _cell(item.quantity.toString(), font),
            _cell('¥${item.price.toStringAsFixed(2)}', font),
            _cell('¥${item.amount.toStringAsFixed(2)}', font),
          ],
        )),
      ],
    );
  }

  pw.Widget _cell(String text, pw.Font font, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : null),
      ),
    );
  }

  pw.Widget _buildTotalRow(String label, double amount, pw.Font font, {bool bold = false}) {
    pw.TextStyle ts(double size) => pw.TextStyle(font: font, fontSize: size, fontWeight: bold ? pw.FontWeight.bold : null);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(width: 120, child: pw.Text(label, style: ts(10), textAlign: pw.TextAlign.right)),
          pw.SizedBox(width: 8),
          pw.SizedBox(width: 80, child: pw.Text('¥${amount.toStringAsFixed(2)}', style: ts(10), textAlign: pw.TextAlign.right)),
        ],
      ),
    );
  }
}
