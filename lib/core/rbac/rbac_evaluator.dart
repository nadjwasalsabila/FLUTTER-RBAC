import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class RbacEvaluator {
  static final RbacEvaluator instance = RbacEvaluator._internal();
  RbacEvaluator._internal();

  Future<bool> hasPermission(int userId, String permissionName) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM role_permissions rp
      JOIN permissions p ON p.id = rp.permission_id
      JOIN users u ON u.role_id = rp.role_id
      WHERE u.id = ? AND p.name = ?
    ''', [userId, permissionName]);
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  Future<List<String>> getPermissions(int userId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT p.name
      FROM role_permissions rp
      JOIN permissions p ON p.id = rp.permission_id
      JOIN users u ON u.role_id = rp.role_id
      WHERE u.id = ?
    ''', [userId]);
    return result.map((row) => row['name'] as String).toList();
  }
}
