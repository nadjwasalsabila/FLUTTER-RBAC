import 'package:sqflite/sqflite.dart';

import '../../../core/rbac/permission_service.dart';
import '../models/warehouse_models.dart';

/// Service CRUD master barang dengan validasi izin RBAC di layer bisnis.
class ItemService {
  ItemService(
    this._db,
    this._checkPermission, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const readDeniedMessage =
      'Akses ditolak: Anda tidak memiliki izin item:read.';
  static const createDeniedMessage =
      'Akses ditolak: Anda tidak memiliki izin item:create.';
  static const deleteDeniedMessage =
      'Akses ditolak: Anda tidak memiliki izin item:delete.';

  final Database _db;
  final PermissionChecker _checkPermission;
  final DateTime Function() _now;

  Future<ItemsQueryResult> getItems() async {
    if (!await _checkPermission(AppPermissions.itemRead)) {
      return const ItemsQueryResult(
        allowed: false,
        items: [],
        errorMessage: readDeniedMessage,
      );
    }

    final rows = await _db.query(
      'warehouse_items',
      columns: const [
        'id',
        'sku',
        'name',
        'category',
        'location',
        'stock',
        'satuan',
        'min_stock',
        'updated_at',
      ],
      orderBy: 'sku ASC',
    );
    return ItemsQueryResult(
      allowed: true,
      items: rows.map(WarehouseItem.fromMap).toList(),
    );
  }

  Future<ItemActionResult> addItem(
    WarehouseItemInput input, {
    required int userId,
  }) async {
    if (!await _checkPermission(AppPermissions.itemCreate)) {
      return ItemActionResult.denied(createDeniedMessage);
    }

    final sku = input.sku.trim();
    final name = input.name.trim();
    final category = input.category.trim();
    final location = input.location.trim();

    if (sku.isEmpty || name.isEmpty || category.isEmpty || location.isEmpty) {
      return const ItemActionResult(
        success: false,
        message: 'Semua input wajib diisi.',
      );
    }

    if (input.stock < 0) {
      return const ItemActionResult(
        success: false,
        message: 'Stok awal tidak boleh negatif.',
      );
    }

    final existing = await _db.query(
      'warehouse_items',
      columns: const ['id'],
      where: 'sku = ?',
      whereArgs: [sku],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return ItemActionResult(
        success: false,
        message: 'SKU $sku sudah digunakan oleh barang lain.',
      );
    }

    final timestamp = _now().toIso8601String();
    try {
      await _db.transaction((txn) async {
        final itemId = await txn.insert('warehouse_items', {
          'sku': sku,
          'name': name,
          'category': category,
          'location': location,
          'stock': input.stock,
          'satuan': input.satuan.trim().isEmpty ? 'unit' : input.satuan.trim(),
          'min_stock': input.minStock < 0 ? 0 : input.minStock,
          'updated_at': timestamp,
        });

        if (input.stock != 0) {
          await txn.insert('stock_movements', {
            'item_id': itemId,
            'user_id': userId,
            'delta': input.stock,
            'reason': 'Stok awal',
            'created_at': timestamp,
          });
        }
      });

      return ItemActionResult(
        success: true,
        message: 'Barang $sku berhasil ditambahkan.',
      );
    } on DatabaseException {
      return const ItemActionResult(
        success: false,
        message: 'Gagal menyimpan barang ke database.',
      );
    }
  }

  /// Mengubah data barang (tanpa mengubah stok; stok melalui StockAdjustmentService).
  Future<ItemActionResult> updateItem({
    required int itemId,
    required String currentSku,
    required WarehouseItemInput input,
  }) async {
    if (!await _checkPermission(AppPermissions.itemCreate)) {
      return ItemActionResult.denied(createDeniedMessage);
    }

    final sku = input.sku.trim();
    final name = input.name.trim();
    final category = input.category.trim();
    final location = input.location.trim();

    if (sku.isEmpty || name.isEmpty || category.isEmpty || location.isEmpty) {
      return const ItemActionResult(
        success: false,
        message: 'Semua input wajib diisi.',
      );
    }

    final duplicate = await _db.query(
      'warehouse_items',
      columns: const ['id'],
      where: 'sku = ? AND id != ?',
      whereArgs: [sku, itemId],
      limit: 1,
    );
    if (duplicate.isNotEmpty) {
      return ItemActionResult(
        success: false,
        message: 'SKU $sku sudah digunakan oleh barang lain.',
      );
    }

    try {
      await _db.update(
        'warehouse_items',
        {
          'sku': sku,
          'name': name,
          'category': category,
          'location': location,
          'satuan': input.satuan.trim().isEmpty ? 'unit' : input.satuan.trim(),
          'min_stock': input.minStock < 0 ? 0 : input.minStock,
          'updated_at': _now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [itemId],
      );
      return ItemActionResult(
        success: true,
        message: currentSku == sku
            ? 'Barang $sku berhasil diperbarui.'
            : 'Barang $currentSku berhasil diperbarui menjadi $sku.',
      );
    } on DatabaseException {
      return const ItemActionResult(
        success: false,
        message: 'Gagal memperbarui barang di database.',
      );
    }
  }

  Future<ItemActionResult> deleteItem(int itemId, String sku) async {
    if (!await _checkPermission(AppPermissions.itemDelete)) {
      return ItemActionResult.denied(deleteDeniedMessage);
    }

    try {
      await _db.transaction((txn) async {
        // Hapus riwayat pergerakan terkait terlebih dahulu agar FK RESTRICT tidak gagal.
        await txn.delete(
          'stock_movements',
          where: 'item_id = ?',
          whereArgs: [itemId],
        );
        await txn.delete(
          'warehouse_items',
          where: 'id = ?',
          whereArgs: [itemId],
        );
      });
      return ItemActionResult(
        success: true,
        message: 'Barang $sku berhasil dihapus.',
      );
    } on DatabaseException {
      return const ItemActionResult(
        success: false,
        message: 'Gagal menghapus barang dari database.',
      );
    }
  }
}
