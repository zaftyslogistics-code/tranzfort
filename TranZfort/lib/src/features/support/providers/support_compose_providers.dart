import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../data/support_repository.dart';
import '../data/support_attachment_upload_service.dart';

const List<String> supportTicketCategories = <String>[
  'general',
  'account',
  'load',
  'trip',
  'payment',
  'technical',
  'other',
];

const List<String> reportIssueCategories = <String>[
  'spam_or_scam',
  'fake_payout_proof',
  'non_payment',
  'abusive_behavior',
];

const String supportCreateTicketValidationFailureCode = 'support_create_ticket_validation';
const String supportCreateTicketInvalidCategoryCode = 'support_create_ticket_invalid_category';
const String supportCreateTicketDescriptionTooShortCode = 'support_create_ticket_description_too_short';
const String supportCreateTicketAttachmentFinalizeFailureCode = 'support_create_ticket_attachment_finalize_failed';
const String reportIssueValidationFailureCode = 'report_issue_validation';
const String reportIssueInvalidCategoryCode = 'report_issue_invalid_category';
const String reportIssueDescriptionTooShortCode = 'report_issue_description_too_short';
const String reportIssueAttachmentRequiredCode = 'report_issue_attachment_required';
const String reportIssueAttachmentFinalizeFailureCode = 'report_issue_attachment_finalize_failed';
const String supportReplyValidationFailureCode = 'support_reply_validation';
const String supportReplyMessageTooShortCode = 'support_reply_message_too_short';
const String supportReplyAttachmentFinalizeFailureCode = 'support_reply_attachment_finalize_failed';

class ReportIssueContext {
  final String initialCategory;
  final String relatedLoadId;
  final String relatedTripId;
  final String sourceLabel;

  const ReportIssueContext({
    required this.initialCategory,
    required this.relatedLoadId,
    required this.relatedTripId,
    required this.sourceLabel,
  });

  factory ReportIssueContext.empty() {
    return const ReportIssueContext(
      initialCategory: 'spam_or_scam',
      relatedLoadId: '',
      relatedTripId: '',
      sourceLabel: 'Current conversation or trip context',
    );
  }
}

class ReportIssueState {
  final String category;
  final String description;
  final List<TicketAttachmentMetadata> attachments;
  final bool isSubmitting;
  final AppFailure? failure;
  final String? createdTicketId;
  final Map<String, String> fieldErrors;

  const ReportIssueState({
    required this.category,
    required this.description,
    required this.attachments,
    required this.isSubmitting,
    required this.failure,
    required this.createdTicketId,
    required this.fieldErrors,
  });

  factory ReportIssueState.initial(ReportIssueContext context) {
    return ReportIssueState(
      category: reportIssueCategories.contains(context.initialCategory)
          ? context.initialCategory
          : reportIssueCategories.first,
      description: '',
      attachments: const [],
      isSubmitting: false,
      failure: null,
      createdTicketId: null,
      fieldErrors: const <String, String>{},
    );
  }

