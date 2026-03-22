import 'package:flutter/foundation.dart';
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
  'abusive_behavior',
  'fake_payout_proof',
  'non_payment',
];

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
  final String attachmentPath;
  final bool isSubmitting;
  final AppFailure? failure;
  final String? createdTicketId;
  final Map<String, String> fieldErrors;

  const ReportIssueState({
    required this.category,
    required this.description,
    required this.attachmentPath,
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
      attachmentPath: '',
      isSubmitting: false,
      failure: null,
      createdTicketId: null,
      fieldErrors: const <String, String>{},
    );
  }

  ReportIssueState copyWith({
    String? category,
    String? description,
    String? attachmentPath,
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
      attachmentPath: attachmentPath ?? this.attachmentPath,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failure: clearFailure == true ? null : failure ?? this.failure,
      createdTicketId: clearCreatedTicketId == true ? null : createdTicketId ?? this.createdTicketId,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}

class CreateSupportTicketState {
  final String category;
  final String relatedLoadId;
  final String relatedTripId;
  final String description;
  final String attachmentPath;
  final bool isSubmitting;
  final AppFailure? failure;
  final String? createdTicketId;
  final Map<String, String> fieldErrors;

  const CreateSupportTicketState({
    required this.category,
    required this.relatedLoadId,
    required this.relatedTripId,
    required this.description,
    required this.attachmentPath,
    required this.isSubmitting,
    required this.failure,
    required this.createdTicketId,
    required this.fieldErrors,
  });

  factory CreateSupportTicketState.initial() {
    return const CreateSupportTicketState(
      category: 'general',
      relatedLoadId: '',
      relatedTripId: '',
      description: '',
      attachmentPath: '',
      isSubmitting: false,
      failure: null,
      createdTicketId: null,
      fieldErrors: <String, String>{},
    );
  }

  CreateSupportTicketState copyWith({
    String? category,
    String? relatedLoadId,
    String? relatedTripId,
    String? description,
    String? attachmentPath,
    bool? isSubmitting,
    AppFailure? failure,
    bool? clearFailure,
    String? createdTicketId,
    bool? clearCreatedTicketId,
    Map<String, String>? fieldErrors,
  }) {
    return CreateSupportTicketState(
      category: category ?? this.category,
      relatedLoadId: relatedLoadId ?? this.relatedLoadId,
      relatedTripId: relatedTripId ?? this.relatedTripId,
      description: description ?? this.description,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failure: clearFailure == true ? null : failure ?? this.failure,
      createdTicketId: clearCreatedTicketId == true ? null : createdTicketId ?? this.createdTicketId,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}

class CreateSupportTicketController extends StateNotifier<CreateSupportTicketState> {
  final SupportRepository _repository;
  final SupportAttachmentUploadService _uploadService;

  CreateSupportTicketController(this._repository, this._uploadService) : super(CreateSupportTicketState.initial());

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

  void setAttachmentPath(String value) {
    state = state.copyWith(
      attachmentPath: value,
      clearFailure: true,
      clearCreatedTicketId: true,
      fieldErrors: _withoutErrors(const <String>['attachment_path']),
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
          message: 'Please correct the highlighted support ticket details',
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
      relatedLoadId: state.relatedLoadId.trim(),
      relatedTripId: state.relatedTripId.trim(),
      attachmentPath: state.attachmentPath.trim(),
    );

    String? finalTicketId = result.valueOrNull;
    if (result.isSuccess && finalTicketId != null && state.attachmentPath.trim().isNotEmpty) {
      final relocateResult = await _uploadService.relocateAttachment(
        currentPath: state.attachmentPath.trim(),
        targetPathSegment: 'support_ticket/$finalTicketId',
      );
      if (relocateResult.isFailure) {
        state = state.copyWith(
          isSubmitting: false,
          failure: const ServerFailure(message: 'Ticket created but failed to finalize attachment.'),
          createdTicketId: finalTicketId,
        );
        return result;
      }
    }

    state = state.copyWith(
      isSubmitting: false,
      failure: result.failureOrNull,
      createdTicketId: finalTicketId,
      attachmentPath: result.isSuccess ? '' : state.attachmentPath,
    );
    return result;
  }

  Map<String, String> _validate() {
    final errors = <String, String>{};
    if (!supportTicketCategories.contains(state.category)) {
      errors['category'] = 'Select a valid support category';
    }
    if (state.description.trim().length < 10) {
      errors['message_body'] = 'Describe the issue in at least 10 characters';
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

final createSupportTicketProvider =
    StateNotifierProvider.autoDispose<CreateSupportTicketController, CreateSupportTicketState>((ref) {
  return CreateSupportTicketController(
    ref.watch(supportRepositoryProvider),
    ref.watch(supportAttachmentUploadServiceProvider),
  );
});

class ReportIssueController extends StateNotifier<ReportIssueState> {
  final SupportRepository _repository;
  final SupportAttachmentUploadService _uploadService;
  final ReportIssueContext _context;

  ReportIssueController(this._repository, this._uploadService, this._context) : super(ReportIssueState.initial(_context));

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

  void setAttachmentPath(String value) {
    state = state.copyWith(
      attachmentPath: value,
      clearFailure: true,
      clearCreatedTicketId: true,
      fieldErrors: _withoutErrors(const <String>['attachment_path']),
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
          message: 'Please correct the highlighted report details',
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
      attachmentPath: state.attachmentPath.trim(),
    );

    String? finalTicketId = result.valueOrNull;
    if (result.isSuccess && finalTicketId != null && state.attachmentPath.trim().isNotEmpty) {
      final relocateResult = await _uploadService.relocateAttachment(
        currentPath: state.attachmentPath.trim(),
        targetPathSegment: 'support_ticket/$finalTicketId',
      );
      if (relocateResult.isFailure) {
        state = state.copyWith(
          isSubmitting: false,
          failure: const ServerFailure(message: 'Report created but failed to finalize attachment.'),
          createdTicketId: finalTicketId,
        );
        return result;
      }
    }

    state = state.copyWith(
      isSubmitting: false,
      failure: result.failureOrNull,
      createdTicketId: finalTicketId,
      attachmentPath: result.isSuccess ? '' : state.attachmentPath,
    );
    return result;
  }

  Map<String, String> _validate() {
    final errors = <String, String>{};
    if (!reportIssueCategories.contains(state.category)) {
      errors['category'] = 'Select a valid report category';
    }
    if (state.description.trim().length < 10) {
      errors['message_body'] = 'Describe the issue in at least 10 characters';
    }
    if (state.attachmentPath.trim().isEmpty) {
      errors['attachment_path'] = 'Attach one evidence image before submitting this report';
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

final reportIssueProvider = StateNotifierProvider.autoDispose
    .family<ReportIssueController, ReportIssueState, ReportIssueContext>((ref, context) {
  return ReportIssueController(
    ref.watch(supportRepositoryProvider),
    ref.watch(supportAttachmentUploadServiceProvider),
    context,
  );
});

class SupportReplyState {
  final String messageBody;
  final String attachmentPath;
  final bool isSubmitting;
  final AppFailure? failure;
  final String? lastReplyId;
  final Map<String, String> fieldErrors;

  const SupportReplyState({
    required this.messageBody,
    required this.attachmentPath,
    required this.isSubmitting,
    required this.failure,
    required this.lastReplyId,
    required this.fieldErrors,
  });

  factory SupportReplyState.initial() {
    return const SupportReplyState(
      messageBody: '',
      attachmentPath: '',
      isSubmitting: false,
      failure: null,
      lastReplyId: null,
      fieldErrors: <String, String>{},
    );
  }

  SupportReplyState copyWith({
    String? messageBody,
    String? attachmentPath,
    bool? isSubmitting,
    AppFailure? failure,
    bool? clearFailure,
    String? lastReplyId,
    bool? clearLastReplyId,
    Map<String, String>? fieldErrors,
  }) {
    return SupportReplyState(
      messageBody: messageBody ?? this.messageBody,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failure: clearFailure == true ? null : failure ?? this.failure,
      lastReplyId: clearLastReplyId == true ? null : lastReplyId ?? this.lastReplyId,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}

class SupportReplyController extends StateNotifier<SupportReplyState> {
  final SupportRepository _repository;
  final SupportAttachmentUploadService _uploadService;
  final String _ticketId;

  SupportReplyController(this._repository, this._uploadService, this._ticketId) : super(SupportReplyState.initial());

  void setMessageBody(String value) {
    state = state.copyWith(
      messageBody: value,
      clearFailure: true,
      clearLastReplyId: true,
      fieldErrors: _withoutErrors(const <String>['message_body']),
    );
  }

  void setAttachmentPath(String value) {
    state = state.copyWith(
      attachmentPath: value,
      clearFailure: true,
      clearLastReplyId: true,
    );
  }

  Future<Result<String>> submit() async {
    if (state.isSubmitting) {
      return const Failure<String>(BusinessRuleFailure(message: 'Reply submission is already in progress'));
    }

    final fieldErrors = _validate();
    if (fieldErrors.isNotEmpty) {
      state = state.copyWith(fieldErrors: fieldErrors, clearFailure: true, clearLastReplyId: true);
      return Failure<String>(
        ValidationFailure(
          message: 'Please enter a longer reply',
          fieldErrors: fieldErrors,
        ),
      );
    }

    state = state.copyWith(
      isSubmitting: true,
      clearFailure: true,
      clearLastReplyId: true,
      fieldErrors: const <String, String>{},
    );

    final result = await _repository.replyToTicket(
      ticketId: _ticketId,
      messageBody: state.messageBody,
      attachmentPath: state.attachmentPath.trim(),
    );

    final replyId = result.valueOrNull;
    if (result.isSuccess && replyId != null && state.attachmentPath.trim().isNotEmpty) {
      final relocateResult = await _uploadService.relocateAttachment(
        currentPath: state.attachmentPath.trim(),
        targetPathSegment: 'support_reply/$replyId',
      );
      if (relocateResult.isFailure) {
        debugPrint('Support reply attachment relocation failed for reply $replyId: ${relocateResult.failureOrNull}');
      }
    }

    state = state.copyWith(
      isSubmitting: false,
      failure: result.failureOrNull,
      lastReplyId: replyId,
      attachmentPath: result.isSuccess ? '' : state.attachmentPath,
      messageBody: result.isSuccess ? '' : state.messageBody,
    );
    return result;
  }

  Map<String, String> _validate() {
    final errors = <String, String>{};
    if (state.messageBody.trim().length < 2) {
      errors['message_body'] = 'Reply must contain at least 2 characters';
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
    ref.watch(supportAttachmentUploadServiceProvider),
    ticketId,
  );
});
