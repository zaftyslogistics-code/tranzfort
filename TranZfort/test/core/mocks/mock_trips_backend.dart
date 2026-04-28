import 'package:tranzfort/src/features/trucker/data/trucker_trip_repository_models.dart';

/// Centralized mock implementation of [TruckerTripsBackend] for testing.
///
/// This mock provides:
/// - Configurable behavior via public fields
/// - Method call tracking for verification
/// - Default sensible implementations
///
/// Usage:
/// ```dart
/// final mock = MockTruckerTripsBackend()
///   ..rows = [testTrip]
///   ..detailRow = testTripDetail
///   ..error = null;
/// ```
class MockTruckerTripsBackend implements TruckerTripsBackend {
  // ==================== CONFIGURABLE BEHAVIOR ====================

  /// Return value for fetchTrips
  List<Map<String, dynamic>> rows = const <Map<String, dynamic>>[];

  /// Return value for fetchTripDetail
  Map<String, dynamic>? detailRow;

  /// Return value for fetchOwnRating
  Map<String, dynamic>? ratingRow;

  /// Return value for uploadTripLr
  Map<String, dynamic>? lrUploadRow;

  /// Exception to throw from any method (if non-null)
  Object? error;

  /// Supplier profile data
  Map<String, dynamic>? supplierProfile;

  /// Supplier extension data
  Map<String, dynamic>? supplierExtension;

  /// Trip dispute summary data
  Map<String, dynamic>? disputeSummary;

  // ==================== TRACKING FIELDS ====================

  String? fetchedTripsTruckerId;
  List<String>? fetchedTripsStages;

  String? fetchedTripDetailTruckerId;
  String? fetchedTripDetailTripId;

  String? fetchedTripDetailWithSupplierTruckerId;
  String? fetchedTripDetailWithSupplierTripId;

  String? advancedTripId;
  String? advancedStage;
  double? advancedGpsLat;
  double? advancedGpsLng;

  String? uploadedProofTripId;
  String? uploadedProofPodPath;
  String? uploadedProofLrPath;
  double? uploadedProofGpsLat;
  double? uploadedProofGpsLng;

  String? uploadedLrTripId;
  String? uploadedLrPath;

  String? fetchedOwnRatingReviewerId;
  String? fetchedOwnRatingLoadId;

  String? submittedRatingLoadId;
  int? submittedRatingScore;
  String? submittedRatingComment;

  String? fetchedSupplierProfileId;
  String? fetchedSupplierExtensionId;
  String? fetchedTripDisputeSummaryId;

  // ==================== METHOD IMPLEMENTATIONS ====================

