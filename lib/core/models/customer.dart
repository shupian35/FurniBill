/// 客户模型
class Customer {
  final int? id;
  final String name;
  final String phone;
  final String? address;
  final DateTime createTime;
  final DateTime updateTime;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    this.address,
    DateTime? createTime,
    DateTime? updateTime,
  })  : createTime = createTime ?? DateTime.now(),
        updateTime = updateTime ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'create_time': createTime.toIso8601String(),
        'update_time': updateTime.toIso8601String(),
      };

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String?,
      createTime: DateTime.parse(map['create_time'] as String),
      updateTime: DateTime.parse(map['update_time'] as String),
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
  }) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        createTime: createTime,
        updateTime: DateTime.now(),
      );
}
