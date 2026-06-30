/// 客户模型
class Customer {
  final int? id;
  final String name;
  final String phone;
  final String? address;
  final String tier;
  final double creditLimit;
  final int dueDays;
  final double totalOwing;
  final DateTime createTime;
  final DateTime updateTime;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    this.address,
    this.tier = '普通',
    this.creditLimit = 0,
    this.dueDays = 0,
    this.totalOwing = 0,
    DateTime? createTime,
    DateTime? updateTime,
  }) : createTime = createTime ?? DateTime.now(),
       updateTime = updateTime ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'phone': phone,
    'address': address,
    'tier': tier,
    'credit_limit': creditLimit,
    'due_days': dueDays,
    'total_owing': totalOwing,
    'create_time': createTime.toIso8601String(),
    'update_time': updateTime.toIso8601String(),
  };

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String?,
      tier: map['tier'] as String? ?? '普通',
      creditLimit: (map['credit_limit'] as num?)?.toDouble() ?? 0,
      dueDays: map['due_days'] as int? ?? 0,
      totalOwing: (map['total_owing'] as num?)?.toDouble() ?? 0,
      createTime: DateTime.parse(map['create_time'] as String),
      updateTime: DateTime.parse(map['update_time'] as String),
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? tier,
    double? creditLimit,
    int? dueDays,
    double? totalOwing,
  }) => Customer(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    tier: tier ?? this.tier,
    creditLimit: creditLimit ?? this.creditLimit,
    dueDays: dueDays ?? this.dueDays,
    totalOwing: totalOwing ?? this.totalOwing,
    createTime: createTime,
    updateTime: DateTime.now(),
  );
}
