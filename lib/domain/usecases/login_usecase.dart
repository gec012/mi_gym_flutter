import 'package:mi_gym_flutter/domain/entities/user_entity.dart';
import 'package:mi_gym_flutter/domain/repositories/auth_repository.dart';

abstract class LoginUseCase {
  Future<UserEntity?> execute(String email, String password);
  Future<void> logout();
}

class LoginUseCaseImpl implements LoginUseCase {
  final AuthRepository repository;

  LoginUseCaseImpl(this.repository);

  @override
  Future<UserEntity?> execute(String email, String password) {
    return repository.login(email, password);
  }

  @override
  Future<void> logout() {
    return repository.logout();
  }
}
