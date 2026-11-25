import 'package:sqflite/sqflite.dart';

class RbacEvaluator {
  RbacEvaluator(this._db);

  final Database _db;

  Future<bool> hasPermission(int userId, String permissionName) async {
    final result = await _db.rawQuery('''
      SELECT COUNT(*) as count
      FROM role_permissions rp
      JOIN permissions p ON p.key = rp.permission_key
      JOIN users u ON u.role_id = rp.role_id
      WHERE u.id = ? AND p.key = ? AND rp.is_active = 1
    ''', [userId, permissionName]);
    final count = result.first['count'] as int? ?? 0;
    return count > 0;
  }

  Future<List<String>> getPermissions(int userId) async {
    final result = await _db.rawQuery('''
      SELECT p.key
      FROM role_permissions rp
      JOIN permissions p ON p.key = rp.permission_key
      JOIN users u ON u.role_id = rp.role_id
      WHERE u.id = ? AND rp.is_active = 1
    ''', [userId]);
    return result.map((row) => row['key'] as String).toList();
  }
}
