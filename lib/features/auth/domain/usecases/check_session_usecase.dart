import '../repositories/auth_repository.dart';

class CheckSessionUseCase {
  final AuthRepository repository;

  const CheckSessionUseCase(this.repository);

  Future<bool> call() async {
    return repository.hasSession();
  }
}
