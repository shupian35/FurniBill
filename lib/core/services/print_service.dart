
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../providers/settings_provider.dart';

/// 打印 PDF 生成服务（从 print_preview_page 抽出的纯逻辑层）
///
/// 负责：加载中文字体、构建单页/三联单 PDF、把金额转中文大写。
/// 不负责：UI、Scaffold、Provider 监听、用户交互。
/// 调用方：PrintPreviewPage 在 PdfPreview.build 回调里直接 `await PrintService().buildPdf(order, settings)`。
class PrintService {
  const PrintService();

  /// 默认店招（settings.shopName 为空时使用）。
  static const String defaultShopName = '聪聪木业';

  /// 三联单标签（白联=存根，红联=客户，蓝联=记账）。
  static const List<String> tripleFormLabels = <String>[
    '白联(存根)',
    '红联(客户)',
    '蓝联(记账)',
  ];

  /// 三联单对应的标签底色（存根=灰，客户=红，记账=蓝）。
  static const List<PdfColor> tripleFormColors = <PdfColor>[
    PdfColors.grey400,
    PdfColors.red300,
    PdfColors.blue300,
  ];

  Future<Uint8List> buildPdf(
    Order order,
    SettingsProvider settings, {
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    final font = await _loadChineseFont();

    final pdf = pw.Document();
    final shopName = settings.shopName.isNotEmpty ? settings.shopName : defaultShopName;
    final dateStr = DateFormat('yyyy-MM-dd').format(order.completeTime ?? order.createTime);

    if (settings.tripleFormEnabled) {
      // 三联单模式
      final copies = settings.tripleFormCopies;
      const labels = tripleFormLabels;
      const colors = tripleFormColors;

      if (settings.tripleFormMode == 'continuous') {
        // 连续打印模式：三联在同一张纸上
        pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (ctx) {
            return pw.Column(
              children: copies.map((index) {
                return pw.Column(
                  children: [
                    _buildTripleFormContent(font, settings, order, shopName, dateStr, labels[index], colors[index]),
                    if (index != copies.last) pw.Divider(height: 20, thickness: 2, color: PdfColors.grey),
                  ],
                );
              }).toList(),
            );
          },
        ));
      } else {
        // 分页打印模式：每联单独一页
        for (final index in copies) {
          pdf.addPage(pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (ctx) {
              return _buildTripleFormContent(font, settings, order, shopName, dateStr, labels[index], colors[index]);
            },
          ));
        }
      }
    } else {
      // 普通单页模式
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (ctx) {
          return _buildTripleFormContent(font, settings, order, shopName, dateStr, '', PdfColors.grey400);
        },
      ));
    }

    return pdf.save();
  }

  pw.Widget _buildTripleFormContent(
    pw.Font font,
    SettingsProvider settings,
    Order order,
    String shopName,
    String dateStr,
    String label,
    PdfColor labelColor,
  ) {
    pw.TextStyle ts(double size, {bool bold = false, PdfColor? color}) =>
        pw.TextStyle(font: font, fontSize: size, fontWeight: bold ? pw.FontWeight.bold : null, color: color);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // 联标签
        if (label.isNotEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: labelColor,
            child: pw.Text(label, style: ts(10, bold: true)),
          ),
        pw.SizedBox(height: 8),

        // 标题
        pw.Center(child: pw.Text(shopName, style: ts(18, bold: true))),
        pw.SizedBox(height: 2),
        pw.Center(child: pw.Text('家具销售单', style: ts(14, bold: true))),
        pw.SizedBox(height: 8),

        // 单据信息行
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('NO: ${order.orderNo}', style: ts(9)),
              pw.Text('客户: ${order.customerName ?? ""}', style: ts(9)),
              pw.Text('日期: $dateStr', style: ts(9)),
            ],
          ),
        ),
        pw.SizedBox(height: 6),

        // 商品表格
        _buildTable(font, order),
        pw.SizedBox(height: 6),

        // 合计金额
        pw.Text(
          '合计金额：${_amountToChinese(order.receivable)}  ${order.receivable.toStringAsFixed(2)}',
          style: ts(10, bold: true),
        ),
        pw.SizedBox(height: 4),

        // 备注
        if (order.remark != null && order.remark!.isNotEmpty)
          pw.Text('备注：${order.remark}', style: ts(9)),
        pw.SizedBox(height: 8),

        // 页脚
        pw.Divider(),
        pw.SizedBox(height: 2),
        if (settings.shopPhone.isNotEmpty)
          pw.Text('电话：${settings.shopPhone}', style: ts(8)),
        if (settings.shopAddress.isNotEmpty)
          pw.Text('地址：${settings.shopAddress}', style: ts(8)),
        if (settings.bankAccount.isNotEmpty)
          pw.Text(settings.bankAccount, style: ts(8)),
      ],
    );
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

  pw.Widget _buildTable(pw.Font font, Order order) {
    pw.TextStyle hdr(double size) => pw.TextStyle(font: font, fontSize: size, fontWeight: pw.FontWeight.bold);
    pw.TextStyle cell(double size) => pw.TextStyle(font: font, fontSize: size);
    pw.TextStyle cellBold(double size) => pw.TextStyle(font: font, fontSize: size, fontWeight: pw.FontWeight.bold);

    const pad = 4.0;
    final rows = <pw.TableRow>[];

    // 表头
    rows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEEEEEE)),
      children: [
        _tc('编号', hdr(8), pad),
        _tc('产品', hdr(8), pad),
        _tc('规格', hdr(8), pad),
        _tc('单位', hdr(8), pad, align: pw.TextAlign.center),
        _tc('数量', hdr(8), pad, align: pw.TextAlign.center),
        _tc('单价', hdr(8), pad, align: pw.TextAlign.right),
        _tc('金额', hdr(8), pad, align: pw.TextAlign.right),
      ],
    ));

    // 数据行
    for (var i = 0; i < order.items.length; i++) {
      final item = order.items[i];
      rows.add(pw.TableRow(
        children: [
          _tc('${i + 1}', cell(8), pad, align: pw.TextAlign.center),
          _tc(item.name, cell(8), pad),
          _tc(item.specSummary ?? '', cell(8), pad),
          _tc(_unitFromItem(item), cell(8), pad, align: pw.TextAlign.center),
          _tc('${item.quantity}', cell(8), pad, align: pw.TextAlign.center),
          _tc('${item.price.toStringAsFixed(2)}', cell(8), pad, align: pw.TextAlign.right),
          _tc('${item.amount.toStringAsFixed(2)}', cell(8), pad, align: pw.TextAlign.right),
        ],
      ));
    }

    // 合计行
    rows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5F5F5)),
      children: [
        _tc('', cell(8), pad),
        _tc('合计', cellBold(8), pad),
        _tc('', cell(8), pad),
        _tc('', cell(8), pad),
        _tc('${order.itemCount}', cellBold(8), pad, align: pw.TextAlign.center),
        _tc('', cell(8), pad),
        _tc('${order.receivable.toStringAsFixed(2)}', cellBold(8), pad, align: pw.TextAlign.right),
      ],
    ));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(0.5),
        4: const pw.FlexColumnWidth(0.6),
        5: const pw.FlexColumnWidth(0.8),
        6: const pw.FlexColumnWidth(0.9),
      },
      children: rows,
    );
  }

  String _unitFromItem(OrderItem item) => item.unit ?? '';

  pw.Widget _tc(String text, pw.TextStyle style, double pad, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(pad),
      child: pw.Text(text, style: style, textAlign: align, maxLines: 2),
    );
  }

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
