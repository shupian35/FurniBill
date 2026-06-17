import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/member.dart';

class MemberProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<Member> _members = [];
  bool _loading = false;
  String _searchQuery = '';

  List<Member> get members => _members;
  bool get loading => _loading;

  List<Member> get filteredMembers {
    if (_searchQuery.isEmpty) return _members;
    final q = _searchQuery.toLowerCase();
    return _members.where((m) {
      return m.name.toLowerCase().contains(q) ||
          m.memberNo.toLowerCase().contains(q) ||
          (m.phone?.contains(q) ?? false);
    }).toList();
  }

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    await _loadMembers();
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadMembers() async {
    final rows = await _db.query('members', orderBy: 'create_time DESC');
    _members = rows.map((r) => Member.fromMap(r)).toList();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<int> addMember(Member member) async {
    final id = await _db.insert('members', member.toMap());
    await _loadMembers();
    notifyListeners();
    return id;
  }

  Future<void> updateMember(Member member) async {
    await _db.update(
      'members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
    await _loadMembers();
    notifyListeners();
  }

  Future<void> deleteMember(int id) async {
    await _db.delete('members', where: 'id = ?', whereArgs: [id]);
    await _loadMembers();
    notifyListeners();
  }

  Member? getById(int id) {
    try {
      return _members.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addPoints(int id, int points) async {
    final member = getById(id);
    if (member == null) return;
    final updated = member.copyWith(points: member.points + points);
    await updateMember(updated);
  }
}
