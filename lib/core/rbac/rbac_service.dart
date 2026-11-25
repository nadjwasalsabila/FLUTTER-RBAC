import '../database/database_helper.dart';
import '../models/user_model.dart';

class RbacService {
  static final RbacService instance = RbacService._internal();
  RbacService._internal();

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  Future<List<UserModel>> getAllUsers() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT u.id, u.name, u.role_id, r.name as role_name
      FROM users u
      JOIN roles r ON r.id = u.role_id
    ''');
    return result.map((row) => UserModel.fromMap(row)).toList();
  }

  Future<void> setCurrentUser(UserModel user) async {
    _currentUser = user;
  }

  void clearCurrentUser() {
    _currentUser = null;
  }
}
