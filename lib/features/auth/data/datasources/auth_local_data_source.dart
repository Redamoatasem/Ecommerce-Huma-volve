import '../../../../core/storage/token_storage.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens({required String accessToken, String? refreshToken});
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
  Future<bool> hasAccessToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final TokenStorage tokenStorage;

  AuthLocalDataSourceImpl({TokenStorage? tokenStorage})
    : tokenStorage = tokenStorage ?? SecureTokenStorage();

  @override
  Future<void> saveTokens({required String accessToken, String? refreshToken}) {
    return tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<String?> getAccessToken() {
    return tokenStorage.getAccessToken();
  }

  @override
  Future<String?> getRefreshToken() {
    return tokenStorage.getRefreshToken();
  }

  @override
  Future<void> clearTokens() {
    return tokenStorage.clearTokens();
  }

  @override
  Future<bool> hasAccessToken() {
    return tokenStorage.hasAccessToken();
  }
}
