import 'package:mi_gym_flutter/domain/entities/user_entity.dart';
import 'package:mi_gym_flutter/domain/repositories/auth_repository.dart';
import 'package:mi_gym_flutter/services/supabase_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<UserEntity?> login(String email, String password) async {
    final response = await SupabaseService.signIn(
      email: email,
      password: password,
    );

    if (response.user == null) {
      return null;
    }

    final profile = await SupabaseService.getUserProfile(response.user!.id);
    if (profile == null) return null;

    return UserEntity(
      id: response.user!.id,
      email: response.user!.email ?? '',
      fullName: profile['full_name'],
      avatarUrl: profile['avatar_url'],
      role: profile['role'] == 'admin' ? UserRole.admin : UserRole.client,
    );
  }

  @override
  Future<UserEntity?> signUp(String email, String password, String fullName) async {
    final response = await SupabaseService.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );

    if (response.user == null) return null;

    return UserEntity(
      id: response.user!.id,
      email: email,
      fullName: fullName,
      role: UserRole.client,
    );
  }

  @override
  Future<void> logout() async {
    await SupabaseService.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;

    final profile = await SupabaseService.getUserProfile(user.id);
    if (profile == null) return null;

    return UserEntity(
      id: user.id,
      email: user.email ?? '',
      fullName: profile['full_name'],
      avatarUrl: profile['avatar_url'],
      role: profile['role'] == 'admin' ? UserRole.admin : UserRole.client,
    );
  }
}
