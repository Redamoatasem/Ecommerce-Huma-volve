class AuthTokensEntity {
  final String accessToken;
  final String? refreshToken;

  const AuthTokensEntity({required this.accessToken, this.refreshToken});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthTokensEntity &&
          runtimeType == other.runtimeType &&
          accessToken == other.accessToken &&
          refreshToken == other.refreshToken;

  @override
  int get hashCode => Object.hash(accessToken, refreshToken);

  @override
  String toString() =>
      'AuthTokensEntity(accessToken: [PROTECTED], refreshToken: [PROTECTED])';
}
