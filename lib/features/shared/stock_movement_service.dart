import 'package:sqflite/sqflite.dart';

class StockMovement {
  const StockMovement({
    required this.id,
    required this.delta,
    required this.reason,
    required this.createdAt,
    required this.userName,
  });

  final int id;

  /// Perubahan stok: positif = masuk, negatif = keluar.
  final int delta;
  final String reason;
  final String createdAt;
  final String userName;

  factory StockMovement.fromMap(Map<String, Object?> map) {
    return StockMovement(
      id: map['id']! as int,
      delta: map['delta']! as int,
      reason: map['reason']! as String,
      createdAt: map['created_at']! as String,
      userName: (map['full_name'] ?? 'Tidak diketahui') as String,
    );
  }
}

/// Membaca riwayat pergerakan stok per barang untuk halaman detail.
/// Read-only: tidak butuh izin khusus di luar item:read.
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
