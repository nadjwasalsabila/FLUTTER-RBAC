class UserModel {
  final int id;
  final String name;
  final int roleId;
  final String roleName;

  UserModel({
    required this.id,
    required this.name,
    required this.roleId,
    required this.roleName,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int,
      name: map['name'] as String,
      roleId: map['role_id'] as int,
      roleName: map['role_name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'role_id': roleId};
  }
}
