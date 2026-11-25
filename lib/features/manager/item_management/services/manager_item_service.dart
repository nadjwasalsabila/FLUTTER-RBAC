import 'package:sqflite/sqflite.dart';

import '../types/manager_models.dart';

class ManagerItemService {
  ManagerItemService(
    this._db,
    this._checkPermission, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const String readPermission = 'item:read';
  static const String createPermission = 'item:create';
  static const String deletePermission = 'item:delete';
  static const String readDeniedMessage =
      'Akses ditolak: Anda tidak memiliki izin item:read.';
  static const String createDeniedMessage =
      'Akses ditolak: Anda tidak memiliki izin item:create.';
  static const String deleteDeniedMessage =
      'Akses ditolak: Anda tidak memiliki izin item:delete.';

  final Database _db;
  final ManagerPermissionChecker _checkPermission;
  final DateTime Function() _now;

  Future<bool> hasPermission(String permissionKey) =>
      _checkPermission(permissionKey);

  Future<ManagerItemsResult> getItems() async {
    final allowed = await _checkPermission(readPermission);
    if (!allowed) {
      return const ManagerItemsResult(
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
        'updated_at',
      ],
      orderBy: 'sku ASC',
    );
    return ManagerItemsResult(
      allowed: true,
      items: rows.map(ManagerItem.fromMap).toList(),
    );
  }

  Future<ManagerItemResult> addItem(
    ManagerItemInput input, {
    required int userId,
  }) async {
    final allowed = await _checkPermission(createPermission);
    if (!allowed) {
      return ManagerItemResult.denied(createDeniedMessage);
    }

    final sku = input.sku.trim();
    final name = input.name.trim();
    final category = input.category.trim();
    final location = input.location.trim();

    if (sku.isEmpty ||
        name.isEmpty ||
        category.isEmpty ||
        location.isEmpty) {
      return const ManagerItemResult(
        success: false,
        message: 'Semua input wajib diisi.',
      );
    }

    if (input.stock < 0) {
      return const ManagerItemResult(
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
      return ManagerItemResult(
        success: false,
        message: 'SKU $sku sudah digunakan oleh barang lain.',
      );
    }

    final timestamp = _now().toIso8601String();
    try {
      final itemId = await _db.insert('warehouse_items', {
        'sku': sku,
        'name': name,
        'category': category,
        'location': location,
        'stock': input.stock,
        'updated_at': timestamp,
      });

      // Catat stok awal ke riwayat pergerakan agar konsisten dengan
      // perubahan stok yang dilakukan staff/manager.
      if (input.stock != 0) {
        await _db.insert('stock_movements', {
          'item_id': itemId,
          'user_id': userId,
          'delta': input.stock,
          'reason': 'Stok awal',
          'created_at': timestamp,
        });
      }

      return ManagerItemResult(
        success: true,
        message: 'Barang $sku berhasil ditambahkan.',
      );
    } on DatabaseException {
      return const ManagerItemResult(
        success: false,
        message: 'Gagal menyimpan barang ke database.',
      );
    }
  }

  /// Mengubah data barang (SKU, nama, kategori, lokasi).
  /// Stok TIDAK diubah di sini — perubahan stok harus melalui
  /// [StockAdjustmentService.adjustStock] agar tercatat di stock_movements.
  /// Memakai izin item:create (pembuat barang boleh mengubah datanya).
  Future<ManagerItemResult> updateItem({
    required int itemId,
    required String currentSku,
    required ManagerItemInput input,
  }) async {
    final allowed = await _checkPermission(createPermission);
    if (!allowed) {
      return ManagerItemResult.denied(createDeniedMessage);
    }

    final sku = input.sku.trim();
    final name = input.name.trim();
    final category = input.category.trim();
    final location = input.location.trim();

    if (sku.isEmpty ||
        name.isEmpty ||
        category.isEmpty ||
        location.isEmpty) {
      return const ManagerItemResult(
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
      return ManagerItemResult(
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
          'updated_at': _now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [itemId],
      );
      return ManagerItemResult(
        success: true,
        message: currentSku == sku
            ? 'Barang $sku berhasil diperbarui.'
            : 'Barang $currentSku berhasil diperbarui menjadi $sku.',
      );
    } on DatabaseException {
      return const ManagerItemResult(
        success: false,
        message: 'Gagal memperbarui barang di database.',
      );
    }
  }

  Future<ManagerItemResult> deleteItem(int itemId, String sku) async {
    final allowed = await _checkPermission(deletePermission);
    if (!allowed) {
      return ManagerItemResult.denied(deleteDeniedMessage);
    }

    try {
      await _db.delete(
        'warehouse_items',
        where: 'id = ?',
        whereArgs: [itemId],
      );
      return ManagerItemResult(
        success: true,
        message: 'Barang $sku berhasil dihapus.',
      );
    } on DatabaseException {
      return const ManagerItemResult(
        success: false,
        message: 'Gagal menghapus barang dari database.',
      );
    }
  }
}
