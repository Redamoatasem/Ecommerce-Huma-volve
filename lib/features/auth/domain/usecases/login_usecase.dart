import '../entities/auth_tokens_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  const LoginUseCase(this.repository);

  Future<AuthTokensEntity> call({
    required String email,
    required String password,
  }) async {
    return repository.login(email: email, password: password);
  }
}
