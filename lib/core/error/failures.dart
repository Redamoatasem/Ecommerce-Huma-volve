/// Base domain failure class.
abstract class Failure {
  final String message;
  final int? statusCode;

  const Failure(this.message, {this.statusCode});

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          statusCode == other.statusCode;

  @override
  int get hashCode => Object.hash(message, statusCode);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode});
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.statusCode});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.statusCode});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.statusCode});
}
