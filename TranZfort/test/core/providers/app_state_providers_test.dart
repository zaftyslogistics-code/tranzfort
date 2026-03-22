import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/auth/data/auth_repository.dart';

Session _session() {
  return Session.fromJson({
    'access_token': 'test-access-token',
    'token_type': 'bearer',
    'refresh_token': 'test-refresh-token',
    'user': {
      'id': 'user-1',
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'user@example.com',
    },
  })!;
}

void main() {
  test('fromSessionAndProfile treats suspended trust safety status as restricted entry', () {
    final snapshot = AuthStateSnapshot.fromSessionAndProfile(
      _session(),
      const UserProfile(
        id: 'user-1',
        fullName: 'Aarav Singh',
        mobile: '9999999999',
        email: 'aarav@example.com',
        roleType: 'trucker',
        isBanned: false,
        accountDeletionStatus: 'active',
        trustSafetyStatus: 'suspended',
      ),
    );

    expect(snapshot.hasSession, isTrue);
    expect(snapshot.role, AppUserRole.trucker);
    expect(snapshot.isBanned, isTrue);
    expect(snapshot.isDeactivated, isFalse);
  });

  test('fromSessionAndProfile keeps normal trust safety status unrestricted when ban flag is false', () {
    final snapshot = AuthStateSnapshot.fromSessionAndProfile(
      _session(),
      const UserProfile(
        id: 'user-1',
        fullName: 'Aarav Singh',
        mobile: '9999999999',
        email: 'aarav@example.com',
        roleType: 'supplier',
        isBanned: false,
        accountDeletionStatus: 'active',
        trustSafetyStatus: 'normal',
      ),
    );

    expect(snapshot.hasSession, isTrue);
    expect(snapshot.role, AppUserRole.supplier);
    expect(snapshot.isBanned, isFalse);
    expect(snapshot.isDeactivated, isFalse);
  });
}
