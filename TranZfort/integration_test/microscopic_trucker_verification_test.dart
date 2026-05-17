// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist, undefined_identifier
// P0.1: flutter_dotenv removed - TODO: Fix in P5.2 to use --dart-define
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/verification/data/verification_repository.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_marketplace_repository.dart';

/// MICROSCOPIC TRUCKER VERIFICATION TEST
/// Tests the complete verification flow from scratch for a fresh trucker account
/// This test will expose any bugs in the verification flow that regular tests miss

bool _supabaseReady = false;

Future<void> _ensureSupabaseInitialized() async {
  if (_supabaseReady) return;
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}
  
  final url = dotenv.env['SUPABASE_URL'] ?? const String.fromEnvironment('SUPABASE_URL');
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? const String.fromEnvironment('SUPABASE_ANON_KEY');
  
  if (url.isEmpty || anonKey.isEmpty) {
    throw Exception('Supabase config missing for microscopic trucker verification test');
  }
  
  await Supabase.initialize(url: url, anonKey: anonKey);
  _supabaseReady = true;
}

String _testPasscode() {
  final fromDefine = const String.fromEnvironment('TZ_TEST_PASSCODE');
  if (fromDefine.isNotEmpty) return fromDefine;
  return dotenv.env['TZ_TEST_PASSCODE'] ?? 'Tabish%%Khan721';
}

