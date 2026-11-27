import 'package:flutter_test/flutter_test.dart';
import 'package:rbac/core/rbac/permission_service.dart';
import 'package:rbac/features/warehouse/warehouse.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/test_database_helper.dart';

void main() {
  late Database db;
  late PermissionService permissionService;

  setUp(() async {
    db = await openTestWarehouseDb();
    permissionService = PermissionService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('PermissionService', () {
    test('returns expected active permissions per role', () async {
      expect(
        await permissionService.getActivePermissions('staff'),
        {AppPermissions.itemRead, AppPermissions.stockAdjust},
      );
      expect(
        await permissionService.getActivePermissions('manager'),
        {
          AppPermissions.itemRead,
          AppPermissions.stockAdjust,
          AppPermissions.itemCreate,
          AppPermissions.itemDelete,
        },
      );
      expect(
        await permissionService.getActivePermissions('admin'),
        {
          AppPermissions.itemRead,
          AppPermissions.stockAdjust,
          AppPermissions.itemCreate,
          AppPermissions.itemDelete,
          AppPermissions.policyEdit,
        },
      );
    });

    test('respects is_active = 0 when permission is toggled off', () async {
      await db.update(
        'role_permissions',
        {'is_active': 0},
        where: 'role_id = ? AND permission_key = ?',
        whereArgs: ['staff', AppPermissions.stockAdjust],
      );

      expect(
        await permissionService.hasPermission('staff', AppPermissions.stockAdjust),
        isFalse,
      );
      expect(
        await permissionService.hasPermission('staff', AppPermissions.itemRead),
        isTrue,
      );
    });
  });

  group('ItemService', () {
    test('getItems returns seeded items when item:read is allowed', () async {
      final service = ItemService(db, buildDbPermissionChecker(db, 'staff'));
      final result = await service.getItems();

      expect(result.allowed, isTrue);
      expect(result.items.length, 2);
      expect(result.items.first.sku, 'SKU-1001');
    });

    test('getItems is denied when item:read is revoked', () async {
      await db.update(
        'role_permissions',
        {'is_active': 0},
        where: 'role_id = ? AND permission_key = ?',
        whereArgs: ['staff', AppPermissions.itemRead],
      );
      final service = ItemService(db, buildDbPermissionChecker(db, 'staff'));
      final result = await service.getItems();

      expect(result.allowed, isFalse);
      expect(result.items, isEmpty);
      expect(result.errorMessage, contains('item:read'));
    });

    test('manager can add, update, and delete items', () async {
      final service = ItemService(
        db,
        buildDbPermissionChecker(db, 'manager'),
        now: () => DateTime(2026, 11, 25, 19, 30),
      );

      final addResult = await service.addItem(
        const WarehouseItemInput(
          sku: 'SKU-2001',
          name: 'Helm Safety Proyek',
          category: 'APD',
          location: 'Aisle D-01',
          stock: 15,
          satuan: 'unit',
          minStock: 5,
        ),
        userId: 2,
      );
      expect(addResult.success, isTrue);

      final listAfterAdd = await service.getItems();
      expect(listAfterAdd.items.length, 3);
      final created = listAfterAdd.items.firstWhere((i) => i.sku == 'SKU-2001');

      final updateResult = await service.updateItem(
        itemId: created.id,
        currentSku: created.sku,
        input: const WarehouseItemInput(
          sku: 'SKU-2001',
          name: 'Helm Safety Proyek Kuning',
          category: 'APD',
          location: 'Aisle D-02',
          stock: 15,
          satuan: 'unit',
          minStock: 5,
        ),
      );
      expect(updateResult.success, isTrue);

      // Pastikan penghapusan berhasil meski item punya riwayat stock_movements.
      final deleteResult = await service.deleteItem(created.id, created.sku);
      expect(deleteResult.success, isTrue);

      final listAfterDelete = await service.getItems();
      expect(listAfterDelete.items.length, 2);
    });

    test('addItem validates duplicate SKU, empty fields, and negative stock', () async {
      final service = ItemService(db, buildDbPermissionChecker(db, 'manager'));

      final duplicate = await service.addItem(
        const WarehouseItemInput(
          sku: 'SKU-1001',
          name: 'Duplikat',
          category: 'Test',
          location: 'Rak X',
          stock: 5,
        ),
        userId: 2,
      );
      expect(duplicate.success, isFalse);
      expect(duplicate.message, contains('SKU-1001'));

      final negative = await service.addItem(
        const WarehouseItemInput(
          sku: 'SKU-NEG',
          name: 'Negatif',
          category: 'Test',
          location: 'Rak X',
          stock: -1,
        ),
        userId: 2,
      );
      expect(negative.success, isFalse);

      final empty = await service.addItem(
        const WarehouseItemInput(
          sku: '',
          name: 'Kosong',
          category: 'Test',
          location: 'Rak X',
          stock: 5,
        ),
        userId: 2,
      );
      expect(empty.success, isFalse);
    });

    test('staff cannot add or delete items without permissions', () async {
      final service = ItemService(db, buildDbPermissionChecker(db, 'staff'));

      final addResult = await service.addItem(
        const WarehouseItemInput(
          sku: 'SKU-STAFF',
          name: 'Tidak Boleh',
          category: 'Test',
          location: 'Rak X',
          stock: 5,
        ),
        userId: 1,
      );
      expect(addResult.success, isFalse);
      expect(addResult.deniedByRbac, isTrue);

      final deleteResult = await service.deleteItem(1, 'SKU-1001');
      expect(deleteResult.success, isFalse);
      expect(deleteResult.deniedByRbac, isTrue);
    });
  });

  group('StockAdjustmentService', () {
    late StockAdjustmentService service;

    setUp(() {
      service = StockAdjustmentService(
        db,
        buildDbPermissionChecker(db, 'staff'),
        now: () => DateTime(2026, 11, 25, 19, 30),
      );
    });

    test('increases stock and logs movement in one transaction', () async {
      final result = await service.adjustStock(
        const StockAdjustmentRequest(
          itemId: 1,
          userId: 1,
          type: StockAdjustmentType.increase,
          amount: 5,
          reason: 'Barang masuk',
        ),
      );

      expect(result.success, isTrue);
      expect(result.updatedStock, 15);

      final movements = await db.query('stock_movements');
      expect(movements.length, 1);
      expect(movements.first['delta'], 5);
      expect(movements.first['created_at'], '2026-11-25T19:30:00.000');
    });

    test('decreases stock with negative delta', () async {
      final result = await service.adjustStock(
        const StockAdjustmentRequest(
          itemId: 1,
          userId: 1,
          type: StockAdjustmentType.decrease,
          amount: 4,
          reason: 'Barang keluar',
        ),
      );

      expect(result.success, isTrue);
      expect(result.updatedStock, 6);

      final movements = await db.query('stock_movements');
      expect(movements.first['delta'], -4);
    });

    test('prevents non-positive amount and negative final stock', () async {
      final zeroResult = await service.adjustStock(
        const StockAdjustmentRequest(
          itemId: 1,
          userId: 1,
          type: StockAdjustmentType.increase,
          amount: 0,
          reason: 'Koreksi stok',
        ),
      );
      expect(zeroResult.success, isFalse);

      final overDecrease = await service.adjustStock(
        const StockAdjustmentRequest(
          itemId: 1,
          userId: 1,
          type: StockAdjustmentType.decrease,
          amount: 50,
          reason: 'Barang keluar',
        ),
      );
      expect(overDecrease.success, isFalse);
      expect(await db.query('stock_movements'), isEmpty);
    });

    test('denies action when stock:adjust permission is missing', () async {
      await db.update(
        'role_permissions',
        {'is_active': 0},
        where: 'role_id = ? AND permission_key = ?',
        whereArgs: ['staff', AppPermissions.stockAdjust],
      );

      final result = await service.adjustStock(
        const StockAdjustmentRequest(
          itemId: 1,
          userId: 1,
          type: StockAdjustmentType.increase,
          amount: 3,
          reason: 'Barang masuk',
        ),
      );

      expect(result.success, isFalse);
      expect(result.deniedByRbac, isTrue);
      expect(result.message, StockAdjustmentService.adjustDeniedMessage);
    });

    test('rolls back warehouse_items when movement insert fails', () async {
      final result = await service.adjustStock(
        const StockAdjustmentRequest(
          itemId: 1,
          userId: 999,
          type: StockAdjustmentType.increase,
          amount: 2,
          reason: 'Barang masuk',
        ),
      );

      expect(result.success, isFalse);
      final items = await db.query(
        'warehouse_items',
        where: 'id = ?',
        whereArgs: [1],
      );
      expect(items.first['stock'], 10);
      expect(await db.query('stock_movements'), isEmpty);
    });
  });
}
