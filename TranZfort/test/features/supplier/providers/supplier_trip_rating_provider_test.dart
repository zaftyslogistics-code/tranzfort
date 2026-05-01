import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_trip_repository.dart';
import 'package:tranzfort/src/features/supplier/providers/supplier_trip_rating_provider.dart';

class _RatingBackend implements SupplierTripsBackend {
  Map<String, dynamic>? ratingRow;
  Object? error;
  String? submittedLoadId;
  int? submittedScore;
  String? submittedComment;

  @override
  Future<List<Map<String, dynamic>>> fetchTrips({required String supplierId, required List<String> stages, int limit = 15, int offset = 0}) async {
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({required String supplierId, required String tripId}) async => null;

  @override
  Future<Map<String, dynamic>?> fetchTripDetailConsolidated({required String supplierId, required String tripId}) async => null;

  @override
  Future<Map<String, dynamic>?> fetchTruckerProfile(String truckerId) async => null;

  @override
  Future<Map<String, dynamic>?> fetchOwnRating({required String reviewerId, required String loadId}) async {
    if (error != null) {
      throw error!;
    }
    return ratingRow;
  }

  @override
  Future<void> submitRating({required String loadId, required int score, String? comment}) async {
    if (error != null) {
      throw error!;
    }
    submittedLoadId = loadId;
    submittedScore = score;
    submittedComment = comment;
    ratingRow = {
      'id': 'rating-1',
      'score': score,
      'comment': comment,
      'created_at': '2026-03-10T13:00:00.000Z',
    };
  }

  @override
  Future<String?> createProofSignedUrl(String path) async => null;

  @override
  Future<void> cancelTrip(String tripId) async {}

  @override
  Future<Map<String, dynamic>?> fetchTripDisputeSummary({required String tripId}) async => null;

  @override
  Future<void> confirmTripDelivery(String tripId) async {}

  @override
  Future<String> raiseTripDispute({
    required String tripId,
    required String category,
    required String reason,
    String? attachmentPath,
  }) async => 'support-ticket-1';
}

void main() {
  test('supplier trip rating provider loads existing rating', () async {
    final backend = _RatingBackend()
      ..ratingRow = {
        'id': 'rating-1',
        'score': 4,
        'comment': 'Reliable trucker',
        'created_at': '2026-03-10T13:00:00.000Z',
      };
    final controller = SupplierTripRatingController(
      SupplierTripsRepository(backend, () => 'supplier-1'),
      'load-1',
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.submittedRating?.score, 4);
    expect(controller.state.commentDraft, 'Reliable trucker');
  });

  test('supplier trip rating provider submits rating', () async {
    final backend = _RatingBackend();
    final controller = SupplierTripRatingController(
      SupplierTripsRepository(backend, () => 'supplier-1'),
      'load-1',
    );
    await Future<void>.delayed(Duration.zero);
    controller.setSelectedScore(5);
    controller.setCommentDraft('Smooth coordination');

    final result = await controller.submit();

    expect(result.isSuccess, isTrue);
    expect(backend.submittedLoadId, 'load-1');
    expect(backend.submittedScore, 5);
    expect(controller.state.submittedRating?.score, 5);
  });

  test('supplier trip rating provider surfaces repository failures', () async {
    final backend = _RatingBackend()
      ..error = const PostgrestException(message: 'No completed trip found for rating');
    final controller = SupplierTripRatingController(
      SupplierTripsRepository(backend, () => 'supplier-1'),
      'load-1',
    );
    await Future<void>.delayed(Duration.zero);
    controller.setSelectedScore(5);

    final result = await controller.submit();

    expect(result.failureOrNull, isA<BusinessRuleFailure>());
    expect(controller.state.isSubmitting, isFalse);
  });
}
