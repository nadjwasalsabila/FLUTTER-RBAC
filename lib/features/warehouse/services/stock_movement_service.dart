import 'package:sqflite/sqflite.dart';

import '../models/warehouse_models.dart';

/// Membaca riwayat pergerakan stok per barang untuk halaman detail.
class StockMovementService {
  StockMovementService(this._db);

  final Database _db;

  Future<List<StockMovement>> getMovements(int itemId, {int limit = 20}) async {
    final rows = await _db.rawQuery(
      '''
      SELECT m.id, m.delta, m.reason, m.created_at, u.full_name
      FROM stock_movements m
      LEFT JOIN users u ON u.id = m.user_id
      WHERE m.item_id = ?
      ORDER BY m.id DESC
      LIMIT ?
      ''',
      [itemId, limit],
    );
    return rows.map(StockMovement.fromMap).toList();
  }
}
