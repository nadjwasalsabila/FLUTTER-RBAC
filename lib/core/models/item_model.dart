class ItemModel {
  final int? id;
  final String sku;
  final String name;
  final String category;
  final String location;
  final int stock;

  ItemModel({
    this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.location,
    required this.stock,
  });

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'] as int?,
      sku: map['sku'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      location: map['location'] as String,
      stock: map['stock'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'sku': sku,
      'name': name,
      'category': category,
      'location': location,
      'stock': stock,
    };
    if (id != null) data['id'] = id;
    return data;
  }

  ItemModel copyWith({
    int? id,
    String? sku,
    String? name,
    String? category,
    String? location,
    int? stock,
  }) {
    return ItemModel(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      category: category ?? this.category,
      location: location ?? this.location,
      stock: stock ?? this.stock,
    );
  }
}
