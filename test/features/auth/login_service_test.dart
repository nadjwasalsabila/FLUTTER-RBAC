import 'package:flutter_test/flutter_test.dart';
import 'package:rbac/features/auth/auth.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/test_database_helper.dart';

void main() {
  late Database db;
  late LoginService loginService;
  late AuthState authState;

  setUp(() async {
    db = await openTestWarehouseDb();
    loginService = LoginService(db);
    authState = AuthState(loginService);
  });

  tearDown(() async {
    await db.close();
  });

  test('UserSeeder seeds 3 deterministic demo accounts without duplication', () async {
    await const UserSeeder().seed(db);

    final users = await loginService.getUsers();
    expect(users.length, 3);
    expect(users[0].id, 1);
    expect(users[0].roleId, 'staff');
    expect(users[0].username, 'staff');
    expect(users[0].isActive, isTrue);
    expect(users[1].id, 2);
    expect(users[1].roleId, 'manager');
    expect(users[2].id, 3);
    expect(users[2].roleId, 'admin');
  });

  test('LoginService fetches staff by id, username, and email identifier', () async {
    final byId = await loginService.getUserById(1);
    final byUsername = await loginService.getUserByUsername('staff');
    final byEmail = await loginService.getUserByIdentifier('staff@gudang.demo');
    final missing = await loginService.getUserByUsername('unknown');

    expect(byId, isNotNull);
    expect(byId!.roleId, 'staff');
    expect(byUsername, byId);
    expect(byEmail, byId);
    expect(missing, isNull);
  });

  test('AuthState loginWithCredentials validates password and identifier', () async {
    final emptyPass = await authState.loginWithCredentials('staff@gudang.demo', '');
    expect(emptyPass, isNull);
    expect(authState.errorMessage, 'Password wajib diisi.');

    final staffUser = await authState.loginWithCredentials(
      'staff@gudang.demo',
      'demo123',
    );
    expect(staffUser?.roleId, 'staff');
    expect(authState.activeUser?.id, 1);
  });

  test('AuthState stores active user and supports switching demo accounts', () async {
    await authState.loadUsers();
    expect(authState.users.length, 3);

    final staffUser = await authState.loginById(1);
    expect(staffUser?.roleId, 'staff');
    expect(authState.activeUser?.id, 1);

    authState.switchAccount();
    expect(authState.activeUser, isNull);

    final managerUser = await authState.loginByUsername('manager');
    expect(managerUser?.roleId, 'manager');
    expect(authState.activeUser?.id, 2);
  });

  test('AuthState rejects inactive demo account', () {
    const inactive = AuthUser(
      id: 99,
      roleId: 'staff',
      fullName: 'Nonaktif',
      username: 'inactive',
      isActive: false,
    );

    final selected = authState.selectUser(inactive);
    expect(selected, isFalse);
    expect(authState.activeUser, isNull);
    expect(authState.errorMessage, isNotNull);
  });
}
