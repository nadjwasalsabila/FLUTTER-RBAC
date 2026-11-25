import 'package:sqflite/sqflite.dart';

import '../types/auth_user.dart';

class UserSeeder {
  const UserSeeder();

  static const List<AuthUser> defaultUsers = [
    AuthUser(
      id: 1,
      roleId: 'staff',
      fullName: 'Petugas Gudang',
      username: 'staff',
      isActive: true,
    ),
    AuthUser(
      id: 2,
      roleId: 'manager',
      fullName: 'Kepala Gudang',
      username: 'manager',
      isActive: true,
    ),
    AuthUser(
      id: 3,
      roleId: 'admin',
      fullName: 'Admin Sistem',
      username: 'admin',
      isActive: true,
    ),
  ];

  Future<void> seed(DatabaseExecutor db) async {
    for (final user in defaultUsers) {
      await db.insert(
        'users',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }
}
