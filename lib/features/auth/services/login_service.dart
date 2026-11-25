import 'package:sqflite/sqflite.dart';

import '../types/auth_user.dart';

class LoginService {
  LoginService(this._db);

  final DatabaseExecutor _db;

  Future<List<AuthUser>> getUsers() async {
    final rows = await _db.query(
      'users',
      columns: const ['id', 'role_id', 'full_name', 'username', 'is_active'],
      orderBy: 'id ASC',
    );
    return rows.map(AuthUser.fromMap).toList();
  }

  Future<AuthUser?> getUserById(int id) async {
    final rows = await _db.query(
      'users',
      columns: const ['id', 'role_id', 'full_name', 'username', 'is_active'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AuthUser.fromMap(rows.first);
  }

  Future<AuthUser?> getUserByUsername(String username) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    final rows = await _db.query(
      'users',
      columns: const ['id', 'role_id', 'full_name', 'username', 'is_active'],
      where: 'LOWER(username) = ?',
      whereArgs: [normalized],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AuthUser.fromMap(rows.first);
  }

  Future<AuthUser?> getUserByIdentifier(String identifier) async {
    final trimmed = identifier.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    final username = trimmed.contains('@') ? trimmed.split('@').first : trimmed;
    return getUserByUsername(username);
  }
}
