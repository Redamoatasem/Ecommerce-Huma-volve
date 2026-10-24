import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStorage {
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  });

  Future<String?> getAccessToken();

  Future<String?> getRefreshToken();

  Future<void> clearTokens();

  Future<bool> hasAccessToken();
}

class SecureTokenStorage implements TokenStorage {
  static const String _accessTokenKey = 'secure_access_token';
  static const String _refreshTokenKey = 'secure_refresh_token';

  final FlutterSecureStorage _storage;

  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: true),
            );

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  @override
  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  @override
  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}

/// In-memory implementation of [TokenStorage] for isolated testing
/// without platform-channel dependencies.
class InMemoryTokenStorage implements TokenStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _data['access_token'] = accessToken;
    if (refreshToken != null) {
      _data['refresh_token'] = refreshToken;
    }
  }

  @override
  Future<String?> getAccessToken() async {
    return _data['access_token'];
  }

  @override
  Future<String?> getRefreshToken() async {
    return _data['refresh_token'];
  }

  @override
  Future<void> clearTokens() async {
    _data.clear();
  }

  @override
  Future<bool> hasAccessToken() async {
    final token = _data['access_token'];
    return token != null && token.isNotEmpty;
  }
}

