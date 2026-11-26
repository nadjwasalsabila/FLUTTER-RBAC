import 'package:sqflite/sqflite.dart';

import '../../core/rbac/rbac_evaluator.dart';

class ManagerService {
  ManagerService(this._db);

  final Database _db;

  Future<List<Map<String, Object?>>> getAllItems() async {
    final result = await _db.query('warehouse_items', orderBy: 'sku ASC');
    return result;
  }

  Future<bool> isSkuExists(String sku, {int? excludeId}) async {
    final where =
        excludeId != null ? 'sku = ? AND id != ?' : 'sku = ?';
    final args = excludeId != null ? [sku, excludeId] : [sku];
    final result = await _db.query(
      'warehouse_items',
      where: where,
      whereArgs: args,
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<String?> addItem(int userId, Map<String, Object?> item) async {
    final canCreate = await RbacEvaluator(_db).hasPermission(
      userId,
      'item:create',
    );
    if (!canCreate) {
      return 'Akses ditolak: Anda tidak memiliki izin item:create.';
    }

    if (item['sku']!.toString().trim().isEmpty ||
        item['name']!.toString().trim().isEmpty ||
        item['category']!.toString().trim().isEmpty ||
        item['location']!.toString().trim().isEmpty) {
      return 'Semua input wajib diisi.';
    }

    if (((item['stock'] as int?) ?? 0) < 0) {
      return 'Stok awal tidak boleh negatif.';
    }

    final skuExists = await isSkuExists(item['sku']!.toString().trim());
    if (skuExists) {
      return 'SKU ${item['sku']} sudah digunakan oleh barang lain.';
    }

    await _db.insert('warehouse_items', {
      'sku': item['sku']!.toString().trim(),
      'name': item['name']!.toString().trim(),
      'category': item['category']!.toString().trim(),
      'location': item['location']!.toString().trim(),
      'stock': item['stock'],
    });

    return null;
  }

  Future<String?> deleteItem(int userId, int itemId, String itemSku) async {
    final canDelete = await RbacEvaluator(_db).hasPermission(
      userId,
      'item:delete',
    );
    if (!canDelete) {
      return 'Akses ditolak: Anda tidak memiliki izin item:delete.';
    }

    await _db.delete(
      'warehouse_items',
      where: 'id = ?',
      whereArgs: [itemId],
    );

    return null;
  }
}
