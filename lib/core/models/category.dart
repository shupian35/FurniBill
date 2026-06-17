class Category {
  final int? id;
  final String name;
  final int? parentId;
  final int sortOrder;
  final DateTime createTime;

  Category({
    this.id,
    required this.name,
    this.parentId,
    this.sortOrder = 0,
    DateTime? createTime,
  }) : createTime = createTime ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'parent_id': parentId,
    'sort_order': sortOrder,
    'create_time': createTime.toIso8601String(),
  };

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      parentId: map['parent_id'] as int?,
      sortOrder: map['sort_order'] as int? ?? 0,
      createTime: DateTime.parse(map['create_time'] as String),
    );
  }

  Category copyWith({
    int? id,
    String? name,
    int? parentId,
    int? sortOrder,
  }) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        parentId: parentId ?? this.parentId,
        sortOrder: sortOrder ?? this.sortOrder,
        createTime: createTime,
      );
}