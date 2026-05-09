import 'package:flutter_test/flutter_test.dart';
import 'package:furni_bill/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('app name', () {
      expect(AppConstants.appName, '家具备货单');
    });

    test('app version', () {
      expect(AppConstants.appVersion, '1.0.0');
      expect(AppConstants.appVersion, isNotEmpty);
    });

    test('payment methods', () {
      expect(AppConstants.paymentMethods, ['现金', '微信', '支付宝', '转账', '挂账']);
      expect(AppConstants.paymentMethods.length, 5);
    });

    test('customer grades', () {
      expect(AppConstants.customerGrades, ['普通', 'VIP', '代理', '批发商']);
      expect(AppConstants.customerGrades.length, 4);
    });

    test('gradeDiscounts mapping', () {
      expect(AppConstants.gradeDiscounts['普通'], 1.0);
      expect(AppConstants.gradeDiscounts['VIP'], 0.95);
      expect(AppConstants.gradeDiscounts['代理'], 0.90);
      expect(AppConstants.gradeDiscounts['批发商'], 0.88);
    });

    test('order statuses', () {
      expect(AppConstants.orderStatusMap['draft'], '草稿');
      expect(AppConstants.orderStatusMap['completed'], '已完成');
      expect(AppConstants.orderStatusMap['cancelled'], '已作废');
      expect(AppConstants.orderStatusMap.length, 3);
    });

    test('payment statuses', () {
      expect(AppConstants.paymentStatusMap['paid'], '已结清');
      expect(AppConstants.paymentStatusMap['partial'], '部分付款');
      expect(AppConstants.paymentStatusMap['unpaid'], '未付');
    });

    test('attribute types', () {
      expect(AppConstants.attrTypes, [
        'single_select',
        'multi_select',
        'number',
        'text',
        'date',
      ]);
      expect(AppConstants.attrTypeLabels['single_select'], '单选');
      expect(AppConstants.attrTypeLabels['multi_select'], '多选');
      expect(AppConstants.attrTypeLabels['number'], '数字');
      expect(AppConstants.attrTypeLabels['text'], '文本');
      expect(AppConstants.attrTypeLabels['date'], '日期');
    });

    test('triple form colors', () {
      expect(AppConstants.tripleFormColors, [
        '白联(存根)',
        '红联(客户)',
        '蓝联(记账)',
      ]);
      expect(AppConstants.tripleFormColors.length, 3);
    });

    test('paper types', () {
      expect(AppConstants.paperTypes['A4'], 'A4 纸');
      expect(AppConstants.paperTypes['triple_cut'], '三等分切纸');
      expect(AppConstants.paperTypes.length, 2);
    });

    test('max drafts', () {
      expect(AppConstants.maxDrafts, 20);
    });
  });
}
