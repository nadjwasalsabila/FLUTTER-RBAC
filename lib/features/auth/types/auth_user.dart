class AuthUser {
  const AuthUser({
    required this.id,
    required this.roleId,
    required this.fullName,
    required this.username,
    required this.isActive,
  });

  final int id;
  final String roleId;
  final String fullName;
  final String username;
  final bool isActive;

  factory AuthUser.fromMap(Map<String, Object?> map) {
    return AuthUser(
      id: map['id']! as int,
      roleId: map['role_id']! as String,
      fullName: map['full_name']! as String,
      username: map['username']! as String,
      isActive: (map['is_active']! as int) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'role_id': roleId,
      'full_name': fullName,
      'username': username,
      'is_active': isActive ? 1 : 0,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthUser &&
        other.id == id &&
        other.roleId == roleId &&
        other.fullName == fullName &&
        other.username == username &&
        other.isActive == isActive;
  }

  @override
  int get hashCode => Object.hash(id, roleId, fullName, username, isActive);
}
