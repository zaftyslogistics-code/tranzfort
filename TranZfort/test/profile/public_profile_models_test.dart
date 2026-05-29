import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/features/profile/data/public_profile_models.dart';

void main() {
  group('PublicProfile', () {
    test('fromMap parses trucker profile correctly', () {
      final map = {
        'id': 'user-123',
        'full_name': 'John Doe',
        'role': 'trucker',
        'verification_status': 'verified',
        'location': 'Mumbai',
        'trust_scores': {
          'avg_rating': 4.5,
          'review_count': 10,
        },
        'role_specific': {
          'truck_count': 3,
          'completed_trips_count': 25,
          'fleet': [
            {
              'id': 'truck-1',
              'truck_number': 'MH01AB1234',
              'body_type': 'Open',
              'tyres': 10,
              'capacity_tonnes': 25.0,
              'status': 'verified',
            },
          ],
        },
        'is_self': false,
      };

      final profile = PublicProfile.fromMap(map);

      expect(profile.id, 'user-123');
      expect(profile.role, 'trucker');
      expect(profile.avgRating, 4.5);
      expect(profile.reviewCount, 10);
      expect(profile.truckCount, 3);
      expect(profile.hasReviews, true);
      expect(profile.isNewTrucker, false); // 25 trips > 5
    });

    test('fromMap parses supplier profile correctly', () {
      final map = {
        'id': 'user-456',
        'full_name': 'ABC Logistics',
        'company_name': 'ABC Logistics Pvt Ltd',
        'role': 'supplier',
        'verification_status': 'verified',
        'trust_scores': {
          'avg_rating': 0,
          'review_count': 0,
        },
        'role_specific': {
          'total_loads_posted': 100,
          'active_loads_count': 5,
          'is_super_load_eligible': true,
        },
        'is_self': false,
      };

      final profile = PublicProfile.fromMap(map);

      expect(profile.role, 'supplier');
      expect(profile.companyName, 'ABC Logistics Pvt Ltd');
      expect(profile.hasReviews, false); // 0 rating
      expect(profile.isNewSupplier, false); // 100 loads > 5
      expect(profile.isSuperLoadEligible, true);
    });

    test('displayName returns company name when available', () {
      final profile = PublicProfile(
        id: '1',
        fullName: 'John Doe',
        companyName: 'ABC Logistics',
        role: 'supplier',
        verificationStatus: 'verified',
        avgRating: 4.0,
        reviewCount: 5,
        isSelf: false,
      );

      expect(profile.displayName, 'ABC Logistics');
    });

    test('displayName returns full name when no company', () {
      final profile = PublicProfile(
        id: '1',
        fullName: 'John Doe',
        companyName: null,
        role: 'trucker',
        verificationStatus: 'verified',
        avgRating: 4.0,
        reviewCount: 5,
        isSelf: false,
      );

      expect(profile.displayName, 'John Doe');
    });

    test('isNewTrucker returns true for < 5 trips', () {
      final profile = PublicProfile(
        id: '1',
        fullName: 'New Trucker',
        role: 'trucker',
        verificationStatus: 'verified',
        avgRating: 0,
        reviewCount: 0,
        completedTripsCount: 3,
        isSelf: false,
      );

      expect(profile.isNewTrucker, true);
      expect(profile.newUserBadge, 'New Trucker');
    });

    test('fromMap uses profile photo path when avatar_url is missing', () {
      final map = {
        'id': 'user-789',
        'full_name': 'Photo Supplier',
        'role': 'supplier',
        'verification_status': 'verified',
        'profile_photo_document_path': 'profiles/user-789/photo.jpg',
        'trust_scores': {'avg_rating': 0, 'review_count': 0},
        'role_specific': {},
        'is_self': false,
      };

      final profile = PublicProfile.fromMap(map);

      expect(profile.avatarUrl, 'profiles/user-789/photo.jpg');
    });
  });

  group('PublicTruckPreview', () {
    test('fromMap parses correctly', () {
      final map = {
        'id': 'truck-1',
        'truck_number': 'MH01AB1234',
        'body_type': 'Open',
        'tyres': 10,
        'capacity_tonnes': 25.0,
        'status': 'verified',
      };

      final truck = PublicTruckPreview.fromMap(map);

      expect(truck.truckNumber, 'MH01AB1234');
      expect(truck.bodyType, 'Open');
      expect(truck.tyres, 10);
    });
  });
}
