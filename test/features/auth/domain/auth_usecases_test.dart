import 'package:ecommerce_app_huma_volve/features/auth/domain/entities/auth_tokens_entity.dart';
import 'package:ecommerce_app_huma_volve/features/auth/domain/entities/user_entity.dart';
import 'package:ecommerce_app_huma_volve/features/auth/domain/repositories/auth_repository.dart';
import 'package:ecommerce_app_huma_volve/features/auth/domain/usecases/check_session_usecase.dart';
import 'package:ecommerce_app_huma_volve/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:ecommerce_app_huma_volve/features/auth/domain/usecases/login_usecase.dart';
import 'package:ecommerce_app_huma_volve/features/auth/domain/usecases/logout_usecase.dart';
import 'package:ecommerce_app_huma_volve/features/auth/domain/usecases/register_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements AuthRepository {
  String? lastLoginEmail;
  String? lastLoginPassword;
  String? lastRegisterName;
  String? lastRegisterEmail;
  String? lastRegisterPassword;
  String? lastExplicitToken;
  bool loggedOut = false;
  bool sessionActive = false;

  final sampleTokens = const AuthTokensEntity(
    accessToken: 'test-access-token',
    refreshToken: 'test-refresh-token',
  );

  final sampleUser = const UserEntity(
    id: 1,
    email: 'john@mail.com',
    name: 'John Doe',
    role: 'customer',
    avatar: 'https://placehold.co/100',
  );

  @override
  Future<AuthTokensEntity> login({
    required String email,
    required String password,
  }) async {
    lastLoginEmail = email;
    lastLoginPassword = password;
    return sampleTokens;
  }

  @override
  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
    String? avatar,
  }) async {
    lastRegisterName = name;
    lastRegisterEmail = email;
    lastRegisterPassword = password;
    return sampleUser;
  }

  @override
  Future<UserEntity> getProfile({String? explicitToken}) async {
    lastExplicitToken = explicitToken;
    return sampleUser;
  }

  @override
  Future<bool> hasSession() async {
    return sessionActive;
  }

  @override
  Future<void> logout() async {
    loggedOut = true;
  }
}

void main() {
  late FakeAuthRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeAuthRepository();
  });

  group('Auth Domain Use Cases', () {
    test('LoginUseCase calls repository.login and returns tokens', () async {
      final useCase = LoginUseCase(fakeRepository);
      final result = await useCase(
        email: 'user@example.com',
        password: 'password123',
      );

      expect(fakeRepository.lastLoginEmail, 'user@example.com');
      expect(fakeRepository.lastLoginPassword, 'password123');
      expect(result.accessToken, 'test-access-token');
      expect(result.refreshToken, 'test-refresh-token');
    });

    test(
      'RegisterUseCase calls repository.register and returns user',
      () async {
        final useCase = RegisterUseCase(fakeRepository);
        final result = await useCase(
          name: 'Jane Doe',
          email: 'jane@example.com',
          password: 'securePassword!',
        );

        expect(fakeRepository.lastRegisterName, 'Jane Doe');
        expect(fakeRepository.lastRegisterEmail, 'jane@example.com');
        expect(fakeRepository.lastRegisterPassword, 'securePassword!');
        expect(result.name, 'John Doe');
        expect(result.id, 1);
      },
    );

    test(
      'GetProfileUseCase calls repository.getProfile and returns user',
      () async {
        final useCase = GetProfileUseCase(fakeRepository);
        final result = await useCase(explicitToken: 'custom-token');

        expect(fakeRepository.lastExplicitToken, 'custom-token');
        expect(result.email, 'john@mail.com');
      },
    );

    test(
      'CheckSessionUseCase queries session status from repository',
      () async {
        final useCase = CheckSessionUseCase(fakeRepository);
        fakeRepository.sessionActive = true;
        expect(await useCase(), isTrue);

        fakeRepository.sessionActive = false;
        expect(await useCase(), isFalse);
      },
    );

    test('LogoutUseCase invokes repository logout', () async {
      final useCase = LogoutUseCase(fakeRepository);
      await useCase();
      expect(fakeRepository.loggedOut, isTrue);
    });
  });
}
