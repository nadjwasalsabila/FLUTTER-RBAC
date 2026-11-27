import 'package:sqflite/sqflite.dart';

import '../types/stock_models.dart';

class StockAdjustmentService {
  StockAdjustmentService(
    this._db,
    this._checkPermission, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const String adjustPermission = 'stock:adjust';
  static const String readPermission = 'item:read';
  static const String adjustDeniedMessage =
      'Akses ditolak: Anda tidak memiliki izin stock:adjust.';
  static const String readDeniedMessage =
      'Akses ditolak: Anda tidak memiliki izin item:read.';

  final Database _db;
  final StaffPermissionChecker _checkPermission;
  final DateTime Function() _now;

  /// Dipakai UI untuk memutuskan apakah aksi tertentu boleh ditampilkan.
  Future<StockPermissionDecision> checkPermission(String permissionKey) {
    return _checkPermission(permissionKey);
  }

  Future<WarehouseItemsResult> getItems() async {
    final decision = await _checkPermission(readPermission);
    if (!decision.allowed) {
      return const WarehouseItemsResult(
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
      orderBy: 'name ASC',
    );
    return WarehouseItemsResult(
      allowed: true,
      items: rows.map(WarehouseItem.fromMap).toList(),
    );
  }

  Future<StockAdjustmentResult> adjustStock(
    StockAdjustmentRequest request,
  ) async {
    final decision = await _checkPermission(adjustPermission);
    if (!decision.allowed) {
      return StockAdjustmentResult.denied(adjustDeniedMessage);
    }

    if (request.amount <= 0) {
      return const StockAdjustmentResult(
        success: false,
        message: 'Jumlah perubahan harus lebih dari 0.',
      );
    }

    final trimmedReason = request.reason.trim();
    if (trimmedReason.isEmpty) {
      return const StockAdjustmentResult(
        success: false,
        message: 'Alasan perubahan wajib diisi.',
      );
    }

    try {
      return await _db.transaction((txn) async {
        final itemRows = await txn.query(
          'warehouse_items',
          columns: const ['stock'],
          where: 'id = ?',
          whereArgs: [request.itemId],
          limit: 1,
        );
        if (itemRows.isEmpty) {
          return const StockAdjustmentResult(
            success: false,
            message: 'Barang tidak ditemukan.',
          );
        }

        final currentStock = itemRows.first['stock']! as int;
        final delta = request.type == StockAdjustmentType.increase
            ? request.amount
            : -request.amount;
        final nextStock = currentStock + delta;

        if (nextStock < 0) {
          return const StockAdjustmentResult(
            success: false,
            message: 'Stok tidak mencukupi. Stok akhir tidak boleh negatif.',
          );
        }

        final timestamp = _now().toIso8601String();
        await txn.update(
          'warehouse_items',
          {'stock': nextStock, 'updated_at': timestamp},
          where: 'id = ?',
          whereArgs: [request.itemId],
        );

        await txn.insert('stock_movements', {
          'item_id': request.itemId,
          'user_id': request.userId,
          'delta': delta,
          'reason': trimmedReason,
          'created_at': timestamp,
        });

        return StockAdjustmentResult(
          success: true,
          message: 'Stok berhasil diperbarui.',
          updatedStock: nextStock,
        );
      });
    } on DatabaseException {
      return const StockAdjustmentResult(
        success: false,
        message: 'Gagal menyimpan perubahan stok ke database.',
      );
    }
  }
}
