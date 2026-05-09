import 'package:flutter_test/flutter_test.dart';
import 'package:furni_bill/core/models/backup_meta.dart';

void main() {
  group('BackupMeta', () {
    final sample = BackupMeta(
      id: 1,
      fileName: 'furni_bill_20260509_120000.db',
      deviceId: 'device-001',
      deviceName: '华为 Mate 60',
      fileSize: 1048576,
    );

    test('toMap / fromMap roundtrip', () {
      final map = sample.toMap();
      final restored = BackupMeta.fromMap(map);

      expect(restored.id, 1);
      expect(restored.fileName, 'furni_bill_20260509_120000.db');
      expect(restored.deviceId, 'device-001');
      expect(restored.deviceName, '华为 Mate 60');
      expect(restored.fileSize, 1048576);
    });

    test('id is null for new backup', () {
      final meta = BackupMeta(
        fileName: 'backup.db',
        deviceId: 'd1',
        deviceName: 'Test',
        fileSize: 100,
      );
      expect(meta.id, isNull);
    });

    test('createTime auto-generated', () {
      final before = DateTime.now();
      final meta = BackupMeta(
        fileName: 'test.db',
        deviceId: 'd2',
        deviceName: 'iPhone',
        fileSize: 2048,
      );
      final after = DateTime.now();

      expect(
        meta.createTime.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        meta.createTime.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });
  });
}
