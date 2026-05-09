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
      appBar: AppBar(title: const Text('打印预览')),
      body: PdfPreview(
        build: (format) => _buildPdf(format, settings),
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }

  Future<Uint8List> _buildPdf(PdfPageFormat format, SettingsProvider settings) async {
    final font = await _loadChineseFont();

    pw.TextStyle ts(double size, {bool bold = false, PdfColor? color}) =>
        pw.TextStyle(font: font, fontSize: size, fontWeight: bold ? pw.FontWeight.bold : null, color: color);

    final pdf = pw.Document();
    final shopName = settings.shopName.isNotEmpty ? settings.shopName : '聪聪木业';
    final shopPhone = settings.shopPhone.isNotEmpty ? settings.shopPhone : null;
    final shopAddress = settings.shopAddress.isNotEmpty ? settings.shopAddress : null;
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(order.completeTime ?? order.createTime);
    final totalQty = order.items.fold<int>(0, (s, i) => s + i.quantity.toInt());

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ═══════ 标题 ═══════
              pw.Center(child: pw.Text(shopName, style: ts(22, bold: true))),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 3),
                  child: pw.Text('家具销售单', style: ts(16, bold: true)),
                ),
              ),
              pw.SizedBox(height: 12),

              // ═══════ 单据信息 ═══════
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('单号: ${order.orderNo}', style: ts(10)),
                        pw.Text('日期: $dateStr', style: ts(10)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('客户: ${order.customerName ?? ""}', style: ts(11, bold: true)),
                        if (order.clerk != null && order.clerk!.isNotEmpty)
                          pw.Text('经手人: ${order.clerk}', style: ts(10)),
                      ],
                    ),
                    if (shopPhone != null || shopAddress != null)
                      pw.SizedBox(height: 2),
                    if (shopPhone != null && shopPhone!.isNotEmpty)
                      pw.Text('电话: $shopPhone', style: ts(9)),
                    if (shopAddress != null && shopAddress!.isNotEmpty)
                      pw.Text('地址: $shopAddress', style: ts(9)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // ═══════ 商品明细表格 ═══════
              _buildTable(font),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('共 ${order.items.length} 项  $totalQty 件', style: ts(9)),
                  pw.Text('合计: ¥${order.totalAmount.toStringAsFixed(2)}', style: ts(11, bold: true)),
                ],
              ),
              pw.SizedBox(height: 8),

              // ═══════ 金额汇总 ═══════
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 200,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (order.orderDiscount < 1.0)
                        _totalLine('整单折扣  ${((order.orderDiscount) * 100).toStringAsFixed(0)}%', -order.discountAmount, font),
                      if (order.roundOff > 0)
                        _totalLine('抹零', -order.roundOff, font),
                      pw.Divider(height: 1),
                      _totalLine('应收合计', order.receivable, font, bold: true),
                      _totalLine('实收金额', order.received, font),
                      if (order.owing > 0)
                        _totalLine('欠款', order.owing, font, color: PdfColors.red),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 16),

              // ═══════ 签收 ═══════
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('客户签收: ____________', style: ts(11)),
                  pw.Text('日期: ____________', style: ts(11)),
                ],
              ),
              pw.SizedBox(height: 10),

              // ═══════ 收款方式 / 备注 ═══════
              if (order.paymentMethod != null && order.paymentMethod!.isNotEmpty)
                pw.Text('收款方式: ${order.paymentMethod}', style: ts(9)),
              if (order.remark != null && order.remark!.isNotEmpty)
                pw.Text('备注: ${order.remark}', style: ts(9)),
              if (settings.footerText.isNotEmpty)
                pw.Text(settings.footerText, style: ts(9, color: PdfColors.grey)),
            ],
          ),
        );
      },
    ));

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
    pw.TextStyle hdr(double size, {bool bold = false}) =>
        pw.TextStyle(font: font, fontSize: size, fontWeight: bold ? pw.FontWeight.bold : null, color: PdfColors.white);
    pw.TextStyle cell(double size) =>
        pw.TextStyle(font: font, fontSize: size);

    const headerBg = PdfColor.fromInt(0xFF333333);
    final rows = <pw.TableRow>[
      // 表头
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: headerBg),
        children: [
          _tc('品名', hdr(10, bold: true), pad: 5),
          _tc('规格', hdr(10, bold: true), pad: 5),
          _tc('数量', hdr(10, bold: true), pad: 5),
          _tc('单价', hdr(10, bold: true), pad: 5),
          _tc('金额', hdr(10, bold: true), pad: 5),
        ],
      ),
      // 数据行
      for (var i = 0; i < order.items.length; i++)
        pw.TableRow(
          decoration: i.isEven
              ? const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF9F9F9))
              : null,
          children: [
            _tc(order.items[i].name, cell(9), pad: 5),
            _tc(order.items[i].specSummary ?? '', cell(9), pad: 5),
            _tc('${order.items[i].quantity}', cell(9), pad: 5, align: pw.TextAlign.center),
            _tc('¥${order.items[i].price.toStringAsFixed(2)}', cell(9), pad: 5, align: pw.TextAlign.right),
            _tc('¥${order.items[i].amount.toStringAsFixed(2)}', cell(9), pad: 5, align: pw.TextAlign.right),
          ],
        ),
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.8),
        4: const pw.FlexColumnWidth(1.8),
      },
      children: rows,
    );
  }

  pw.Widget _tc(String text, pw.TextStyle style, {double pad = 4, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(pad),
      child: pw.Text(text, style: style, textAlign: align),
    );
  }

  pw.Widget _totalLine(String label, double amount, pw.Font font, {bool bold = false, PdfColor? color}) {
    final ts = pw.TextStyle(
      font: font,
      fontSize: 10,
      fontWeight: bold ? pw.FontWeight.bold : null,
      color: color ?? PdfColors.black,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(width: 80, child: pw.Text(label, style: ts, textAlign: pw.TextAlign.right)),
          pw.SizedBox(width: 10),
          pw.SizedBox(width: 80, child: pw.Text('¥${amount.toStringAsFixed(2)}', style: ts, textAlign: pw.TextAlign.right)),
        ],
      ),
    );
  }
}
