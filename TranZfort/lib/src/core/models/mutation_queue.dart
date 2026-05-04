import 'package:uuid/uuid.dart';

enum MutationOperation {
  create,
  update,
  delete,
  custom,
}

enum MutationTarget {
  loadBooking,
  chatSend,
  podProofUpload,
  lrProofUpload,
  profileUpdate,
  supplierProfileUpdate,
  disputeRaise,
  reviewSubmit,
  reviewReply,
  notificationMarkRead,
  custom,
}

class QueuedMutation {
  final String id;
  final MutationOperation operationType;
  final MutationTarget target;
  final Map<String, dynamic> payload;
  final String endpoint; // RPC name or API endpoint
  final DateTime timestamp;
  final int retryCount;
  final int maxRetries;
  final MutationStatus status;
  final String? lastError;
  final String userId;

  QueuedMutation({
    required this.id,
    required this.operationType,
    required this.target,
    required this.payload,
    required this.endpoint,
    required this.timestamp,
    this.retryCount = 0,
    this.maxRetries = 5,
    this.status = MutationStatus.pending,
    this.lastError,
    required this.userId,
  });

  factory QueuedMutation.fromJson(Map<String, dynamic> json) {
    return QueuedMutation(
      id: json['id'] as String,
      operationType: MutationOperation.values.firstWhere(
        (e) => e.name == json['operation_type'],
        orElse: () => MutationOperation.custom,
      ),
      target: MutationTarget.values.firstWhere(
        (e) => e.name == json['target'],
        orElse: () => MutationTarget.custom,
      ),
      payload: json['payload'] as Map<String, dynamic>,
      endpoint: json['endpoint'] as String,
      timestamp: DateTime.tryParse(json['timestamp'] as String) ?? DateTime.fromMillisecondsSinceEpoch(0),
      retryCount: json['retry_count'] as int? ?? 0,
      maxRetries: json['max_retries'] as int? ?? 5,
      status: MutationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MutationStatus.pending,
      ),
      lastError: json['last_error'] as String?,
      userId: json['user_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operation_type': operationType.name,
      'target': target.name,
      'payload': payload,
      'endpoint': endpoint,
      'timestamp': timestamp.toIso8601String(),
      'retry_count': retryCount,
      'max_retries': maxRetries,
      'status': status.name,
      'last_error': lastError,
      'user_id': userId,
    };
  }

  QueuedMutation copyWith({
    MutationOperation? operationType,
    MutationTarget? target,
    Map<String, dynamic>? payload,
    String? endpoint,
    DateTime? timestamp,
    int? retryCount,
    int? maxRetries,
    MutationStatus? status,
    String? lastError,
    String? userId,
  }) {
    return QueuedMutation(
      id: id,
      operationType: operationType ?? this.operationType,
      target: target ?? this.target,
      payload: payload ?? this.payload,
      endpoint: endpoint ?? this.endpoint,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      userId: userId ?? this.userId,
    );
  }

  /// Check if this mutation has exceeded max retries.
  bool get isExhausted => retryCount >= maxRetries;

  /// Check if this mutation can be retried.
  bool get canRetry => !isExhausted && status == MutationStatus.failed;

  /// Check if this mutation can be processed now (pending, retrying, or failed but not exhausted).
  bool get isProcessable =>
      status == MutationStatus.pending ||
      status == MutationStatus.retrying ||
      (status == MutationStatus.failed && !isExhausted);

  /// Create a new mutation instance for retry.
  QueuedMutation forRetry() {
    return copyWith(
      retryCount: retryCount + 1,
      status: MutationStatus.retrying,
      lastError: null,
    );
  }

  /// Create a new mutation instance marking as completed.
  QueuedMutation asCompleted() {
    return copyWith(
      status: MutationStatus.completed,
    );
  }

  /// Create a new mutation instance marking as failed with error.
  QueuedMutation asFailed(String error) {
    return copyWith(
      status: MutationStatus.failed,
      lastError: error,
    );
  }

  /// Create a new mutation instance marking as retrying.
  QueuedMutation asRetrying() {
    return copyWith(
      status: MutationStatus.retrying,
    );
  }

  /// Static factory to create a new mutation with auto-generated UUID.
  factory QueuedMutation.create({
    required MutationOperation operationType,
    required MutationTarget target,
    required Map<String, dynamic> payload,
    required String endpoint,
    required String userId,
    int maxRetries = 5,
  }) {
    return QueuedMutation(
      id: const Uuid().v4(),
      operationType: operationType,
      target: target,
      payload: payload,
      endpoint: endpoint,
      timestamp: DateTime.now(),
      maxRetries: maxRetries,
      userId: userId,
    );
  }
}

enum MutationStatus {
  pending,
  retrying,
  completed,
  failed,
}

extension MutationStatusX on MutationStatus {
  String get displayName {
    return switch (this) {
      MutationStatus.pending => 'Pending',
      MutationStatus.retrying => 'Retrying',
      MutationStatus.completed => 'Completed',
      MutationStatus.failed => 'Failed',
    };
  }
}
