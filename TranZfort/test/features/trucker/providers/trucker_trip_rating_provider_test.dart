import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_trip_repository.dart';
import 'package:tranzfort/src/features/trucker/providers/trucker_trip_rating_provider.dart';

class _RatingBackend implements TruckerTripsBackend {
  Map<String, dynamic>? ratingRow;
  Object? error;
  String? submittedLoadId;
  int? submittedScore;
  String? submittedComment;

  @override
  Future<List<Map<String, dynamic>>> fetchTrips({required String truckerId, required List<String> stages}) async {
    return const <Map<String, dynamic>>[];
  }

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
  Future<Map<String, dynamic>?> fetchTripDetail({required String truckerId, required String tripId}) async => null;

  @override
  Future<Map<String, dynamic>?> fetchTripDetailWithSupplier({required String truckerId, required String tripId}) async => null;

  @override
  Future<void> advanceTripStage({required String tripId, required String newStage, double? gpsLat, double? gpsLng}) async {}

  @override
  Future<void> uploadTripProof({required String tripId, required String podPath, String? lrPath, double? gpsLat, double? gpsLng}) async {}

  @override
  Future<Map<String, dynamic>?> uploadTripLr({required String tripId, required String lrPath}) async => {'id': tripId};

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId) async => null;

  @override
  Future<Map<String, dynamic>?> fetchSupplierProfile(String supplierId) async => null;

  @override
  Future<Map<String, dynamic>?> fetchTripDisputeSummary({required String tripId}) async => null;
}

void main() {
  test('trucker trip rating provider loads existing rating', () async {
    final backend = _RatingBackend()
      ..ratingRow = {
        'id': 'rating-1',
        'score': 4,
        'comment': 'Smooth unload',
        'created_at': '2026-03-10T13:00:00.000Z',
      };
    final controller = TruckerTripRatingController(
      TruckerTripsRepository(backend, () => 'trucker-1'),
      'load-1',
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.submittedRating?.score, 4);
    expect(controller.state.commentDraft, 'Smooth unload');
  });

  test('trucker trip rating provider submits rating', () async {
    final backend = _RatingBackend();
    final controller = TruckerTripRatingController(
      TruckerTripsRepository(backend, () => 'trucker-1'),
      'load-1',
    );
    await Future<void>.delayed(Duration.zero);
    controller.setSelectedScore(5);
    controller.setCommentDraft('Very professional supplier');

    final result = await controller.submit();

    expect(result.isSuccess, isTrue);
    expect(backend.submittedLoadId, 'load-1');
    expect(backend.submittedScore, 5);
    expect(controller.state.submittedRating?.score, 5);
  });

  test('trucker trip rating provider surfaces repository failures', () async {
    final backend = _RatingBackend()
      ..error = const PostgrestException(message: 'No completed trip found for rating');
    final controller = TruckerTripRatingController(
      TruckerTripsRepository(backend, () => 'trucker-1'),
      'load-1',
    );
    await Future<void>.delayed(Duration.zero);
    controller.setSelectedScore(5);

    final result = await controller.submit();

    expect(result.failureOrNull, isA<BusinessRuleFailure>());
    expect(controller.state.isSubmitting, isFalse);
  });
}
