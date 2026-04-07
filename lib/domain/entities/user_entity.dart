enum UserRole { admin, client }

class UserEntity {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final UserRole role;

  const UserEntity({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.role = UserRole.client,
  });

  bool get isAdmin => role == UserRole.admin;
}
