import 'package:flutter_test/flutter_test.dart';
import 'package:rbac/features/staff/stock_adjustment/stock_adjustment.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/test_database_helper.dart';

void main() {
  late Database db;
  late StockAdjustmentService service;

  setUp(() async {
    db = await openTestWarehouseDb();
    service = StockAdjustmentService(
      db,
      buildDbPermissionChecker(db, 'staff'),
      now: () => DateTime(2026, 11, 25, 19, 30),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('getItems returns seeded items when item:read is allowed', () async {
    final result = await service.getItems();
    expect(result.allowed, isTrue);
    expect(result.items.length, 2);
  });

  test('getItems is denied when item:read is revoked', () async {
    await db.delete(
      'role_permissions',
      where: 'role_id = ? AND permission_key = ?',
      whereArgs: ['staff', 'item:read'],
    );

    final result = await service.getItems();
    expect(result.allowed, isFalse);
    expect(result.items, isEmpty);
    expect(result.errorMessage, contains('item:read'));
  });

  test('adjustStock increases stock and logs movement in one transaction', () async {
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

    final items = await db.query(
      'warehouse_items',
      where: 'id = ?',
      whereArgs: [1],
    );
    expect(items.first['stock'], 15);

    final movements = await db.query('stock_movements');
    expect(movements.length, 1);
    expect(movements.first['item_id'], 1);
    expect(movements.first['user_id'], 1);
    expect(movements.first['delta'], 5);
    expect(movements.first['reason'], 'Barang masuk');
    expect(movements.first['created_at'], '2026-11-25T19:30:00.000');
  });

  test('adjustStock decreases stock with negative delta', () async {
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
    expect(movements.length, 1);
    expect(movements.first['delta'], -4);
  });

  test('adjustStock prevents non-positive amount and negative stock', () async {
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

    final items = await db.query(
      'warehouse_items',
      where: 'id = ?',
      whereArgs: [1],
    );
    expect(items.first['stock'], 10);
    expect(await db.query('stock_movements'), isEmpty);
  });

  test('adjustStock denies action when stock:adjust permission is missing', () async {
    await db.delete(
      'role_permissions',
      where: 'role_id = ? AND permission_key = ?',
      whereArgs: ['staff', 'stock:adjust'],
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
    expect(
      result.message,
      'Akses ditolak: Anda tidak memiliki izin stock:adjust.',
    );

    final items = await db.query(
      'warehouse_items',
      where: 'id = ?',
      whereArgs: [1],
    );
    expect(items.first['stock'], 10);
    expect(await db.query('stock_movements'), isEmpty);
  });

  test('adjustStock rolls back warehouse_items when movement insert fails', () async {
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
}
