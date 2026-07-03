// BaseCrudProvider unit test

import 'package:flutter_test/flutter_test.dart';
import 'package:furni_bill/core/providers/base_crud_provider.dart';

class _MockNote {
  final int? id;
  final String title;
  _MockNote({this.id, required this.title});

  Map<String, dynamic> toMap() => {'id': id, 'title': title};
  factory _MockNote.fromMap(Map<String, dynamic> map) =>
      _MockNote(id: map['id'] as int?, title: map['title'] as String);
}

class _MockNoteProvider extends BaseCrudProvider<_MockNote> {
  @override
  String get tableName => 'notes';

  @override
  _MockNote fromMap(Map<String, dynamic> map) => _MockNote.fromMap(map);

  @override
  Map<String, dynamic> toMap(_MockNote item) => item.toMap();

  @override
  String? get orderByClause => 'id ASC';
}

class _NoOrderProvider extends BaseCrudProvider<_MockNote> {
  @override
  String get tableName => 'x';
  @override
  _MockNote fromMap(Map<String, dynamic> map) => _MockNote.fromMap(map);
  @override
  Map<String, dynamic> toMap(_MockNote item) => item.toMap();
}

void main() {
  group('BaseCrudProvider basic behavior', () {
    test('new instance: items = [], loading = false', () {
      final p = _MockNoteProvider();
      expect(p.items, isEmpty);
      expect(p.loading, isFalse);
    });

    test('fromMap/toMap delegate to Model', () {
      final p = _MockNoteProvider();
      final note = _MockNote(id: 1, title: 'hello');
      expect(p.toMap(note), {'id': 1, 'title': 'hello'});
      final back = p.fromMap({'id': 2, 'title': 'world'});
      expect(back.id, 2);
      expect(back.title, 'world');
    });

    test('tableName / orderByClause from subclass', () {
      final p = _MockNoteProvider();
      expect(p.tableName, 'notes');
      expect(p.orderByClause, 'id ASC');
    });

    test('orderByClause defaults to null', () {
      expect(_NoOrderProvider().orderByClause, isNull);
    });
  });
}