import '../models/order.dart';
import '../../features/orders/widgets/order_create_models.dart';

/// 订单金额计算器（纯函数，无 Flutter 依赖）
///
/// 把订单 UI 模型上的金额计算从 OrderCreatePage / OrderCreatePageState 中
/// 抽出来，方便单测。
class OrderCalculator {
  const OrderCalculator();

  /// 商品明细总额：sum(price * quantity * discount)
  double totalAmount(List<OrderItemData> items) {
    return items.fold(0.0, (sum, i) => sum + (i.price * i.quantity * i.discount));
  }

  /// 整单折扣金额：totalAmount * (1 - orderDiscount)
  double discountAmount(double totalAmount, double orderDiscount) {
    return totalAmount * (1 - orderDiscount);
  }

  /// 折扣后金额：totalAmount * orderDiscount
  double afterDiscount(double totalAmount, double orderDiscount) {
    return totalAmount * orderDiscount;
  }

  /// 应收金额：afterDiscount - roundOff
  double receivable(double afterDiscount, double roundOff) {
    return afterDiscount - roundOff;
  }

  /// 欠款：receivable - received
  double owing(double receivable, double received) {
    return receivable - received;
  }

  /// 一次算完所有金额（用 OrderItem 列表 + 折扣 + 抹零 + 实收）
  ///
  /// 返回值对应 Order 模型的 5 个金额字段：
  ///   totalAmount, discountAmount, receivable, received, owing
  OrderTotals compute({
    required List<OrderItem> items,
    required double orderDiscount,
    required double roundOff,
    required double received,
  }) {
    final total = items.fold(0.0, (sum, i) => sum + (i.price * i.quantity * i.discount));
    final disc = total * (1 - orderDiscount);
    final after = total * orderDiscount;
    final recv = after - roundOff;
    final owing = recv - received;
    return OrderTotals(
      totalAmount: total,
      discountAmount: disc,
      receivable: recv,
      received: received,
      owing: owing,
    );
  }
}

class OrderTotals {
  final double totalAmount;
  final double discountAmount;
  final double receivable;
  final double received;
  final double owing;

  const OrderTotals({
    required this.totalAmount,
    required this.discountAmount,
    required this.receivable,
    required this.received,
    required this.owing,
  });
}