  void _throwIfError() {
    if (error != null) throw error!;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTrips({
    required String truckerId,
    required List<String> stages,
    int limit = 15,
    int offset = 0,
  }) async {
    _throwIfError();
    fetchedTripsTruckerId = truckerId;
    fetchedTripsStages = stages;
    return rows;
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({
    required String truckerId,
    required String tripId,
  }) async {
    _throwIfError();
    fetchedTripDetailTruckerId = truckerId;
    fetchedTripDetailTripId = tripId;
    return detailRow;
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDetailWithSupplier({
    required String truckerId,
    required String tripId,
  }) async {
    _throwIfError();
    fetchedTripDetailWithSupplierTruckerId = truckerId;
    fetchedTripDetailWithSupplierTripId = tripId;

    if (detailRow == null) return null;

    final supplierId = (detailRow!['supplier_id'] ?? 'supplier-1').toString();
    return <String, dynamic>{
      'trip': detailRow,
      'supplier_profile': supplierProfile ?? _defaultSupplierProfile(supplierId),
      'supplier_extension': supplierExtension ?? _defaultSupplierExtension(supplierId),
      'dispute_summary': disputeSummary,
    };
  }

  Map<String, dynamic> _defaultSupplierProfile(String supplierId) => {
        'id': supplierId,
        'full_name': 'Test Supplier',
        'verification_status': 'verified',
        'mobile': '+919876543210',
      };

  Map<String, dynamic> _defaultSupplierExtension(String supplierId) => {
        'id': supplierId,
        'company_name': 'Test Logistics',
      };

  @override
  Future<void> advanceTripStage({
    required String tripId,
    required String newStage,
    double? gpsLat,
    double? gpsLng,
  }) async {
    _throwIfError();
    advancedTripId = tripId;
    advancedStage = newStage;
    advancedGpsLat = gpsLat;
    advancedGpsLng = gpsLng;
  }

  @override
  Future<void> uploadTripProof({
    required String tripId,
    required String podPath,
    String? lrPath,
    double? gpsLat,
    double? gpsLng,
  }) async {
    _throwIfError();
    uploadedProofTripId = tripId;
    uploadedProofPodPath = podPath;
    uploadedProofLrPath = lrPath;
    uploadedProofGpsLat = gpsLat;
    uploadedProofGpsLng = gpsLng;
  }

  @override
  Future<Map<String, dynamic>?> uploadTripLr({
    required String tripId,
    required String lrPath,
  }) async {
    _throwIfError();
    uploadedLrTripId = tripId;
    uploadedLrPath = lrPath;
    return lrUploadRow ?? <String, dynamic>{'id': tripId};
  }

  @override
  Future<Map<String, dynamic>?> fetchOwnRating({
    required String reviewerId,
    required String loadId,
  }) async {
    _throwIfError();
    fetchedOwnRatingReviewerId = reviewerId;
    fetchedOwnRatingLoadId = loadId;
    return ratingRow;
  }

  @override
  Future<void> submitRating({
    required String loadId,
    required int score,
    String? comment,
  }) async {
    _throwIfError();
    submittedRatingLoadId = loadId;
    submittedRatingScore = score;
    submittedRatingComment = comment;
    ratingRow = {
      'id': 'rating-1',
      'score': score,
      'comment': comment,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierProfile(String supplierId) async {
    _throwIfError();
    fetchedSupplierProfileId = supplierId;
    return supplierProfile ?? _defaultSupplierProfile(supplierId);
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId) async {
    _throwIfError();
    fetchedSupplierExtensionId = supplierId;
    return supplierExtension ?? _defaultSupplierExtension(supplierId);
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDisputeSummary({
    required String tripId,
  }) async {
    _throwIfError();
    fetchedTripDisputeSummaryId = tripId;
    return disputeSummary;
  }

  // ==================== HELPER METHODS ====================

  /// Sets up a complete trip detail scenario
  void setupTripDetail({
    required String tripId,
    required String supplierId,
    Map<String, dynamic>? customDetail,
    Map<String, dynamic>? customSupplierProfile,
    Map<String, dynamic>? customSupplierExtension,
    Map<String, dynamic>? customDisputeSummary,
  }) {
    detailRow = customDetail ?? {
      'id': tripId,
      'load_id': 'load-1',
      'supplier_id': supplierId,
      'truck_id': 'truck-1',
      'stage': 'in_transit',
      'assigned_at': '2026-03-08T12:00:00.000Z',
      'started_at': '2026-03-09T08:00:00.000Z',
      'delivered_at': null,
      'pod_uploaded_at': null,
      'completed_at': null,
      'lr_document_path': null,
      'pod_document_path': null,
      'load_snapshot_summary': {
        'origin_label': 'Chandrapur, Maharashtra',
        'destination_label': 'Mumbai, Maharashtra',
        'material': 'Coal',
      },
      'loads': {
        'origin_label': 'Chandrapur, Maharashtra',
        'origin_city': 'Chandrapur',
        'origin_state': 'Maharashtra',
        'origin_lat': 19.95,
        'origin_lng': 79.30,
        'destination_label': 'Mumbai, Maharashtra',
        'destination_city': 'Mumbai',
        'destination_state': 'Maharashtra',
        'destination_lat': 19.07,
        'destination_lng': 72.87,
        'route_distance_km': 820,
        'route_duration_minutes': 780,
        'route_snapshot_source': 'osrm',
        'material': 'Coal',
        'pickup_date': '2026-03-12',
      },
      'trucks': {
        'truck_number': 'MH12AB1234',
        'body_type': 'Open',
        'tyres': 12,
      },
    };
    supplierProfile = customSupplierProfile;
    supplierExtension = customSupplierExtension;
    disputeSummary = customDisputeSummary;
  }

  /// Sets up a list of trips for fetchTrips
  void setupTrips(List<Map<String, dynamic>> trips) {
    rows = trips;
  }

  /// Sets up a rating scenario
  void setupRating({
    required String loadId,
    required int score,
    String? comment,
  }) {
    ratingRow = {
      'id': 'rating-1',
      'load_id': loadId,
      'score': score,
      'comment': comment,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Clears all tracking fields
  void clearTracking() {
    fetchedTripsTruckerId = null;
    fetchedTripsStages = null;
    fetchedTripDetailTruckerId = null;
    fetchedTripDetailTripId = null;
    fetchedTripDetailWithSupplierTruckerId = null;
    fetchedTripDetailWithSupplierTripId = null;
    advancedTripId = null;
    advancedStage = null;
    advancedGpsLat = null;
    advancedGpsLng = null;
    uploadedProofTripId = null;
    uploadedProofPodPath = null;
    uploadedProofLrPath = null;
    uploadedProofGpsLat = null;
    uploadedProofGpsLng = null;
    uploadedLrTripId = null;
    uploadedLrPath = null;
    fetchedOwnRatingReviewerId = null;
    fetchedOwnRatingLoadId = null;
    submittedRatingLoadId = null;
    submittedRatingScore = null;
    submittedRatingComment = null;
    fetchedSupplierProfileId = null;
    fetchedSupplierExtensionId = null;
    fetchedTripDisputeSummaryId = null;
  }
}
