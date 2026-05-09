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

    // 样式工厂
    pw.TextStyle ts(double size, {bool bold = false, PdfColor? color}) =>
        pw.TextStyle(font: font, fontSize: size, fontWeight: bold ? pw.FontWeight.bold : null, color: color);

    final pdf = pw.Document();
    final shopName = settings.shopName.isNotEmpty ? settings.shopName : '聪聪木业';
    final dateStr = DateFormat('yyyy-MM-dd').format(order.completeTime ?? order.createTime);
    final totalQty = order.items.fold<int>(0, (s, i) => s + i.quantity.toInt());

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ═══════ 标题 ═══════
            pw.Center(child: pw.Text(shopName, style: ts(22, bold: true))),
            pw.SizedBox(height: 2),
            pw.Center(child: pw.Text('家具销售单', style: ts(16, bold: true))),
            pw.SizedBox(height: 10),

            // ═══════ 单据信息行 ═══════
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('NO: ${order.orderNo}', style: ts(10)),
                  pw.Text('客户: ${order.customerName ?? ""}', style: ts(10)),
                  pw.Text('销售日期: $dateStr', style: ts(10)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // ═══════ 商品表格 ═══════
            _buildTable(font),
            pw.SizedBox(height: 8),

            // ═══════ 合计金额（大写 + 数字）═══════
            pw.Text(
              '合计金额：${_amountToChinese(order.receivable)}  ${order.receivable.toStringAsFixed(2)}',
              style: ts(11, bold: true),
            ),
            pw.SizedBox(height: 6),

            // ═══════ 备注 ═══════
            if (order.remark != null && order.remark!.isNotEmpty)
              pw.Text('备注：${order.remark}', style: ts(10)),
            pw.SizedBox(height: 16),

            // ═══════ 页脚联系信息 ═══════
            pw.Divider(),
            pw.SizedBox(height: 4),
            pw.Text(
              '订货电话：13763921269（微信号）  15083211281（微信号）',
              style: ts(9),
            ),
            pw.Text(
              '订货地址：南康东山桥南大道坪塘工业园',
              style: ts(9),
            ),
            pw.Text(
              '农行：6228 4534 7002 3535 717  户名（谢月亮）',
              style: ts(9),
            ),
          ],
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
    pw.TextStyle hdr(double size) => pw.TextStyle(font: font, fontSize: size, fontWeight: pw.FontWeight.bold);
    pw.TextStyle cell(double size) => pw.TextStyle(font: font, fontSize: size);
    pw.TextStyle cellBold(double size) => pw.TextStyle(font: font, fontSize: size, fontWeight: pw.FontWeight.bold);

    const pad = 6.0;
    final rows = <pw.TableRow>[];

    // 表头
    rows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEEEEEE)),
      children: [
        _tc('编号', hdr(9), pad),
        _tc('产品', hdr(9), pad),
        _tc('规格型号', hdr(9), pad),
        _tc('单位', hdr(9), pad),
        _tc('总数量', hdr(9), pad, align: pw.TextAlign.center),
        _tc('单价', hdr(9), pad, align: pw.TextAlign.right),
        _tc('金额', hdr(9), pad, align: pw.TextAlign.right),
        _tc('备注', hdr(9), pad),
      ],
    ));

    // 数据行
    final totalQty = order.items.fold<int>(0, (s, i) => s + i.quantity.toInt());
    for (var i = 0; i < order.items.length; i++) {
      final item = order.items[i];
      rows.add(pw.TableRow(
        children: [
          _tc('${i + 1}', cell(9), pad, align: pw.TextAlign.center),
          _tc(item.name, cell(9), pad),
          _tc(item.specSummary ?? '', cell(9), pad),
          _tc(_unitFromItem(item), cell(9), pad, align: pw.TextAlign.center),
          _tc('${item.quantity}', cell(9), pad, align: pw.TextAlign.center),
          _tc('${item.price.toStringAsFixed(2)}', cell(9), pad, align: pw.TextAlign.right),
          _tc('${item.amount.toStringAsFixed(2)}', cell(9), pad, align: pw.TextAlign.right),
          _tc(item.remark ?? '', cell(8), pad),
        ],
      ));
    }

    // 合计行
    rows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5F5F5)),
      children: [
        _tc('', cell(9), pad),
        _tc('合计', cellBold(9), pad),
        _tc('', cell(9), pad),
        _tc('', cell(9), pad),
        _tc('$totalQty', cellBold(9), pad, align: pw.TextAlign.center),
        _tc('', cell(9), pad),
        _tc('${order.receivable.toStringAsFixed(2)}', cellBold(9), pad, align: pw.TextAlign.right),
        _tc('', cell(9), pad),
      ],
    ));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.6),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(0.6),
        4: const pw.FlexColumnWidth(0.8),
        5: const pw.FlexColumnWidth(1.0),
        6: const pw.FlexColumnWidth(1.0),
        7: const pw.FlexColumnWidth(1.2),
      },
      children: rows,
    );
  }

  /// 从 OrderItem 提取单位信息
  String _unitFromItem(OrderItem item) => item.unit ?? '';

  pw.Widget _tc(String text, pw.TextStyle style, double pad, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(pad),
      child: pw.Text(text, style: style, textAlign: align, maxLines: 2),
    );
  }

  /// 阿拉伯数字转中文大写金额
  String _amountToChinese(double amount) {
    if (amount <= 0) return '零元整';
    final digits = '零壹贰叁肆伍陆柒捌玖';
    final units = ['', '拾', '佰', '仟'];
    final bigUnits = ['', '万', '亿'];

    final yuan = amount.toInt();
    final jiao = ((amount * 10) % 10).toInt();
    final fen = ((amount * 100) % 10).toInt();

    String convertPart(int num) {
      if (num == 0) return '零';
      final s = num.toString();
      final len = s.length;
      final buf = StringBuffer();
      bool hasZero = false;
      for (var i = 0; i < len; i++) {
        final d = int.parse(s[i]);
        final pos = len - 1 - i;
        if (d == 0) {
          hasZero = true;
        } else {
          if (hasZero && buf.isNotEmpty && !buf.toString().endsWith('零')) {
            buf.write('零');
          }
          buf.write(digits[d]);
          buf.write(units[pos % 4]);
          hasZero = false;
        }
        if (pos % 4 == 0 && pos > 0) {
          buf.write(bigUnits[pos ~/ 4]);
          hasZero = false;
        }
      }
      var result = buf.toString();
      if (result.endsWith('零')) result = result.substring(0, result.length - 1);
      return result;
    }

    final yuanStr = convertPart(yuan);
    final buf = StringBuffer();
    buf.write(yuanStr);
    buf.write('元');

    if (jiao == 0 && fen == 0) {
      buf.write('整');
    } else {
      if (jiao > 0) buf.write('${digits[jiao]}角');
      if (fen > 0) buf.write('${digits[fen]}分');
    }
    return buf.toString();
  }
}
