import 'package:ecommerce_app_huma_volve/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:ecommerce_app_huma_volve/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:ecommerce_app_huma_volve/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ecommerce_app_huma_volve/features/auth/models/auth_exception.dart';
import 'package:ecommerce_app_huma_volve/features/auth/models/auth_tokens.dart';
import 'package:ecommerce_app_huma_volve/features/auth/models/login_request.dart';
import 'package:ecommerce_app_huma_volve/features/auth/models/signup_request.dart';
import 'package:ecommerce_app_huma_volve/features/auth/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  LoginRequest? lastLoginRequest;
  SignUpRequest? lastSignUpRequest;
  String? lastProfileToken;

  bool shouldThrow = false;

  final sampleTokens = const AuthTokens(
    accessToken: 'jwt-access-123',
    refreshToken: 'jwt-refresh-456',
  );

  final sampleUser = const UserProfile(
    id: 10,
    email: 'test@mail.com',
    name: 'Test User',
    role: 'customer',
    avatar: 'https://placehold.co/100',
  );

  @override
  Future<AuthTokens> login(LoginRequest request) async {
    if (shouldThrow) {
      throw const AuthException('Invalid credentials', statusCode: 401);
    }
    lastLoginRequest = request;
    return sampleTokens;
  }

  @override
  Future<UserProfile> register(SignUpRequest request) async {
    if (shouldThrow) {
      throw const AuthException('Email exists', statusCode: 400);
    }
    lastSignUpRequest = request;
    return sampleUser;
  }

  @override
  Future<UserProfile> getProfile(String token) async {
    if (shouldThrow) {
      throw const AuthException('Unauthorized', statusCode: 401);
    }
    lastProfileToken = token;
    return sampleUser;
  }
}

class FakeAuthLocalDataSource implements AuthLocalDataSource {
  String? storedAccessToken;
  String? storedRefreshToken;
  bool cleared = false;

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    storedAccessToken = accessToken;
    storedRefreshToken = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => storedAccessToken;

  @override
  Future<String?> getRefreshToken() async => storedRefreshToken;

  @override
  Future<bool> hasAccessToken() async =>
      storedAccessToken != null && storedAccessToken!.isNotEmpty;

  @override
  Future<void> clearTokens() async {
    storedAccessToken = null;
    storedRefreshToken = null;
    cleared = true;
  }
}

void main() {
  late FakeAuthRemoteDataSource remoteDataSource;
  late FakeAuthLocalDataSource localDataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    remoteDataSource = FakeAuthRemoteDataSource();
    localDataSource = FakeAuthLocalDataSource();
    repository = AuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );
  });

  group('AuthRepositoryImpl', () {
    test('login validates input, calls remote, and persists tokens', () async {
      final tokens = await repository.login(
        email: 'user@mail.com',
        password: 'password123',
      );

      expect(remoteDataSource.lastLoginRequest?.email, 'user@mail.com');
      expect(remoteDataSource.lastLoginRequest?.password, 'password123');
      expect(localDataSource.storedAccessToken, 'jwt-access-123');
      expect(localDataSource.storedRefreshToken, 'jwt-refresh-456');
      expect(tokens.accessToken, 'jwt-access-123');
    });

    test(
      'login throws AuthException when email or password is empty',
      () async {
        expect(
          () => repository.login(email: '', password: '123'),
          throwsA(isA<AuthException>()),
        );
        expect(
          () => repository.login(email: 'user@mail.com', password: ''),
          throwsA(isA<AuthException>()),
        );
      },
    );

    test('register validates inputs and returns user entity', () async {
      final user = await repository.register(
        name: 'Alice',
        email: 'alice@mail.com',
        password: 'password123',
      );

      expect(remoteDataSource.lastSignUpRequest?.name, 'Alice');
      expect(remoteDataSource.lastSignUpRequest?.email, 'alice@mail.com');
      expect(user.id, 10);
      expect(user.email, 'test@mail.com');
    });

    test(
      'register throws AuthException when input fields are invalid',
      () async {
        expect(
          () => repository.register(
            name: '',
            email: 'a@b.com',
            password: '123456',
          ),
          throwsA(isA<AuthException>()),
        );
        expect(
          () => repository.register(name: 'A', email: '', password: '123456'),
          throwsA(isA<AuthException>()),
        );
        expect(
          () =>
              repository.register(name: 'A', email: 'a@b.com', password: '123'),
          throwsA(isA<AuthException>()),
        );
      },
    );

    test(
      'getProfile reads token from local storage and calls remote',
      () async {
        localDataSource.storedAccessToken = 'saved-token';
        final profile = await repository.getProfile();

        expect(remoteDataSource.lastProfileToken, 'saved-token');
        expect(profile.name, 'Test User');
      },
    );

    test('getProfile throws 401 when no token is present', () async {
      expect(
        () => repository.getProfile(),
        throwsA(predicate<AuthException>((e) => e.statusCode == 401)),
      );
    });

    test('hasSession checks local storage token presence', () async {
      expect(await repository.hasSession(), isFalse);
      localDataSource.storedAccessToken = 'token';
      expect(await repository.hasSession(), isTrue);
    });

    test('logout clears tokens from local storage', () async {
      localDataSource.storedAccessToken = 'token';
      await repository.logout();
      expect(localDataSource.cleared, isTrue);
      expect(localDataSource.storedAccessToken, isNull);
    });
  });
}
