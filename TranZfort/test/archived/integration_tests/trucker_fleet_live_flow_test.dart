import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/features/trucker/data/truck_document_upload_service.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_fleet_repository.dart';

bool _supabaseReady = false;

final supabaseUrl = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
final supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

Future<void> _ensureSupabaseInitialized() async {
  if (_supabaseReady) {
    return;
  }

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    // Will be handled by group-level skip
    return;
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  _supabaseReady = true;
}

String _testPasscode() {
  return const String.fromEnvironment('TZ_TEST_PASSCODE', defaultValue: 'Tabish%%Khan721');
}

String _truckerEmail() {
  return const String.fromEnvironment('TZ_TRUCKER_EMAIL', defaultValue: 'trucker@example.com');
}

String _adminEmail() {
  return const String.fromEnvironment('TZ_ADMIN_EMAIL', defaultValue: 'zaftyslogistics@gmail.com');
}

Future<void> _signIn(SupabaseClient client, String email) async {
  await client.auth.signOut(scope: SignOutScope.local);
  final auth = await client.auth.signInWithPassword(
    email: email,
    password: _testPasscode(),
  );
  expect(auth.session, isNotNull);
  expect(auth.user, isNotNull);
  expect(client.auth.currentUser?.email, email);
}

Future<String> _resolveTestImagePath() async {
  final fromDefine = const String.fromEnvironment('TZ_TEST_RC_IMAGE_PATH', defaultValue: '');
  final directCandidates = <String>[
    if (fromDefine.isNotEmpty) fromDefine,
  ];

  for (final candidate in directCandidates) {
    final file = File(candidate);
    if (file.existsSync()) {
      return file.absolute.path;
    }
  }

  const assetCandidates = <String>[
    'assets/images/icon.png',
    'assets/images/splash-screen-logo.png',
    'assets/images/main-logo-transparent.png',
  ];

  for (final assetPath in assetCandidates) {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      if (bytes.isEmpty) {
        continue;
      }
      final tempDir = await Directory.systemTemp.createTemp('tranzfort_rc_live_test_');
      final target = File('${tempDir.path}${Platform.pathSeparator}${assetPath.split('/').last}');
      await target.writeAsBytes(bytes, flush: true);
      return target.path;
    } catch (_) {}
  }

  throw FileSystemException('Could not prepare a local image file for RC upload live test.');
}

String _uniqueTruckNumber() {
  final suffix = DateTime.now().toUtc().millisecondsSinceEpoch.toString();
  final lastFour = suffix.substring(suffix.length - 4);
  return 'MH12TZ$lastFour';
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'TRUCKER live fleet flow uploads RC, creates truck, and admin approves it',
    (tester) async {
    await _ensureSupabaseInitialized();
    final client = Supabase.instance.client;

    await _signIn(client, _truckerEmail());
    final truckerId = client.auth.currentUser!.id;
    final imagePath = await _resolveTestImagePath();

    final uploadService = TruckDocumentUploadService(
      client,
      pickImageFn: (_) async => XFile(imagePath),
    );
    final repository = TruckerFleetRepository(
      SupabaseTruckerFleetBackend(client),
      () => client.auth.currentUser?.id,
    );

    final uploadResult = await uploadService.pickCompressAndUploadRcDocument(
      ownerId: truckerId,
      truckId: 'draft-truck',
      source: ImageSource.gallery,
    );

    expect(uploadResult.isSuccess, isTrue, reason: uploadResult.failureOrNull?.message);
    final rcPath = uploadResult.valueOrNull;
    expect(rcPath, isNotNull);
    expect(rcPath!, contains('/draft-truck/rc/rc_'));

    final truckNumber = _uniqueTruckNumber();
    final createResult = await repository.createTruck(
      truckNumber: truckNumber,
      bodyType: 'Open',
      tyres: 12,
      capacityTonnes: 25,
      rcDocumentPath: rcPath,
    );

    expect(createResult.isSuccess, isTrue, reason: createResult.failureOrNull?.message);
    final truckId = createResult.valueOrNull;
    expect(truckId, isNotNull);
    expect(truckId, isNotEmpty);

    final truckBeforeApproval = await client
        .from('trucks')
        .select('id, owner_id, truck_number, status, rc_document_path')
        .eq('id', truckId!)
        .maybeSingle();
    expect(truckBeforeApproval, isNotNull);
    expect((truckBeforeApproval!['owner_id'] ?? '').toString(), truckerId);
    expect((truckBeforeApproval['truck_number'] ?? '').toString(), truckNumber);
    expect((truckBeforeApproval['rc_document_path'] ?? '').toString(), rcPath);

    final myTrucksResult = await repository.getMyTrucks();
    expect(myTrucksResult.isSuccess, isTrue, reason: myTrucksResult.failureOrNull?.message);
    final myTruck = myTrucksResult.valueOrNull!.firstWhere((truck) => truck.id == truckId);
    expect(myTruck.truckNumber, truckNumber);
    expect(myTruck.hasRcDocument, isTrue);

    await _signIn(client, _adminEmail());

    final verificationCase = await client
        .from('verification_cases')
        .select('id, subject_type, subject_id, case_status')
        .eq('subject_type', 'truck')
        .eq('subject_id', truckId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    expect(verificationCase, isNotNull, reason: 'A truck verification case should exist for the created truck.');

    await client.rpc(
      'update_truck_verification_state',
      params: {
        'p_truck_id': truckId,
        'p_next_status': 'verified',
        'p_reason': null,
        'p_feedback_json': null,
      },
    );

    final truckAfterApproval = await client
        .from('trucks')
        .select('id, status, verified_at')
        .eq('id', truckId)
        .maybeSingle();
    expect(truckAfterApproval, isNotNull);
    expect((truckAfterApproval!['status'] ?? '').toString(), 'verified');
    expect((truckAfterApproval['verified_at'] ?? '').toString(), isNotEmpty);

    await _signIn(client, _truckerEmail());
    final truckerRepositoryAfterApproval = TruckerFleetRepository(
      SupabaseTruckerFleetBackend(client),
      () => client.auth.currentUser?.id,
    );
    final refreshedResult = await truckerRepositoryAfterApproval.getMyTrucks();
    expect(refreshedResult.isSuccess, isTrue, reason: refreshedResult.failureOrNull?.message);
    final approvedTruck = refreshedResult.valueOrNull!.firstWhere((truck) => truck.id == truckId);
    expect(approvedTruck.status, TruckerFleetTruckStatus.verified);

    await client.auth.signOut(scope: SignOutScope.local);
    expect(client.auth.currentSession, isNull);
  }, skip: supabaseUrl.isEmpty || supabaseAnonKey.isEmpty ? 'SUPABASE_URL and SUPABASE_ANON_KEY required (run with --dart-define)' : null);
}
