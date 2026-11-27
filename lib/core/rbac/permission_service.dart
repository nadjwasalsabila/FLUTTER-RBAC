import 'package:sqflite/sqflite.dart';

/// Kunci permission terpusat untuk seluruh fitur RBAC.
abstract final class AppPermissions {
  static const itemRead = 'item:read';
  static const stockAdjust = 'stock:adjust';
  static const itemCreate = 'item:create';
  static const itemDelete = 'item:delete';
  static const policyEdit = 'policy:edit';
}

typedef PermissionChecker = Future<bool> Function(String permissionKey);

/// Evaluator RBAC tunggal yang membaca tabel `role_permissions` aktif.
class PermissionService {
  const PermissionService(this._db);

  final DatabaseExecutor _db;

  Future<bool> hasPermission(String roleId, String permissionKey) async {
    final rows = await _db.query(
      'role_permissions',
      columns: const ['permission_key'],
      where: 'role_id = ? AND permission_key = ? AND is_active = 1',
      whereArgs: [roleId, permissionKey],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Mengambil seluruh kunci permission yang aktif untuk [roleId] dalam 1 query.
  Future<Set<String>> getActivePermissions(String roleId) async {
    final rows = await _db.query(
      'role_permissions',
      columns: const ['permission_key'],
      where: 'role_id = ? AND is_active = 1',
      whereArgs: [roleId],
    );
    return {for (final row in rows) row['permission_key']! as String};
  }

  /// Helper untuk membuat [PermissionChecker] terikat pada satu [roleId].
  PermissionChecker checkerForRole(String roleId) {
    return (permissionKey) => hasPermission(roleId, permissionKey);
  }
}