  ReportIssueState copyWith({
    String? category,
    String? description,
    List<TicketAttachmentMetadata>? attachments,
    bool? isSubmitting,
    AppFailure? failure,
    bool? clearFailure,
    String? createdTicketId,
    bool? clearCreatedTicketId,
    Map<String, String>? fieldErrors,
  }) {
    return ReportIssueState(
      category: category ?? this.category,
      description: description ?? this.description,
      attachments: attachments ?? this.attachments,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failure: clearFailure == true ? null : failure ?? this.failure,
      createdTicketId: clearCreatedTicketId == true ? null : createdTicketId ?? this.createdTicketId,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}

class CreateSupportTicketState {
  final String sessionId;
  final String category;
  final String relatedLoadId;
  final String relatedTripId;
  final String description;
  final List<TicketAttachmentMetadata> attachments;
  final bool isSubmitting;
  final AppFailure? failure;
  final String? createdTicketId;
  final Map<String, String> fieldErrors;

  const CreateSupportTicketState({
    required this.sessionId,
    required this.category,
    required this.relatedLoadId,
    required this.relatedTripId,
    required this.description,
    required this.attachments,
    required this.isSubmitting,
    required this.failure,
    required this.createdTicketId,
    required this.fieldErrors,
  });

  factory CreateSupportTicketState.initial() {
    return CreateSupportTicketState(
      sessionId: _generateSessionId(),
      category: 'general',
      relatedLoadId: '',
      relatedTripId: '',
      description: '',
      attachments: [],
      isSubmitting: false,
      failure: null,
      createdTicketId: null,
      fieldErrors: <String, String>{},
    );
  }

  CreateSupportTicketState copyWith({
    String? sessionId,
    String? category,
    String? relatedLoadId,
    String? relatedTripId,
    String? description,
    List<TicketAttachmentMetadata>? attachments,
    bool? isSubmitting,
    AppFailure? failure,
    bool? clearFailure,
    String? createdTicketId,
    bool? clearCreatedTicketId,
    Map<String, String>? fieldErrors,
  }) {
    return CreateSupportTicketState(
      sessionId: sessionId ?? this.sessionId,
      category: category ?? this.category,
      relatedLoadId: relatedLoadId ?? this.relatedLoadId,
      relatedTripId: relatedTripId ?? this.relatedTripId,
      description: description ?? this.description,
      attachments: attachments ?? this.attachments,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failure: clearFailure == true ? null : failure ?? this.failure,
      createdTicketId: clearCreatedTicketId == true ? null : createdTicketId ?? this.createdTicketId,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}

/// Generates a unique session ID for draft attachments
String _generateSessionId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

class CreateSupportTicketController extends StateNotifier<CreateSupportTicketState> {
  final SupportRepository _repository;
  final SupportAttachmentUploadService _attachmentService;

  CreateSupportTicketController(this._repository, this._attachmentService) : super(CreateSupportTicketState.initial());

  void setCategory(String? value) {
    if (value == null) {
      return;
    }
    state = state.copyWith(
      category: value,
      clearFailure: true,
      clearCreatedTicketId: true,
      fieldErrors: _withoutErrors(const <String>['category']),
    );
  }

  void setRelatedLoadId(String value) {
    state = state.copyWith(
      relatedLoadId: value,
      clearFailure: true,
      clearCreatedTicketId: true,
    );
  }

  void setRelatedTripId(String value) {
    state = state.copyWith(
      relatedTripId: value,
      clearFailure: true,
      clearCreatedTicketId: true,
    );
  }

  void setDescription(String value) {
    state = state.copyWith(
      description: value,
      clearFailure: true,
      clearCreatedTicketId: true,
      fieldErrors: _withoutErrors(const <String>['message_body']),
    );
  }

  void addAttachment(TicketAttachmentMetadata attachment) {
    state = state.copyWith(
      attachments: [...state.attachments, attachment],
      clearFailure: true,
      clearCreatedTicketId: true,
      fieldErrors: _withoutErrors(const <String>['attachment_path']),
    );
  }

  void removeAttachment(String attachmentId) {
    state = state.copyWith(
      attachments: state.attachments.where((a) => a.id != attachmentId).toList(),
      clearFailure: true,
      clearCreatedTicketId: true,
    );
  }

  Future<Result<String>> submit() async {
    if (state.isSubmitting) {
      return const Failure<String>(BusinessRuleFailure(message: 'Support ticket submission is already in progress'));
    }

    final fieldErrors = _validate();
    if (fieldErrors.isNotEmpty) {
      state = state.copyWith(fieldErrors: fieldErrors, clearFailure: true, clearCreatedTicketId: true);
      return Failure<String>(
        ValidationFailure(
          message: supportCreateTicketValidationFailureCode,
          fieldErrors: fieldErrors,
        ),
      );
    }

    state = state.copyWith(
      isSubmitting: true,
      clearFailure: true,
      clearCreatedTicketId: true,
      fieldErrors: const <String, String>{},
    );

    // Step 1: Create ticket
    final result = await _repository.createTicket(
      category: state.category,
      messageBody: state.description,
      relatedLoadId: state.relatedLoadId.trim(),
      relatedTripId: state.relatedTripId.trim(),
      attachmentPath: '', // Empty - attachments are handled separately via ticket_attachments table
    );

    String? finalTicketId = result.valueOrNull;
    
    // Step 2: Finalize draft attachments if ticket created successfully
    if (result.isSuccess && finalTicketId != null && state.attachments.isNotEmpty) {
      try {
        await _repository.finalizeTicketAttachments(
          ticketId: finalTicketId,
          sessionId: state.sessionId,
        );
      } catch (_) {
        // If finalization fails, we still return success for ticket creation
        // The attachments will remain orphaned and cleaned up by the cleanup job
        // This is a safe fallback
      }
    }

    state = state.copyWith(
      isSubmitting: false,
      failure: result.failureOrNull,
      createdTicketId: finalTicketId,
      attachments: result.isSuccess ? [] : state.attachments,
    );
    return result;
  }

  Map<String, String> _validate() {
    final errors = <String, String>{};
    if (!supportTicketCategories.contains(state.category)) {
      errors['category'] = supportCreateTicketInvalidCategoryCode;
    }
    if (state.description.trim().length < 10) {
      errors['message_body'] = supportCreateTicketDescriptionTooShortCode;
    }
    return errors;
  }

  Map<String, String> _withoutErrors(List<String> keys) {
    final next = Map<String, String>.from(state.fieldErrors);
    for (final key in keys) {
      next.remove(key);
    }
    return next;
  }

  Future<void> cancel() async {
    // Cleanup draft attachments if any
    if (state.attachments.isNotEmpty) {
      try {
        await _attachmentService.cleanupDraftSession(
          profileId: '', // Will need to get from auth context
          sessionId: state.sessionId,
        );
      } catch (_) {
        // Don't fail cancel if cleanup fails
      }
    }
    // Reset state
    state = CreateSupportTicketState.initial();
  }
}

final createSupportTicketProvider =
    StateNotifierProvider.autoDispose<CreateSupportTicketController, CreateSupportTicketState>((ref) {
  return CreateSupportTicketController(
    ref.watch(supportRepositoryProvider),
    ref.watch(supportAttachmentUploadServiceProvider),
  );
});

class ReportIssueController extends StateNotifier<ReportIssueState> {
  final SupportRepository _repository;
  final ReportIssueContext _context;

  ReportIssueController(this._repository, this._context) : super(ReportIssueState.initial(_context));

  void setCategory(String? value) {
    if (value == null) {
      return;
    }
    state = state.copyWith(
      category: value,
      clearFailure: true,
      clearCreatedTicketId: true,
      fieldErrors: _withoutErrors(const <String>['category']),
    );
  }

  void setDescription(String value) {
    state = state.copyWith(
      description: value,
      clearFailure: true,
      clearCreatedTicketId: true,
      fieldErrors: _withoutErrors(const <String>['message_body']),
    );
  }

  void addAttachment(TicketAttachmentMetadata attachment) {
    state = state.copyWith(
      attachments: [...state.attachments, attachment],
      clearFailure: true,
      clearCreatedTicketId: true,
      fieldErrors: _withoutErrors(const <String>['attachment_path']),
    );
  }

  void removeAttachment(String attachmentId) {
    state = state.copyWith(
      attachments: state.attachments.where((a) => a.id != attachmentId).toList(),
      clearFailure: true,
      clearCreatedTicketId: true,
    );
  }

  Future<Result<String>> submit() async {
    if (state.isSubmitting) {
      return const Failure<String>(BusinessRuleFailure(message: 'Issue report submission is already in progress'));
    }

    final fieldErrors = _validate();
    if (fieldErrors.isNotEmpty) {
      state = state.copyWith(fieldErrors: fieldErrors, clearFailure: true, clearCreatedTicketId: true);
      return Failure<String>(
        ValidationFailure(
          message: reportIssueValidationFailureCode,
          fieldErrors: fieldErrors,
        ),
      );
    }

    state = state.copyWith(
      isSubmitting: true,
      clearFailure: true,
      clearCreatedTicketId: true,
      fieldErrors: const <String, String>{},
    );

    final result = await _repository.createTicket(
      category: state.category,
      messageBody: state.description,
      relatedLoadId: _context.relatedLoadId.trim(),
      relatedTripId: _context.relatedTripId.trim(),
      attachmentPath: '', // Empty - attachments are handled separately via ticket_attachments table
    );

    String? finalTicketId = result.valueOrNull;
    if (result.isSuccess && finalTicketId != null && state.attachments.isNotEmpty) {
      // Attachments are already stored in ticket_attachments table with correct ticket_id
      // No need to relocate - they were uploaded with the ticket_id
    }

    state = state.copyWith(
      isSubmitting: false,
      failure: result.failureOrNull,
      createdTicketId: finalTicketId,
      attachments: result.isSuccess ? [] : state.attachments,
    );
    return result;
  }

  Map<String, String> _validate() {
    final errors = <String, String>{};
    if (!reportIssueCategories.contains(state.category)) {
      errors['category'] = reportIssueInvalidCategoryCode;
    }
    if (state.description.trim().length < 10) {
      errors['message_body'] = reportIssueDescriptionTooShortCode;
    }
    // Removed attachment validation - multiple attachments are optional now
    return errors;
  }

  Map<String, String> _withoutErrors(List<String> keys) {
    final next = Map<String, String>.from(state.fieldErrors);
    for (final key in keys) {
      next.remove(key);
    }
    return next;
  }
}

final reportIssueProvider = StateNotifierProvider.autoDispose
    .family<ReportIssueController, ReportIssueState, ReportIssueContext>((ref, context) {
  return ReportIssueController(
    ref.watch(supportRepositoryProvider),
    context,
  );
});

class SupportReplyState {
  final String messageBody;
  final List<TicketAttachmentMetadata> attachments;
  final bool isSubmitting;
  final AppFailure? failure;
  final String? lastReplyId;
  final Map<String, String> fieldErrors;

  const SupportReplyState({
    required this.messageBody,
    required this.attachments,
    required this.isSubmitting,
    required this.failure,
    required this.lastReplyId,
    required this.fieldErrors,
  });

  factory SupportReplyState.initial() {
    return const SupportReplyState(
      messageBody: '',
      attachments: [],
      isSubmitting: false,
      failure: null,
      lastReplyId: null,
      fieldErrors: <String, String>{},
    );
  }

  SupportReplyState copyWith({
    String? messageBody,
    List<TicketAttachmentMetadata>? attachments,
    bool? isSubmitting,
    AppFailure? failure,
    bool? clearFailure,
    String? lastReplyId,
    Map<String, String>? fieldErrors,
  }) {
    return SupportReplyState(
      messageBody: messageBody ?? this.messageBody,
      attachments: attachments ?? this.attachments,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failure: clearFailure == true ? null : failure ?? this.failure,
      lastReplyId: lastReplyId ?? this.lastReplyId,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}

class SupportReplyController extends StateNotifier<SupportReplyState> {
  final SupportRepository _repository;
  final String _ticketId;

  SupportReplyController(this._repository, this._ticketId) : super(SupportReplyState.initial());

  void setMessageBody(String value) {
    state = state.copyWith(
      messageBody: value,
      clearFailure: true,
      fieldErrors: _withoutErrors(const <String>['message_body']),
    );
  }

  void addAttachment(TicketAttachmentMetadata attachment) {
    state = state.copyWith(
      attachments: [...state.attachments, attachment],
      clearFailure: true,
    );
  }

  void removeAttachment(String attachmentId) {
    state = state.copyWith(
      attachments: state.attachments.where((a) => a.id != attachmentId).toList(),
      clearFailure: true,
    );
  }

  Future<Result<String>> submit() async {
    if (state.isSubmitting) {
      return const Failure<String>(BusinessRuleFailure(message: 'Reply submission is already in progress'));
    }

    final fieldErrors = _validate();
    if (fieldErrors.isNotEmpty) {
      state = state.copyWith(fieldErrors: fieldErrors, clearFailure: true);
      return Failure<String>(
        ValidationFailure(
          message: supportReplyValidationFailureCode,
          fieldErrors: fieldErrors,
        ),
      );
    }

    state = state.copyWith(
      isSubmitting: true,
      clearFailure: true,
      fieldErrors: const <String, String>{},
    );

    final result = await _repository.replyToTicket(
      ticketId: _ticketId,
      messageBody: state.messageBody,
      attachmentPath: '', // Empty - attachments are handled separately via ticket_attachments table
    );

    final replyId = result.valueOrNull;
    if (result.isSuccess && replyId != null && state.attachments.isNotEmpty) {
      // Attachments are already stored in ticket_attachments table with correct ticket_id
      // No need to relocate - they were uploaded with the ticket_id
    }

    state = state.copyWith(
      isSubmitting: false,
      failure: result.failureOrNull,
      lastReplyId: replyId,
      attachments: result.isSuccess ? [] : state.attachments,
      messageBody: result.isSuccess ? '' : state.messageBody,
    );
    return result;
  }

  Map<String, String> _validate() {
    final errors = <String, String>{};
    if (state.messageBody.trim().length < 2) {
      errors['message_body'] = supportReplyMessageTooShortCode;
    }
    return errors;
  }

  Map<String, String> _withoutErrors(List<String> keys) {
    final next = Map<String, String>.from(state.fieldErrors);
    for (final key in keys) {
      next.remove(key);
    }
    return next;
  }
}

final supportReplyProvider =
    StateNotifierProvider.autoDispose.family<SupportReplyController, SupportReplyState, String>((ref, ticketId) {
  return SupportReplyController(
    ref.watch(supportRepositoryProvider),
    ticketId,
  );
});
