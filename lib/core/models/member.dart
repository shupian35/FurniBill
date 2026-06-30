class Member {
  final int? id;
  final int? customerId;
  final String memberNo;
  final String name;
  final String? phone;
  final int points;
  final String level;
  final DateTime createTime;

  Member({
    this.id,
    this.customerId,
    required this.memberNo,
    required this.name,
    this.phone,
    this.points = 0,
    this.level = '普通会员',
    DateTime? createTime,
  }) : createTime = createTime ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'customer_id': customerId,
    'member_no': memberNo,
    'name': name,
    'phone': phone,
    'points': points,
    'level': level,
    'create_time': createTime.toIso8601String(),
  };

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int?,
      memberNo: map['member_no'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      points: map['points'] as int? ?? 0,
      level: map['level'] as String? ?? '普通会员',
      createTime: DateTime.parse(map['create_time'] as String),
    );
  }

  Member copyWith({
    int? id,
    int? customerId,
    String? memberNo,
    String? name,
    String? phone,
    int? points,
    String? level,
  }) => Member(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    memberNo: memberNo ?? this.memberNo,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    points: points ?? this.points,
    level: level ?? this.level,
    createTime: createTime,
  );
}
