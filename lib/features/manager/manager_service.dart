import '../../core/database/database_helper.dart';
import '../../core/models/item_model.dart';
import '../../core/rbac/rbac_evaluator.dart';

class ManagerService {
  static final ManagerService instance = ManagerService._internal();
  ManagerService._internal();

  Future<List<ItemModel>> getAllItems() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('warehouse_items', orderBy: 'sku ASC');
    return result.map((row) => ItemModel.fromMap(row)).toList();
  }

  Future<bool> isSkuExists(String sku, {int? excludeId}) async {
    final db = await DatabaseHelper.instance.database;
    final where =
        excludeId != null ? 'sku = ? AND id != ?' : 'sku = ?';
    final args = excludeId != null ? [sku, excludeId] : [sku];
    final result = await db.query(
      'warehouse_items',
      where: where,
      whereArgs: args,
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<String?> addItem(int userId, ItemModel item) async {
    final canCreate = await RbacEvaluator.instance.hasPermission(
      userId,
      'item:create',
    );
    if (!canCreate) {
      return 'Akses ditolak: Anda tidak memiliki izin item:create.';
    }

    if (item.sku.trim().isEmpty ||
        item.name.trim().isEmpty ||
        item.category.trim().isEmpty ||
        item.location.trim().isEmpty) {
      return 'Semua input wajib diisi.';
    }

    if (item.stock < 0) {
      return 'Stok awal tidak boleh negatif.';
    }

    final skuExists = await isSkuExists(item.sku.trim());
    if (skuExists) {
      return 'SKU ${item.sku} sudah digunakan oleh barang lain.';
    }

    final db = await DatabaseHelper.instance.database;
    await db.insert('warehouse_items', {
      'sku': item.sku.trim(),
      'name': item.name.trim(),
      'category': item.category.trim(),
      'location': item.location.trim(),
      'stock': item.stock,
    });

    return null;
  }

  Future<String?> deleteItem(int userId, int itemId, String itemSku) async {
    final canDelete = await RbacEvaluator.instance.hasPermission(
      userId,
      'item:delete',
    );
    if (!canDelete) {
      return 'Akses ditolak: Anda tidak memiliki izin item:delete.';
    }

    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'warehouse_items',
      where: 'id = ?',
      whereArgs: [itemId],
    );

    return null;
  }
}
