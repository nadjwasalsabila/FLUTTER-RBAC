class PermissionModel {
  final int id;
  final String name;

  PermissionModel({required this.id, required this.name});

  factory PermissionModel.fromMap(Map<String, dynamic> map) {
    return PermissionModel(id: map['id'] as int, name: map['name'] as String);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }
}
