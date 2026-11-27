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

  Future<String?> getPasswordForUsername(String username) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final rows = await _db.query(
      'users',
      columns: const ['password'],
      where: 'LOWER(username) = ?',
      whereArgs: [normalized],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['password'] as String?;
  }

  /// Membuat akun baru. Mengembalikan error message jika gagal
  /// (username sudah dipakai, dll), null jika sukses.
  Future<String?> createUser({
    required String fullName,
    required String username,
    required String password,
    required String roleId,
  }) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty) return 'Username wajib diisi.';
    final existing = await getUserByUsername(normalized);
    if (existing != null) return 'Username "$normalized" sudah dipakai.';

    final roles = await _db.query(
      'roles',
      columns: const ['id'],
      where: 'id = ?',
      whereArgs: [roleId],
      limit: 1,
    );
    if (roles.isEmpty) return 'Role tidak valid.';

    await _db.insert('users', {
      'role_id': roleId,
      'full_name': fullName.trim(),
      'username': normalized,
      'is_active': 1,
      'password': password,
    });
    return null;
  }
}
