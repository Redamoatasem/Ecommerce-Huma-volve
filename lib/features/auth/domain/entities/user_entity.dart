class UserEntity {
  final int id;
  final String email;
  final String name;
  final String role;
  final String avatar;
  final DateTime? creationAt;
  final DateTime? updatedAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.avatar,
    this.creationAt,
    this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          name == other.name &&
          role == other.role &&
          avatar == other.avatar;

  @override
  int get hashCode => Object.hash(id, email, name, role, avatar);

  @override
  String toString() => 'UserEntity(id: $id, email: $email, name: $name)';
}
