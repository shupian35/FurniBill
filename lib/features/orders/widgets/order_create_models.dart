// 订单开单页的本地草稿条目模型
//
// 注：这是 _OrderCreatePageState 内的草稿编辑态，不是 OrderItem（领域模型）。
// 仅在本目录下的 widget 间共享。

class OrderItemData {
  int? productId;
  int? skuId;
  String name;
  String? specSummary;
  String? unit;
  double quantity;
  double price;
  double discount;
  String? remark;

  OrderItemData({
    this.productId,
    this.skuId,
    required this.name,
    this.specSummary,
    this.unit,
    this.quantity = 1,
    required this.price,
    this.discount = 1.0,
    this.remark,
  });
}
