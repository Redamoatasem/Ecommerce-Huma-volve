import '../../domain/entities/auth_tokens_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../models/auth_exception.dart';
import '../../models/login_request.dart';
import '../../models/signup_request.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    AuthRemoteDataSource? remoteDataSource,
    AuthLocalDataSource? localDataSource,
  }) : remoteDataSource = remoteDataSource ?? AuthRemoteDataSourceImpl(),
       localDataSource = localDataSource ?? AuthLocalDataSourceImpl();

  @override
  Future<AuthTokensEntity> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw const AuthException('Email and password must not be empty.');
    }

    final request = LoginRequest(email: email.trim(), password: password);

    final tokensModel = await remoteDataSource.login(request);

    // Securely persist tokens in local data source
    await localDataSource.saveTokens(
      accessToken: tokensModel.accessToken,
      refreshToken: tokensModel.refreshToken,
    );

    return tokensModel.toEntity();
  }

  @override
  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
    String? avatar,
  }) async {
    if (name.trim().isEmpty) {
      throw const AuthException('Full name is required.');
    }
    if (email.trim().isEmpty) {
      throw const AuthException('Email address is required.');
    }
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters.');
    }

    final request = SignUpRequest(
      name: name.trim(),
      email: email.trim(),
      password: password,
      avatar: avatar ?? SignUpRequest(name: '', email: '', password: '').avatar,
    );

    final userModel = await remoteDataSource.register(request);
    return userModel.toEntity();
  }

  @override
  Future<UserEntity> getProfile({String? explicitToken}) async {
    final token = explicitToken ?? await localDataSource.getAccessToken();

    if (token == null || token.trim().isEmpty) {
      throw const AuthException(
        'Authentication required: No valid session token found.',
        statusCode: 401,
      );
    }

    final userModel = await remoteDataSource.getProfile(token);
    return userModel.toEntity();
  }

  @override
  Future<bool> hasSession() async {
    return localDataSource.hasAccessToken();
  }

  @override
  Future<void> logout() async {
    await localDataSource.clearTokens();
  }
}
