/// Model barang gudang tunggal untuk seluruh peran (staff, manager, admin).
class WarehouseItem {
  const WarehouseItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.location,
    required this.stock,
    this.satuan = 'unit',
    this.minStock = 10,
    this.updatedAt = '',
  });

  final int id;
  final String sku;
  final String name;
  final String category;
  final String location;
  final int stock;
  final String satuan;
  final int minStock;
  final String updatedAt;

  bool get isLowStock => stock <= minStock;

  factory WarehouseItem.fromMap(Map<String, Object?> map) {
    return WarehouseItem(
      id: map['id']! as int,
      sku: map['sku']! as String,
      name: map['name']! as String,
      category: map['category']! as String,
      location: map['location']! as String,
      stock: map['stock']! as int,
      satuan: (map['satuan'] ?? 'unit') as String,
      minStock: (map['min_stock'] ?? 10) as int,
      updatedAt: (map['updated_at'] ?? '') as String,
    );
  }
}

class WarehouseItemInput {
  const WarehouseItemInput({
    required this.sku,
    required this.name,
    required this.category,
    required this.location,
    required this.stock,
    this.satuan = 'unit',
    this.minStock = 10,
  });

  final String sku;
  final String name;
  final String category;
  final String location;
  final int stock;
  final String satuan;
  final int minStock;
}

class ItemActionResult {
  const ItemActionResult({
    required this.success,
    required this.message,
    this.deniedByRbac = false,
  });

  final bool success;
  final String message;
  final bool deniedByRbac;

  factory ItemActionResult.denied(String message) {
    return ItemActionResult(
      success: false,
      message: message,
      deniedByRbac: true,
    );
  }
}

class ItemsQueryResult {
  const ItemsQueryResult({
    required this.allowed,
    required this.items,
    this.errorMessage,
  });

  final bool allowed;
  final List<WarehouseItem> items;
  final String? errorMessage;
}

enum StockAdjustmentType { increase, decrease }

class StockAdjustmentRequest {
  const StockAdjustmentRequest({
    required this.itemId,
    required this.userId,
    required this.type,
    required this.amount,
    required this.reason,
  });

  final int itemId;
  final int userId;
  final StockAdjustmentType type;
  final int amount;
  final String reason;
}

class StockAdjustmentInput {
  const StockAdjustmentInput({
    required this.type,
    required this.amount,
    required this.reason,
  });

  final StockAdjustmentType type;
  final int amount;
  final String reason;
}

class StockAdjustmentResult {
  const StockAdjustmentResult({
    required this.success,
    required this.message,
    this.updatedStock,
    this.deniedByRbac = false,
  });

  final bool success;
  final String message;
  final int? updatedStock;
  final bool deniedByRbac;

  factory StockAdjustmentResult.denied(String message) {
    return StockAdjustmentResult(
      success: false,
      message: message,
      deniedByRbac: true,
    );
  }
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.delta,
    required this.reason,
    required this.createdAt,
    required this.userName,
  });

  final int id;
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
