import 'dart:async';
import 'dart:io';

import 'package:app/src/features/marketplace/providers/marketplace_providers.dart';
import 'package:app/src/features/marketplace/models/load_filters.dart';
import 'package:app/src/features/trips/providers/trips_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Shared test utilities for user integration tests

void resetFakeNotifiers() {
  FakeFindLoadsNotifier.searchCalls = 0;
  FakeFindLoadsNotifier.lastFilters = null;
  FakeBookLoadActionNotifier.bookLoadWithTruckCalls = 0;
  FakeBookLoadActionNotifier.lastParentLoadId = null;
  FakeBookLoadActionNotifier.lastTruckId = null;
  FakeTripActionNotifier.startTripCalled = false;
  FakeTripActionNotifier.markDeliveredCalled = false;
  FakeTripActionNotifier.uploadLrCalled = false;
  FakeTripActionNotifier.uploadPodCalled = false;
  FakeChatNotifier.sendMessageCalls = 0;
  FakeChatNotifier.lastMessageContent = null;
  FakeChatNotifier.lastMessageType = null;
  FakeBotService.queryCount = 0;
  FakeBotService.lastQuery = null;
  FakeBotService.shouldThrow = false;
}

AuthState signedInAuthState() {
  final session = Session.fromJson({
    'access_token': 'fake',
    'token_type': 'bearer',
    'refresh_token': 'fake',
    'expires_in': 3600,
    'user': {
      'id': 'test-user-id',
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'test@example.com',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'created_at': '2026-03-01T00:00:00Z',
    },
  });

  return AuthState(AuthChangeEvent.signedIn, session);
}

// Fake notifiers for testing
class FakeFindLoadsNotifier extends FindLoadsNotifier {
  static int searchCalls = 0;
  static LoadFilters? lastFilters;

  FakeFindLoadsNotifier(
    super.ref, {
    required List<Map<String, dynamic>> seededResults,
    required List<Map<String, dynamic>> seededTrucks,
  }) {
    state = FindLoadsState(
      results: seededResults,
      myTrucks: seededTrucks,
      filters: const LoadFilters(),
    );
  }

  @override
  Future<void> initialize() async {}

  Future<void> search(LoadFilters filters) async {
    searchCalls += 1;
    lastFilters = filters;
    state = state.copyWith(filters: filters);
  }

  @override
  Future<void> loadMore() async {}

  Future<void> resetFilters() async {}
}

class FakeBookLoadActionNotifier extends LoadActionNotifier {
  FakeBookLoadActionNotifier(super.ref);

  static int bookLoadWithTruckCalls = 0;
  static String? lastParentLoadId;
  static String? lastTruckId;

  @override
  Future<bool> bookLoadWithTruck({
    required String parentLoadId,
    required String truckId,
  }) async {
    bookLoadWithTruckCalls += 1;
    lastParentLoadId = parentLoadId;
    lastTruckId = truckId;
    state = const AsyncData(null);
    return true;
  }
}

class FakeTripActionNotifier extends TripActionNotifier {
  FakeTripActionNotifier(super.ref);

  static bool startTripCalled = false;
  static bool markDeliveredCalled = false;
  static bool uploadLrCalled = false;
  static bool uploadPodCalled = false;

  @override
  Future<bool> startTrip(String tripId) async {
    startTripCalled = true;
    state = const AsyncData(null);
    return true;
  }

  @override
  Future<bool> markDelivered(String tripId) async {
    markDeliveredCalled = true;
    state = const AsyncData(null);
    return true;
  }

  @override
  Future<bool> uploadLr({required File lrFile, required String tripId}) async {
    uploadLrCalled = true;
    state = const AsyncData(null);
    return true;
  }

  @override
  Future<bool> uploadPod({required File podFile, required String tripId}) async {
    uploadPodCalled = true;
    state = const AsyncData(null);
    return true;
  }
}

class FakeChatNotifier extends StateNotifier<AsyncValue<void>> {
  FakeChatNotifier() : super(const AsyncData(null));

  static int sendMessageCalls = 0;
  static String? lastMessageContent;
  static String? lastMessageType;

  @override
  AsyncValue<void> get state => super.state;

  @override
  set state(AsyncValue<void> value) => super.state = value;

  Future<void> sendMessage(String content, {String type = 'text'}) async {
    sendMessageCalls += 1;
    lastMessageContent = content;
    lastMessageType = type;
  }
}

class FakeBotService {
  static int queryCount = 0;
  static String? lastQuery;
  static bool shouldThrow = false;

  Future<Map<String, dynamic>> query(String text, {String? conversationId}) async {
    queryCount += 1;
    lastQuery = text;
    
    if (shouldThrow) {
      throw Exception('Network error');
    }
    
    return {
      'text': 'Response to: $text',
      'actions': [],
      'suggestions': [],
    };
  }

  Stream<Map<String, dynamic>> streamQuery(String text, {String? conversationId}) {
    return Stream.fromFuture(query(text, conversationId: conversationId));
  }
}

// Common test data
final Map<String, dynamic> testLoad = {
  'id': 'load-test-1',
  'supplier_id': 'supplier-test',
  'origin_city': 'Mumbai',
  'origin_state': 'Maharashtra',
  'dest_city': 'Pune',
  'dest_state': 'Maharashtra',
  'material': 'Steel',
  'weight_tonnes': 24,
  'price': 64000,
  'distance_km': 150,
  'trucks_needed': 2,
  'trucks_booked': 0,
  'required_truck_type': 'open',
  'required_tyres': const [10],
  'advance_percentage': 20,
  'poster_label': 'Test Supplier Pvt Ltd',
  'created_at': DateTime.now().toIso8601String(),
  'pickup_date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
};

final List<Map<String, dynamic>> testTrucks = [
  {
    'id': 'truck-verified-1',
    'truck_number': 'MH12AB1234',
    'body_type': 'open',
    'tyres': 10,
    'capacity_tonnes': 25,
  },
];

final Map<String, dynamic> testUserProfile = {
  'user_role_type': 'trucker',
  'verification_status': 'verified',
  'mobile': '+919999999999',
};

final Map<String, dynamic> testSupplierProfile = {
  'user_role_type': 'supplier',
  'verification_status': 'verified',
  'mobile': '+919888888888',
  'company_name': 'Test Supplier Pvt Ltd',
};

