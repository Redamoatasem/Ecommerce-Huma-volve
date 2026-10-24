class ApiConstants {
  static const String baseUrl = 'https://api.escuelajs.co/api/v1/';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  /// Default avatar URL used when registering a user.
  /// The EscuelaJS API (POST /users/) requires a valid URL for the 'avatar' field,
  /// but the current SignUp form UI does not collect an avatar image.
  /// This fallback URL uses a documented, standard, publicly accessible placeholder image.
  static const String defaultAvatarUrl = 'https://picsum.photos/800';
}

