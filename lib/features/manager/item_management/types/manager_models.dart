class ManagerItem {
  const ManagerItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.location,
    required this.stock,
  });

  final int id;
  final String sku;
  final String name;
  final String category;
  final String location;
  final int stock;

  factory ManagerItem.fromMap(Map<String, Object?> map) {
    return ManagerItem(
      id: map['id']! as int,
      sku: map['sku']! as String,
      name: map['name']! as String,
      category: map['category']! as String,
      location: map['location']! as String,
      stock: map['stock']! as int,
    );
  }
}

class ManagerItemInput {
  const ManagerItemInput({
    required this.sku,
    required this.name,
    required this.category,
    required this.location,
    required this.stock,
  });

  final String sku;
  final String name;
  final String category;
  final String location;
  final int stock;
}

class ManagerItemResult {
  const ManagerItemResult({
    required this.success,
    required this.message,
    this.deniedByRbac = false,
  });

  final bool success;
  final String message;
  final bool deniedByRbac;

  factory ManagerItemResult.denied(String message) {
    return ManagerItemResult(
      success: false,
      message: message,
      deniedByRbac: true,
    );
  }
}

class ManagerItemsResult {
  const ManagerItemsResult({
    required this.allowed,
    required this.items,
    this.errorMessage,
  });

  final bool allowed;
  final List<ManagerItem> items;
  final String? errorMessage;
}

typedef ManagerPermissionChecker = Future<bool> Function(
  String permissionKey,
);
