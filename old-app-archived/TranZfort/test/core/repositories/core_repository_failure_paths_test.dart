import 'package:app/src/core/error/app_failure.dart';
import 'package:app/src/core/error/result.dart';
import 'package:app/src/core/repositories/auth_repository.dart';
import 'package:app/src/core/repositories/chat_repository.dart';
import 'package:app/src/core/repositories/load_repository.dart';
import 'package:app/src/core/repositories/notification_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final client = SupabaseClient(
    'http://127.0.0.1:1',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dGVzdA.sig',
  );

  group('Repository failure and fallback paths', () {
    test('AuthRepository.saveMobileNumber returns auth failure with no session', () async {
      final repository = AuthRepository(client, GoogleSignIn(scopes: const []));

      final result = await repository.saveMobileNumber('+911234567890');

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).type, AppFailureType.auth);
    });

    test('AuthRepository OTP methods return Failure on unreachable backend', () async {
      final repository = AuthRepository(client, GoogleSignIn(scopes: const []));

      final sendOtp = await repository.sendOtp('+911234567890');
      final verifyOtp = await repository.verifyOtp('+911234567890', '123456');

      expect(sendOtp, isA<Failure<void>>());
      expect(verifyOtp, isA<Failure<User>>());
    });

    test('ChatRepository.getConversations returns auth failure when signed out', () async {
      final repository = ChatRepository(client);

      final result = await repository.getConversations();

      expect(result, isA<Failure<List<Map<String, dynamic>>>>());
      expect(
        (result as Failure<List<Map<String, dynamic>>>).type,
        AppFailureType.auth,
      );
    });

    test('ChatRepository data methods return Failure when backend is unreachable', () async {
      final repository = ChatRepository(client);

      final getMessages = await repository.getMessages('conversation-1');
      final sendMessage = await repository.sendMessage(
        conversationId: 'conversation-1',
        senderId: 'user-1',
        messageType: 'text',
        textContent: 'hello',
      );

      expect(getMessages, isA<Failure<List<Map<String, dynamic>>>>());
      expect(sendMessage, isA<Failure<Map<String, dynamic>>>());

      final markRead = await repository.markMessagesAsRead(
        'conversation-1',
        'user-1',
      );
      final getOrCreate = await repository.getOrCreateConversation(
        loadId: 'load-1',
        supplierId: 'supplier-1',
        truckerId: 'trucker-1',
      );
      final getById = await repository.getConversationById('conversation-1');

      expect(markRead, isA<Failure<void>>());
      expect(getOrCreate, isA<Failure<Map<String, dynamic>>>());
      expect(getById, isA<Failure<Map<String, dynamic>>>());
    });

    test('NotificationRepository methods return Failure when backend is unreachable', () async {
      final repository = NotificationRepository(client);

      final getNotifications = await repository.getNotifications('user-1');
      final markAsRead = await repository.markAsRead('notification-1');
      final markAll = await repository.markAllAsRead('user-1');

      expect(getNotifications, isA<Failure<List<Map<String, dynamic>>>>());
      expect(markAsRead, isA<Failure<void>>());
      expect(markAll, isA<Failure<void>>());
    });

    test('LoadRepository.getDieselPrice falls back to default value on failure', () async {
      final repository = LoadRepository(client);

      final result = await repository.getDieselPrice('MH');

      expect(result, isA<Success<double>>());
      expect((result as Success<double>).data, 90);
    });

    test('LoadRepository marketplace methods return Failure when backend is unreachable', () async {
      final repository = LoadRepository(client);

      final createLoad = await repository.createLoad(
        supplierId: 'supplier-1',
        payload: {
          'origin_city': 'Mumbai',
          'dest_city': 'Pune',
          'material': 'Steel',
          'weight_tonnes': 12,
          'price': 15000,
        },
      );
      final findLoads = await repository.findLoads(page: 1, pageSize: 10);
      final myLoads = await repository.myLoads(
        supplierId: 'supplier-1',
        completed: false,
      );
      final loadDetail = await repository.getLoadDetail('load-1');
      final childLoads = await repository.getChildLoads('parent-load-1');
      final deactivate = await repository.deactivateLoad('load-1');
      final bookLoad = await repository.bookLoad(
        parentLoadId: 'parent-load',
        truckerId: 'trucker-1',
        truckId: 'truck-1',
      );
      final approveBooking = await repository.approveBooking('child-load-1');
      final rejectBooking = await repository.rejectBooking('child-load-1');
      final verifiedTrucks = await repository.getVerifiedTrucks('trucker-1');

      expect(createLoad, isA<Failure<Map<String, dynamic>>>());
      expect(findLoads, isA<Failure<List<Map<String, dynamic>>>>());
      expect(myLoads, isA<Failure<List<Map<String, dynamic>>>>());
      expect(loadDetail, isA<Failure<Map<String, dynamic>>>());
      expect(childLoads, isA<Failure<List<Map<String, dynamic>>>>());
      expect(deactivate, isA<Failure<void>>());
      expect(bookLoad, isA<Failure<void>>());
      expect(approveBooking, isA<Failure<void>>());
      expect(rejectBooking, isA<Failure<void>>());
      expect(verifiedTrucks, isA<Failure<List<Map<String, dynamic>>>>());
    });

    test('LoadRepository trip lifecycle methods return Failure when backend is unreachable', () async {
      final repository = LoadRepository(client);

      final myTrips = await repository.getMyTrips(
        truckerId: 'trucker-1',
        completed: false,
      );
      final tripDetail = await repository.getTripDetail('trip-1');
      final startTrip = await repository.startTrip(tripId: 'trip-1');
      final markDelivered = await repository.markDelivered(tripId: 'trip-1');
      final uploadLr = await repository.uploadLr(
        tripId: 'trip-1',
        lrPhotoUrl: 'https://example.com/lr.jpg',
      );
      final uploadPod = await repository.uploadPod(
        tripId: 'trip-1',
        podPhotoUrl: 'https://example.com/pod.jpg',
      );
      final confirmDelivery = await repository.confirmDeliveryForChildLoad(
        'child-load-1',
      );

      expect(myTrips, isA<Failure<List<Map<String, dynamic>>>>());
      expect(tripDetail, isA<Failure<Map<String, dynamic>>>());
      expect(startTrip, isA<Failure<void>>());
      expect(markDelivered, isA<Failure<void>>());
      expect(uploadLr, isA<Failure<void>>());
      expect(uploadPod, isA<Failure<void>>());
      expect(confirmDelivery, isA<Failure<void>>());
    });

    test('LoadRepository rating/location methods return Failure when backend is unreachable', () async {
      final repository = LoadRepository(client);

      final rating = await repository.submitRating(
        loadId: 'load-1',
        reviewerId: 'supplier-1',
        revieweeId: 'trucker-1',
        reviewerRole: 'supplier',
        score: 5,
        comment: 'Great',
      );
      final ratingForLoad = await repository.getRatingForLoad(
        loadId: 'load-1',
        reviewerId: 'supplier-1',
      );
      final updateLocation = await repository.updateProfileLastKnownLocation(
        profileId: 'user-1',
        lat: 19.0760,
        lng: 72.8777,
      );

      expect(rating, isA<Failure<void>>());
      expect(ratingForLoad, isA<Failure<Map<String, dynamic>?>>());
      expect(updateLocation, isA<Failure<void>>());
    });
  });
}
