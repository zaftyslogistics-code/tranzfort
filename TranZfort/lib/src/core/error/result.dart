import 'app_failure.dart';

/// Typed Result wrapper for all repository returns.
/// Source of truth: docs/05-data-access-and-repository-rules.md §10
/// Every repository method returns `Result<T>` — never throws raw exceptions.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get valueOrNull => switch (this) {
        Success<T>(value: final v) => v,
        Failure<T>() => null,
      };

  AppFailure? get failureOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(failure: final f) => f,
      };

  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  }) =>
      switch (this) {
        Success<T>(value: final v) => success(v),
        Failure<T>(failure: final f) => failure(f),
      };
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final AppFailure failure;
  const Failure(this.failure);
}
