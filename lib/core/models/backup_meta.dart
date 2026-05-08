/// 备份元数据
class BackupMeta {
  final int? id;
  final String fileName;
  final String deviceId;
  final String deviceName;
  final int fileSize;
  final DateTime createTime;

  BackupMeta({
    this.id,
    required this.fileName,
    required this.deviceId,
    required this.deviceName,
    required this.fileSize,
    DateTime? createTime,
  }) : createTime = createTime ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'file_name': fileName,
        'device_id': deviceId,
        'device_name': deviceName,
        'file_size': fileSize,
        'create_time': createTime.toIso8601String(),
      };

  factory BackupMeta.fromMap(Map<String, dynamic> map) {
    return BackupMeta(
      id: map['id'] as int?,
      fileName: map['file_name'] as String,
      deviceId: map['device_id'] as String,
      deviceName: map['device_name'] as String,
      fileSize: map['file_size'] as int,
      createTime: DateTime.parse(map['create_time'] as String),
    );
  }
}
