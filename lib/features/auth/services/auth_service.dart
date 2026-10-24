import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../data/datasources/auth_local_data_source.dart';
import '../data/datasources/auth_remote_data_source.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/check_session_usecase.dart';
import '../domain/usecases/get_profile_usecase.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/logout_usecase.dart';
import '../domain/usecases/register_usecase.dart';
import '../models/auth_tokens.dart';
import '../models/login_request.dart';
import '../models/signup_request.dart';
import '../models/user_profile.dart';

/// Service facade preserving backwards compatibility while delegating
/// to Clean Architecture domain use cases and repositories.
class AuthService {
  final ApiClient apiClient;
  final TokenStorage tokenStorage;
  final AuthRepository repository;
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final GetProfileUseCase getProfileUseCase;
  final CheckSessionUseCase checkSessionUseCase;
  final LogoutUseCase logoutUseCase;

  AuthService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
    AuthRepository? repository,
  }) : apiClient = apiClient ?? ApiClient(),
       tokenStorage = tokenStorage ?? SecureTokenStorage(),
       repository =
           repository ??
           AuthRepositoryImpl(
             remoteDataSource: AuthRemoteDataSourceImpl(
               apiClient: apiClient ?? ApiClient(),
             ),
             localDataSource: AuthLocalDataSourceImpl(
               tokenStorage: tokenStorage ?? SecureTokenStorage(),
             ),
           ),
       loginUseCase = LoginUseCase(
         repository ??
             AuthRepositoryImpl(
               remoteDataSource: AuthRemoteDataSourceImpl(
                 apiClient: apiClient ?? ApiClient(),
               ),
               localDataSource: AuthLocalDataSourceImpl(
                 tokenStorage: tokenStorage ?? SecureTokenStorage(),
               ),
             ),
       ),
       registerUseCase = RegisterUseCase(
         repository ??
             AuthRepositoryImpl(
               remoteDataSource: AuthRemoteDataSourceImpl(
                 apiClient: apiClient ?? ApiClient(),
               ),
               localDataSource: AuthLocalDataSourceImpl(
                 tokenStorage: tokenStorage ?? SecureTokenStorage(),
               ),
             ),
       ),
       getProfileUseCase = GetProfileUseCase(
         repository ??
             AuthRepositoryImpl(
               remoteDataSource: AuthRemoteDataSourceImpl(
                 apiClient: apiClient ?? ApiClient(),
               ),
               localDataSource: AuthLocalDataSourceImpl(
                 tokenStorage: tokenStorage ?? SecureTokenStorage(),
               ),
             ),
       ),
       checkSessionUseCase = CheckSessionUseCase(
         repository ??
             AuthRepositoryImpl(
               remoteDataSource: AuthRemoteDataSourceImpl(
                 apiClient: apiClient ?? ApiClient(),
               ),
               localDataSource: AuthLocalDataSourceImpl(
                 tokenStorage: tokenStorage ?? SecureTokenStorage(),
               ),
             ),
       ),
       logoutUseCase = LogoutUseCase(
         repository ??
             AuthRepositoryImpl(
               remoteDataSource: AuthRemoteDataSourceImpl(
                 apiClient: apiClient ?? ApiClient(),
               ),
               localDataSource: AuthLocalDataSourceImpl(
                 tokenStorage: tokenStorage ?? SecureTokenStorage(),
               ),
             ),
       );

  /// Authenticates user credentials via domain use case and persists tokens.
  Future<AuthTokens> login(LoginRequest request) async {
    final tokens = await loginUseCase(
      email: request.email,
      password: request.password,
    );

    return AuthTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  }

  /// Registers a new user via domain use case.
  Future<UserProfile> register(SignUpRequest request) async {
    final user = await registerUseCase(
      name: request.name,
      email: request.email,
      password: request.password,
      avatar: request.avatar,
    );

    return UserProfile(
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      avatar: user.avatar,
      creationAt: user.creationAt,
      updatedAt: user.updatedAt,
    );
  }

  /// Retrieves authenticated user profile via domain use case.
  Future<UserProfile> getProfile({String? explicitToken}) async {
    final user = await getProfileUseCase(explicitToken: explicitToken);

    return UserProfile(
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      avatar: user.avatar,
      creationAt: user.creationAt,
      updatedAt: user.updatedAt,
    );
  }

  /// Checks whether an authenticated session exists in secure storage.
  Future<bool> hasSession() async {
    return checkSessionUseCase();
  }

  /// Clears stored tokens upon logout.
  Future<void> logout() async {
    await logoutUseCase();
  }
}
