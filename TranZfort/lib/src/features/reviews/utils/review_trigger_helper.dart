import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/review_repository.dart';
import '../presentation/widgets/review_prompt_sheet.dart';

/// Helper class to trigger review prompts from various screens.
class ReviewTriggerHelper {
  static Future<bool> _canShowPrompt(
    WidgetRef ref, {
    required String targetUserId,
    required String contextType,
    required String contextId,
  }) async {
    final canReviewResult = await ref.read(reviewRepositoryProvider).canReviewUser(
      targetUserId: targetUserId,
      contextType: contextType,
      contextId: contextId,
    );

    return canReviewResult.when(
      success: (status) => status.canReview,
      failure: (_) => false,
    );
  }

  static Future<void> _showPrompt(
    BuildContext context, {
    required String targetUserId,
    required String targetUserName,
    required String contextType,
    required String contextId,
  }) async {
    if (!context.mounted) {
      return;
    }

    await ReviewPromptSheet.show(
      context,
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      contextType: contextType,
      contextId: contextId,
    );
  }

  /// Shows review prompt after chat interaction if criteria met.
  /// Call this when user has sent 3+ messages in a conversation.
  static Future<void> maybeShowChatReviewPrompt(
    BuildContext context,
    WidgetRef ref, {
    required String targetUserId,
    required String targetUserName,
    required String conversationId,
    required int messageCount,
  }) async {
    // Only show after 3+ messages exchanged
    if (messageCount < 3) return;

    final canReview = await _canShowPrompt(
      ref,
      targetUserId: targetUserId,
      contextType: 'chat',
      contextId: conversationId,
    );

    if (!canReview) return;

    await _showPrompt(
      context,
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      contextType: 'chat',
      contextId: conversationId,
    );
  }

  /// Shows review prompt after load is closed.
  static Future<void> showLoadClosedReviewPrompt(
    BuildContext context,
    WidgetRef ref, {
    required String targetUserId,
    required String targetUserName,
    required String loadId,
  }) async {
    final canReview = await _canShowPrompt(
      ref,
      targetUserId: targetUserId,
      contextType: 'load_closed',
      contextId: loadId,
    );

    if (!canReview) return;

    await _showPrompt(
      context,
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      contextType: 'load_closed',
      contextId: loadId,
    );
  }

  /// Shows review prompt after trip is completed.
  static Future<void> showTripCompletedReviewPrompt(
    BuildContext context,
    WidgetRef ref, {
    required String targetUserId,
    required String targetUserName,
    required String tripId,
  }) async {
    final canReview = await _canShowPrompt(
      ref,
      targetUserId: targetUserId,
      contextType: 'trip_completed',
      contextId: tripId,
    );

    if (!canReview) return;

    await _showPrompt(
      context,
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      contextType: 'trip_completed',
      contextId: tripId,
    );
  }

  /// Shows manual review prompt from load detail.
  static Future<void> showManualReviewPrompt(
    BuildContext context,
    WidgetRef ref, {
    required String targetUserId,
    required String targetUserName,
    required String loadId,
  }) async {
    final canReview = await _canShowPrompt(
      ref,
      targetUserId: targetUserId,
      contextType: 'load_closed',
      contextId: loadId,
    );

    if (!canReview) {
      // Show already reviewed message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have already reviewed this user')),
        );
      }
      return;
    }

    await _showPrompt(
      context,
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      contextType: 'load_closed',
      contextId: loadId,
    );
  }
}
