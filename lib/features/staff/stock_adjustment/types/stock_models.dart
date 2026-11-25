class WarehouseItem {
  const WarehouseItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.location,
    required this.stock,
    required this.updatedAt,
  });

  final int id;
  final String sku;
  final String name;
  final String category;
  final String location;
  final int stock;
  final String updatedAt;

  factory WarehouseItem.fromMap(Map<String, Object?> map) {
    return WarehouseItem(
      id: map['id']! as int,
      sku: map['sku']! as String,
      name: map['name']! as String,
      category: map['category']! as String,
      location: map['location']! as String,
      stock: map['stock']! as int,
      updatedAt: map['updated_at']! as String,
    );
  }
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

class StockPermissionDecision {
  const StockPermissionDecision({
    required this.allowed,
    this.missingPermission,
  });

  final bool allowed;
  final String? missingPermission;
}

typedef StaffPermissionChecker = Future<StockPermissionDecision> Function(
  String permissionKey,
);

class WarehouseItemsResult {
  const WarehouseItemsResult({
    required this.allowed,
    required this.items,
    this.errorMessage,
  });

  final bool allowed;
  final List<WarehouseItem> items;
  final String? errorMessage;
}
