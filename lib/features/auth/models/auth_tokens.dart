class AuthTokens {
  final String accessToken;
  final String? refreshToken;

  const AuthTokens({
    required this.accessToken,
    this.refreshToken,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final token = json['access_token'];
    if (token == null || token is! String || token.trim().isEmpty) {
      throw const FormatException('Authentication response missing valid access_token');
    }
    return AuthTokens(
      accessToken: token.trim(),
      refreshToken: json['refresh_token'] is String ? (json['refresh_token'] as String).trim() : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        if (refreshToken != null) 'refresh_token': refreshToken,
      };
}

