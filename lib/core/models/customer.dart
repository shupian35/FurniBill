/// 客户模型
class Customer {
  final int? id;
  final String name;
  final String? companyName;
  final String phone;
  final String? region;
  final String? address;
  final String grade;
  final double discount;
  final double? creditLimit;
  final double owing;
  final String? remark;
  final DateTime createTime;
  final DateTime updateTime;

  Customer({
    this.id,
    required this.name,
    this.companyName,
    required this.phone,
    this.region,
    this.address,
    this.grade = '普通',
    this.discount = 1.0,
    this.creditLimit,
    this.owing = 0,
    this.remark,
    DateTime? createTime,
    DateTime? updateTime,
  })  : createTime = createTime ?? DateTime.now(),
        updateTime = updateTime ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'company_name': companyName,
        'phone': phone,
        'region': region,
        'address': address,
        'grade': grade,
        'discount': discount,
        'credit_limit': creditLimit,
        'owing': owing,
        'remark': remark,
        'create_time': createTime.toIso8601String(),
        'update_time': updateTime.toIso8601String(),
      };

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      companyName: map['company_name'] as String?,
      phone: map['phone'] as String,
      region: map['region'] as String?,
      address: map['address'] as String?,
      grade: map['grade'] as String? ?? '普通',
      discount: (map['discount'] as num?)?.toDouble() ?? 1.0,
      creditLimit: (map['credit_limit'] as num?)?.toDouble(),
      owing: (map['owing'] as num?)?.toDouble() ?? 0,
      remark: map['remark'] as String?,
      createTime: DateTime.parse(map['create_time'] as String),
      updateTime: DateTime.parse(map['update_time'] as String),
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? companyName,
    String? phone,
    String? region,
    String? address,
    String? grade,
    double? discount,
    double? creditLimit,
    double? owing,
    String? remark,
  }) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        companyName: companyName ?? this.companyName,
        phone: phone ?? this.phone,
        region: region ?? this.region,
        address: address ?? this.address,
        grade: grade ?? this.grade,
        discount: discount ?? this.discount,
        creditLimit: creditLimit ?? this.creditLimit,
        owing: owing ?? this.owing,
        remark: remark ?? this.remark,
        createTime: createTime,
        updateTime: DateTime.now(),
      );
}
