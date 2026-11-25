import 'package:sqflite/sqflite.dart';
import 'package:rbac/features/auth/types/auth_user.dart';

class RbacService {
  RbacService(this._db);

  final Database _db;

  Future<List<AuthUser>> getAllUsers() async {
    final result = await _db.query(
      'users',
      columns: const ['id', 'role_id', 'full_name', 'username', 'is_active'],
      orderBy: 'id ASC',
    );
    return result.map((row) => AuthUser.fromMap(row)).toList();
  }
}
