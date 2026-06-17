class Warehouse {
  final int? id;
  final String name;
  final String? address;
  final String? phone;
  final bool isDefault;
  final DateTime createTime;

  Warehouse({
    this.id,
    required this.name,
    this.address,
    this.phone,
    this.isDefault = false,
    DateTime? createTime,
  }) : createTime = createTime ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'address': address,
    'phone': phone,
    'is_default': isDefault ? 1 : 0,
    'create_time': createTime.toIso8601String(),
  };

  factory Warehouse.fromMap(Map<String, dynamic> map) {
    return Warehouse(
      id: map['id'] as int?,
      name: map['name'] as String,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      isDefault: map['is_default'] == 1,
      createTime: DateTime.parse(map['create_time'] as String),
    );
  }

  Warehouse copyWith({
    int? id,
    String? name,
    String? address,
    String? phone,
    bool? isDefault,
  }) =>
      Warehouse(
        id: id ?? this.id,
        name: name ?? this.name,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        isDefault: isDefault ?? this.isDefault,
        createTime: createTime,
      );
}
