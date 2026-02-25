import 'app_failure.dart';

sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  final AppFailureType type;
  final String? debugMessage;
  const Failure(this.type, {this.debugMessage});
}
