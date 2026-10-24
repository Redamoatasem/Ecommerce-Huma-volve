import '../../../core/constants/api_constants.dart';

class SignUpRequest {
  final String name;
  final String email;
  final String password;
  final String avatar;

  const SignUpRequest({
    required this.name,
    required this.email,
    required this.password,
    this.avatar = ApiConstants.defaultAvatarUrl,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        'avatar': avatar,
      };
}

