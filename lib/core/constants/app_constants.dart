class AppConstants {
  static const String appName = '简易开单';
  static const String appVersion = '1.0.0';

  // 收款方式
  static const List<String> paymentMethods = ['现金', '微信', '支付宝', '转账', '挂账'];

  // 订单状态
  static const Map<String, String> orderStatusMap = {
    'draft': '草稿',
    'completed': '已完成',
    'cancelled': '已作废',
  };

  // 收款状态
  static const Map<String, String> paymentStatusMap = {
    'paid': '已结清',
    'partial': '部分付款',
    'unpaid': '未付',
  };

  // 属性类型
  static const List<String> attrTypes = [
    'single_select',
    'multi_select',
    'number',
    'text',
    'date',
  ];

  static const Map<String, String> attrTypeLabels = {
    'single_select': '单选',
    'multi_select': '多选',
    'number': '数字',
    'text': '文本',
    'date': '日期',
  };

  // 三联单颜色
  static const tripleFormColors = ['白联(存根)', '红联(客户)', '蓝联(记账)'];

  // 纸张类型
  static const Map<String, String> paperTypes = {
    'A4': 'A4 纸',
    'triple_cut': '三等分切纸',
  };

  // 草稿上限
  static const int maxDrafts = 20;
}
