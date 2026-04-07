import 'package:mi_gym_flutter/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> login(String email, String password);
  Future<UserEntity?> signUp(String email, String password, String fullName);
  Future<UserEntity?> getCurrentUser();
  Future<void> logout();
}