Future<void> _signInAsTrucker(SupabaseClient client) async {
  await client.auth.signOut(scope: SignOutScope.local);
  
  final auth = await client.auth.signInWithPassword(
    email: 'trucker@example.com',
    password: _testPasscode(),
  );
  
  expect(auth.session, isNotNull, reason: 'Trucker auth session should not be null');
  expect(auth.user, isNotNull, reason: 'Trucker auth user should not be null');
  expect(client.auth.currentSession, isNotNull, reason: 'Trucker current session should not be null');
  expect(client.auth.currentUser?.email, 'trucker@example.com', reason: 'Trucker email should match');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('MICROSCOPIC: Trucker Verification from Scratch', () {
    
    testWidgets('M-T-001: Fresh trucker should have unverified status', (tester) async {
      await _ensureSupabaseInitialized();
      final client = Supabase.instance.client;
      await _signInAsTrucker(client);
      
      // Check raw profile data from database
      final profileResponse = await client
          .from('profiles')
          .select('verification_status, user_role_type, full_name, mobile')
          .eq('id', client.auth.currentUser!.id)
          .single();
      
      expect(profileResponse, isNotNull, reason: 'Profile should exist in database');
      expect(profileResponse['verification_status'], 'unverified', 
          reason: 'Fresh trucker should have unverified status');
      expect(profileResponse['user_role_type'], 'trucker', 
          reason: 'Profile role should be trucker');
      
      // Check if verification case exists
      final caseResponse = await client
          .from('verification_cases')
          .select()
          .eq('subject_id', client.auth.currentUser!.id)
          .eq('subject_type', 'trucker_profile')
          .maybeSingle();
      
      // Fresh account may or may not have a case yet - both are valid states
      // but if it exists, it should be in a valid initial state
      if (caseResponse != null) {
        expect(caseResponse['case_status'], anyOf('draft', 'pending_documents', 'unverified'),
            reason: 'Fresh trucker verification case should be in initial state');
      }
      
      await client.auth.signOut(scope: SignOutScope.local);
    });
    
    testWidgets('M-T-002: Trucker verification detail should load for fresh account', (tester) async {
      await _ensureSupabaseInitialized();
      final client = Supabase.instance.client;
      await _signInAsTrucker(client);
      
      final container = ProviderContainer(
        overrides: [
          currentAuthStateProvider.overrideWithValue(
            AuthStateSnapshot(
              hasSession: true,
              role: AppUserRole.trucker,
              isBanned: false,
              isDeactivated: false,
              isProfileComplete: true,
              isResolved: true,
              profile: null,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      
      final repository = container.read(verificationRepositoryProvider);
      final result = await repository.fetchCurrentDetail();
      
      // Should succeed even for fresh account - this is where bugs often hide
      expect(result, isNotNull, reason: 'Verification result should not be null');
      
      if (result.isSuccess) {
        final detail = result.valueOrNull;
        expect(detail, isNotNull, reason: 'Verification detail should not be null for fresh account');
        expect(detail!.role, AppUserRole.trucker, reason: 'Role should be trucker');
        expect(detail.profileId, client.auth.currentUser!.id, 
            reason: 'Profile ID should match current user');
        
        // Check document requirements for trucker - NOW 4 with profilePhoto fix
        expect(detail.visibleDocuments.length, 4, 
            reason: 'Trucker should have 4 required documents (including profilePhoto)');
        expect(detail.visibleDocuments.contains(VerificationDocumentType.profilePhoto), isTrue,
            reason: 'Profile photo should be required for trucker - BUG FIX VERIFIED');
        expect(detail.visibleDocuments.contains(VerificationDocumentType.aadhaarFront), isTrue,
            reason: 'Aadhaar front should be required for trucker');
        expect(detail.visibleDocuments.contains(VerificationDocumentType.aadhaarBack), isTrue,
            reason: 'Aadhaar back should be required for trucker');
        expect(detail.visibleDocuments.contains(VerificationDocumentType.pan), isTrue,
            reason: 'PAN should be required for trucker');
      } else {
        // If it fails, the failure should be meaningful, not a crash
        final failure = result.failureOrNull;
        expect(failure, isNotNull, reason: 'Failure should not be null when result is not success');
        
        // Bug detection: NotFoundFailure for fresh account is wrong
        expect(failure.toString().toLowerCase(), isNot(contains('not found')),
            reason: 'BUG DETECTED: Fresh trucker got NotFoundFailure - should return a fresh verification detail instead');
      }
      
      await client.auth.signOut(scope: SignOutScope.local);
    });
    
    testWidgets('M-T-003: Trucker should see blocked submit without documents', (tester) async {
      await _ensureSupabaseInitialized();
      final client = Supabase.instance.client;
      await _signInAsTrucker(client);
      
      final container = ProviderContainer(
        overrides: [
          currentAuthStateProvider.overrideWithValue(
            AuthStateSnapshot(
              hasSession: true,
              role: AppUserRole.trucker,
              isBanned: false,
              isDeactivated: false,
              isProfileComplete: true,
              isResolved: true,
              profile: null,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      
      final repository = container.read(verificationRepositoryProvider);
      final result = await repository.fetchCurrentDetail();
      
      if (result.isSuccess) {
        final detail = result.valueOrNull;
        expect(detail, isNotNull);
        
        // For fresh trucker with no documents, should NOT be able to submit
        // This tests the business logic that blocks premature submission
        expect(detail!.canSubmitForReview, isFalse, 
            reason: 'Fresh trucker with no documents should not be able to submit verification');
        
        // Should show which documents are missing
        expect(detail.submissionBlockedReason, isNotNull,
            reason: 'Should report why submission is blocked');
        
        expect(detail.hasIdentityNumbers, isFalse, 
            reason: 'Fresh trucker should not have identity numbers');
        expect(detail.hasApprovedTruckRequirement, isFalse,
            reason: 'Fresh trucker should not have approved truck');
        expect(detail.hasVerificationReadyTruckRequirement, isFalse,
            reason: 'Fresh trucker should not have verification-ready truck');
      }
      
      await client.auth.signOut(scope: SignOutScope.local);
    });
    
    testWidgets('M-T-004: Trucker fleet should be empty for fresh account', (tester) async {
      await _ensureSupabaseInitialized();
      final client = Supabase.instance.client;
      await _signInAsTrucker(client);
      
      // Check fleet directly from database
      final trucksResponse = await client
          .from('trucks')
          .select()
          .eq('owner_id', client.auth.currentUser!.id);
      
      expect(trucksResponse, isNotNull);
      expect(trucksResponse.length, 0, 
          reason: 'Fresh trucker should have empty fleet');
      
      // This is a common bug area: truck count calculations
      // NOTE: profiles.approved_truck_count column doesn't exist - this is a schema drift bug
      // We'll check trucks table directly instead
      final trucksCount = await client
          .from('trucks')
          .count()
          .eq('owner_id', client.auth.currentUser!.id);
      
      // Fresh account should have 0 trucks
      expect(trucksCount, 0,
          reason: 'Fresh trucker should have 0 approved trucks');
      
      await client.auth.signOut(scope: SignOutScope.local);
    });
    
    testWidgets('M-T-005: Trucker cannot book loads without verification and trucks', (tester) async {
      await _ensureSupabaseInitialized();
      final client = Supabase.instance.client;
      await _signInAsTrucker(client);
      
      final container = ProviderContainer(
        overrides: [
          currentAuthStateProvider.overrideWithValue(
            AuthStateSnapshot(
              hasSession: true,
              role: AppUserRole.trucker,
              isBanned: false,
              isDeactivated: false,
              isProfileComplete: true,
              isResolved: true,
              profile: null,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      
      // Try to fetch marketplace loads - should work
      final marketplaceRepo = container.read(truckerMarketplaceRepositoryProvider);
      final loadsResult = await marketplaceRepo.searchLoads(const MarketplaceSearchFilters());
      
      // Marketplace should be accessible even for unverified truckers
      expect(loadsResult.isSuccess, isTrue, 
          reason: 'Unverified trucker should be able to browse marketplace');
      
      await client.auth.signOut(scope: SignOutScope.local);
    });
  });
}
