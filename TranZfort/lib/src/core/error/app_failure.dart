/// TranZfort Failure Taxonomy
/// Source of truth: docs/61-missing-feature-specs-and-schemas.md §10
/// Every repository method maps backend errors to one of these types.
/// Raw backend exception strings must NEVER leak to UI.
sealed class AppFailure {
  final String message;
  final String? debugInfo;

  const AppFailure({required this.message, this.debugInfo});
}

/// No connectivity or request timeout — retryable
class NetworkFailure extends AppFailure {
  const NetworkFailure({
    super.message = 'Check your internet connection and try again',
    super.debugInfo,
  });
}

/// Backend returned 5xx or unexpected error — retryable
class ServerFailure extends AppFailure {
  const ServerFailure({
    super.message = 'Something went wrong. Please try again.',
    super.debugInfo,
  });
}

/// RLS or auth denied the operation — not retryable
class PermissionFailure extends AppFailure {
  const PermissionFailure({
    super.message = "You don't have permission for this action",
    super.debugInfo,
  });
}

/// Requested resource does not exist — not retryable
class NotFoundFailure extends AppFailure {
  const NotFoundFailure({
    super.message = 'This item is no longer available',
    super.debugInfo,
  });
}

/// Concurrent modification or duplicate attempt — sometimes retryable
class ConflictFailure extends AppFailure {
  const ConflictFailure({
    super.message = 'This item was updated. Please refresh and try again.',
    super.debugInfo,
  });
}

/// Client or server-side validation failed — not retryable without correction
class ValidationFailure extends AppFailure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    super.message = 'Please check your input',
    super.debugInfo,
    this.fieldErrors,
  });
}

/// Operation blocked by workflow precondition — not retryable without state change
class BusinessRuleFailure extends AppFailure {
  const BusinessRuleFailure({
    required super.message,
    super.debugInfo,
  });
}

/// Auth session expired or invalid — redirect to auth
class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure({
    super.message = 'Session expired. Please sign in again.',
    super.debugInfo,
  });
}

/// Unclassified error — not retryable
class UnknownFailure extends AppFailure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred',
    super.debugInfo,
  });
}
