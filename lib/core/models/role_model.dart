class RoleModel {
  final int id;
  final String name;

  RoleModel({required this.id, required this.name});

  factory RoleModel.fromMap(Map<String, dynamic> map) {
    return RoleModel(id: map['id'] as int, name: map['name'] as String);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }
}
