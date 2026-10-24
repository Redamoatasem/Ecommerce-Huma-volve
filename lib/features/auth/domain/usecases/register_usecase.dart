import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  const RegisterUseCase(this.repository);

  Future<UserEntity> call({
    required String name,
    required String email,
    required String password,
    String? avatar,
  }) async {
    return repository.register(
      name: name,
      email: email,
      password: password,
      avatar: avatar,
    );
  }
}
