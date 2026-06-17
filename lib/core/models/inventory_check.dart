class InventoryCheckItem {
  final int? id;
  final int? checkId;
  final int productId;
  final String? productName;
  final int systemStock;
  final int? actualStock;
  final int? difference;
  final String? remark;

  InventoryCheckItem({
    this.id,
    this.checkId,
    required this.productId,
    this.productName,
    required this.systemStock,
    this.actualStock,
    this.difference,
    this.remark,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'check_id': checkId,
    'product_id': productId,
    'system_stock': systemStock,
    'actual_stock': actualStock,
    'difference': difference,
    'remark': remark,
  };

  factory InventoryCheckItem.fromMap(Map<String, dynamic> map) {
    return InventoryCheckItem(
      id: map['id'] as int?,
      checkId: map['check_id'] as int?,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String?,
      systemStock: map['system_stock'] as int,
      actualStock: map['actual_stock'] as int?,
      difference: map['difference'] as int?,
      remark: map['remark'] as String?,
    );
  }
}

class InventoryCheck {
  final int? id;
  final String checkNo;
  final int warehouseId;
  final String status;
  final String? remark;
  final DateTime createTime;
  final DateTime? completeTime;

  InventoryCheck({
    this.id,
    required this.checkNo,
    this.warehouseId = 1,
    this.status = 'draft',
    this.remark,
    DateTime? createTime,
    this.completeTime,
  }) : createTime = createTime ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'check_no': checkNo,
    'warehouse_id': warehouseId,
    'status': status,
    'remark': remark,
    'create_time': createTime.toIso8601String(),
    'complete_time': completeTime?.toIso8601String(),
  };

  factory InventoryCheck.fromMap(Map<String, dynamic> map) {
    return InventoryCheck(
      id: map['id'] as int?,
      checkNo: map['check_no'] as String,
      warehouseId: map['warehouse_id'] as int? ?? 1,
      status: map['status'] as String? ?? 'draft',
      remark: map['remark'] as String?,
      createTime: DateTime.parse(map['create_time'] as String),
      completeTime: map['complete_time'] != null
          ? DateTime.parse(map['complete_time'] as String)
          : null,
    );
  }
}
