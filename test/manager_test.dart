import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:rbac/core/database/database_helper.dart';
import 'package:rbac/core/models/item_model.dart';
import 'package:rbac/core/rbac/rbac_evaluator.dart';
import 'package:rbac/core/rbac/rbac_service.dart';
import 'package:rbac/features/manager/manager_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  group('Database Seed', () {
    test('tables and seed data are created', () async {
      final db = await DatabaseHelper.instance.database;
      final roles = await db.query('roles');
      expect(roles.length, 3);

      final users = await db.query('users');
      expect(users.length, 3);

      final perms = await db.query('permissions');
      expect(perms.length, 5);

      final items = await db.query('warehouse_items');
      expect(items.length, 15);
    });
  });

  group('RbacEvaluator', () {
    test('Manager has item:create permission', () async {
      final has = await RbacEvaluator.instance.hasPermission(2, 'item:create');
      expect(has, true);
    });

    test('Manager has item:delete permission', () async {
      final has = await RbacEvaluator.instance.hasPermission(2, 'item:delete');
      expect(has, true);
    });

    test('Staff does NOT have item:create permission', () async {
      final has = await RbacEvaluator.instance.hasPermission(1, 'item:create');
      expect(has, false);
    });

    test('Staff does NOT have item:delete permission', () async {
      final has = await RbacEvaluator.instance.hasPermission(1, 'item:delete');
      expect(has, false);
    });

    test('Admin has all permissions', () async {
      final perms = await RbacEvaluator.instance.getPermissions(3);
      expect(perms, containsAll(['item:create', 'item:delete', 'policy:edit']));
    });
  });

  group('RbacService', () {
    test('getAllUsers returns 3 users', () async {
      final users = await RbacService.instance.getAllUsers();
      expect(users.length, 3);
    });

    test('setCurrentUser updates currentUser', () async {
      final users = await RbacService.instance.getAllUsers();
      await RbacService.instance.setCurrentUser(users[1]);
      expect(RbacService.instance.currentUser, isNotNull);
      expect(RbacService.instance.currentUser!.roleName, 'Manager');
    });
  });

  group('ManagerService', () {
    test('getAllItems returns 15 items', () async {
      final items = await ManagerService.instance.getAllItems();
      expect(items.length, 15);
    });

    test('Manager can add new item', () async {
      final error = await ManagerService.instance.addItem(
        2,
        ItemModel(sku: 'SKU-TEST', name: 'Barang Test', category: 'Test', location: 'Rak X', stock: 10),
      );
      expect(error, isNull);

      final items = await ManagerService.instance.getAllItems();
      expect(items.length, 16);
    });

    test('addItem rejects duplicate SKU', () async {
      final error = await ManagerService.instance.addItem(
        2,
        ItemModel(sku: 'SKU-001', name: 'Duplikat', category: 'Test', location: 'Rak X', stock: 5),
      );
      expect(error, isNotNull);
      expect(error, contains('SKU-001'));
    });

    test('addItem rejects negative stock', () async {
      final error = await ManagerService.instance.addItem(
        2,
        ItemModel(sku: 'SKU-NEG', name: 'Negatif', category: 'Test', location: 'Rak X', stock: -1),
      );
      expect(error, isNotNull);
      expect(error, contains('negatif'));
    });

    test('addItem rejects empty SKU', () async {
      final error = await ManagerService.instance.addItem(
        2,
        ItemModel(sku: '', name: 'Barang Kosong', category: 'Test', location: 'Rak X', stock: 5),
      );
      expect(error, isNotNull);
    });

    test('Staff cannot add item (no item:create)', () async {
      final error = await ManagerService.instance.addItem(
        1,
        ItemModel(sku: 'SKU-STAFF', name: 'Staff Test', category: 'Test', location: 'Rak X', stock: 5),
      );
      expect(error, isNotNull);
      expect(error, contains('item:create'));
    });

    test('Manager can delete item', () async {
      final items = await ManagerService.instance.getAllItems();
      final first = items.first;
      final error = await ManagerService.instance.deleteItem(
        2,
        first.id!,
        first.sku,
      );
      expect(error, isNull);

      final updated = await ManagerService.instance.getAllItems();
      expect(updated.length, items.length - 1);
    });

    test('Staff cannot delete item (no item:delete)', () async {
      final items = await ManagerService.instance.getAllItems();
      final first = items.first;
      final error = await ManagerService.instance.deleteItem(
        1,
        first.id!,
        first.sku,
      );
      expect(error, isNotNull);
      expect(error, contains('item:delete'));
    });
  });
}
