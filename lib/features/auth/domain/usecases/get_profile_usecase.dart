import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class GetProfileUseCase {
  final AuthRepository repository;

  const GetProfileUseCase(this.repository);

  Future<UserEntity> call({String? explicitToken}) async {
    return repository.getProfile(explicitToken: explicitToken);
  }
}
