import 'package:uuid/uuid.dart';

import '../utils/map_readers.dart';
import '../utils/type_safety.dart';

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
    // Defensive parsing for all fields to prevent crashes on malformed data
    
    // Parse id
    final id = (json['id'] ?? '').toString();
    
    // Parse operation_type
    final operationTypeStr = (json['operation_type'] ?? '').toString();
    final operationType = MutationOperation.values.firstWhere(
      (e) => e.name == operationTypeStr,
      orElse: () => MutationOperation.custom,
    );
    
    // Parse target
    final targetStr = (json['target'] ?? '').toString();
    final target = MutationTarget.values.firstWhere(
      (e) => e.name == targetStr,
      orElse: () => MutationTarget.custom,
    );
    
    // Parse payload with defensive Map parsing
    final payload = safeMap(json['payload']) ?? <String, dynamic>{};
    
    // Parse endpoint
    final endpoint = (json['endpoint'] ?? '').toString();
    
    // Parse timestamp (handle both int and string formats)
    final timestampValue = json['timestamp'];
    DateTime timestamp;
    if (timestampValue is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(timestampValue);
    } else if (timestampValue is String) {
      timestamp = DateTime.tryParse(timestampValue) ?? DateTime.fromMillisecondsSinceEpoch(int.tryParse(timestampValue) ?? 0);
    } else {
      timestamp = DateTime.now();
    }
    
    // Parse retry_count
    final retryCount = readInt(json['retry_count']);
    
    // Parse max_retries
    final maxRetries = readInt(json['max_retries']);
    
    // Parse status
    final statusStr = (json['status'] ?? '').toString();
    final status = MutationStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => MutationStatus.pending,
    );
    
    // Parse last_error
    final lastError = json['last_error']?.toString();
    
    // Parse user_id
    final userId = (json['user_id'] ?? '').toString();
    
    return QueuedMutation(
      id: id,
      operationType: operationType,
      target: target,
      payload: payload,
      endpoint: endpoint,
      timestamp: timestamp,
      retryCount: retryCount,
      maxRetries: maxRetries,
      status: status,
      lastError: lastError,
      userId: userId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operation_type': operationType.name,
      'target': target.name,
      'payload': payload,
      'endpoint': endpoint,
      'timestamp': timestamp.millisecondsSinceEpoch, // Changed from ISO8601 string to integer for better SQLite ordering
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
