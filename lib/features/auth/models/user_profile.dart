import '../domain/entities/user_entity.dart';

class UserProfile extends UserEntity {
  const UserProfile({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    required super.avatar,
    super.creationAt,
    super.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      email: (json['email'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      role: (json['role'] as String?)?.trim() ?? 'customer',
      avatar: (json['avatar'] as String?)?.trim() ?? '',
      creationAt: json['creationAt'] != null
          ? DateTime.tryParse(json['creationAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role,
    'avatar': avatar,
    if (creationAt != null) 'creationAt': creationAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  UserEntity toEntity() => this;
}

typedef UserProfileModel = UserProfile;
