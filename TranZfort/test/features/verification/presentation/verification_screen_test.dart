import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/features/verification/data/verification_document_upload_service.dart';
import 'package:tranzfort/src/features/verification/data/verification_location_service.dart';
import 'package:tranzfort/src/features/verification/data/verification_repository.dart';
import 'package:tranzfort/src/features/verification/presentation/verification_screen.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

class _FakeVerificationBackend implements VerificationBackend {
  Map<String, dynamic>? profileMap;
  Map<String, dynamic>? supplierMap;
  int approvedTruckCount = 0;
  int verificationReadyTruckCount = 1;
  Object? profileError;
  int submitCalls = 0;
  int resubmitCalls = 0;

  @override
  Future<int> countApprovedTrucks(String userId) async => approvedTruckCount;

  @override
  Future<int> countVerificationReadyTrucks(String userId) async => verificationReadyTruckCount;

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    if (profileError != null) {
      throw profileError!;
    }
    return profileMap;
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String userId) async => supplierMap;

  @override
  Future<String> resubmitVerificationCase() async {
    resubmitCalls += 1;
    return 'case-2';
  }

  @override
  Future<String> submitVerificationForReview() async {
    submitCalls += 1;
    return 'case-1';
  }

  @override
  Future<void> updateProfileFields(String userId, Map<String, dynamic> values) async {
    profileMap = {
      ...?profileMap,
      ...values,
    };
  }

  @override
  Future<void> updateSupplierFields(String userId, Map<String, dynamic> values) async {
    supplierMap = {
      ...?supplierMap,
      ...values,
    };
  }
}

class _FakeVerificationLocationService extends VerificationLocationService {
  _FakeVerificationLocationService({required this.location});

  final VerificationLocation? location;

  @override
  Future<VerificationLocation?> captureSupplierVerificationLocation() async {
    return location;
  }
}

class _FakeVerificationUploadService extends VerificationDocumentUploadService {
  _FakeVerificationUploadService({required this.storagePath}) : super(null);

  final String? storagePath;
  VerificationDocumentType? lastType;
  ImageSource? lastSource;

  @override
  Future<Result<String?>> pickCompressAndUploadDocument({
    required String profileId,
    required VerificationDocumentType type,
    required ImageSource source,
  }) async {
    lastType = type;
    lastSource = source;
    return Success<String?>(storagePath);
  }
}

Widget _buildApp({
  required VerificationBackend backend,
  required String currentUserId,
  VerificationLocationService? locationService,
  VerificationDocumentUploadService? uploadService,
}) {
  return ProviderScope(
    overrides: [
      verificationRepositoryProvider.overrideWith(
        (ref) => VerificationRepository(backend, () => currentUserId),
      ),
      verificationDocumentUploadServiceProvider.overrideWith(
        (ref) => uploadService ?? VerificationDocumentUploadService(null),
      ),
      if (locationService != null)
        verificationLocationServiceProvider.overrideWithValue(locationService),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: VerificationScreen(),
    ),
  );
}

Widget _buildRoutedApp({
  required VerificationBackend backend,
  required String currentUserId,
  VerificationLocationService? locationService,
  VerificationDocumentUploadService? uploadService,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const VerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.fleetPath,
        builder: (context, state) => const Scaffold(body: Text('Fleet opened')),
      ),
      GoRoute(
        path: AppRoutes.accountPath,
        builder: (context, state) => const Scaffold(body: Text('Account opened')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      verificationRepositoryProvider.overrideWith(
        (ref) => VerificationRepository(backend, () => currentUserId),
      ),
      verificationDocumentUploadServiceProvider.overrideWith(
        (ref) => uploadService ?? VerificationDocumentUploadService(null),
      ),
      if (locationService != null)
        verificationLocationServiceProvider.overrideWithValue(locationService),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('renders sanitized verification load failure copy', (tester) async {
    final backend = _FakeVerificationBackend()..profileError = Exception('PostgrestException: leaked detail');

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'trucker-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load verification state'), findsOneWidget);
    expect(
      find.text('We could not load your verification status right now. Retry shortly to refresh the latest verification state.'),
      findsOneWidget,
    );
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
  });

  testWidgets('renders structured rejection feedback for affected verification documents', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'trucker-1',
        'user_role_type': 'trucker',
        'verification_status': 'rejected',
        'verification_rejection_reason': 'Two items need correction',
        'verification_feedback_json': {
          'summary': 'Two items need correction',
          'next_step': 'Replace the PAN image before resubmitting.',
          'documents': {
            'pan': {
              'status': 'rejected',
              'reason': 'PAN image is unreadable.',
            },
          },
        },
        'aadhaar_front_document_path': 'trucker-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'trucker-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'trucker-1/pan/pan.jpg',
        'profile_photo_document_path': 'trucker-1/profile_photo/profile_photo.jpg',
        'aadhaar_number': '123412341234',
        'aadhaar_last4': '1234',
        'pan_number': 'ABCDE1234F',
      }
      ..approvedTruckCount = 1;

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'trucker-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verification needs attention'), findsOneWidget);

    await tester.ensureVisible(find.text('Next step').first);
    await tester.pumpAndSettle();

    expect(find.text('Replace the PAN image before resubmitting.'), findsOneWidget);

    await tester.ensureVisible(find.textContaining('PAN card').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('PAN card'), findsWidgets);
    expect(find.text('Replace document'), findsWidgets);
  });

  testWidgets('renders structured rejection feedback for affected supplier verification documents', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'supplier-1',
        'user_role_type': 'supplier',
        'verification_status': 'rejected',
        'verification_rejection_reason': 'Business licence image unreadable',
        'verification_feedback_json': {
          'summary': 'Replace the business licence image.',
          'next_step': 'Update the rejected business licence and resubmit for review.',
          'documents': {
            'business_licence': {
              'status': 'rejected',
              'reason': 'Business licence image unreadable.',
            },
          },
        },
        'aadhaar_front_document_path': 'supplier-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'supplier-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'supplier-1/pan/pan.jpg',
        'profile_photo_document_path': 'supplier-1/profile_photo/profile_photo.jpg',
        'aadhaar_number': '123412341234',
        'aadhaar_last4': '1234',
        'pan_number': 'ABCDE1234F',
      }
      ..supplierMap = {
        'id': 'supplier-1',
        'company_name': 'North Hub Logistics',
        'business_licence_document_path': 'supplier-1/business_licence/business_licence.jpg',
        'gst_certificate_document_path': 'supplier-1/gst_certificate/gst_certificate.jpg',
        'verification_location_city': 'Mumbai',
        'verification_location_state': 'Maharashtra',
        'verification_location_lat': 19.076,
        'verification_location_lng': 72.8777,
        'business_licence_number': 'BL-7788',
      };

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'supplier-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update the rejected business licence and resubmit for review.'), findsOneWidget);

    await tester.ensureVisible(find.text('Business licence').first);
    await tester.pumpAndSettle();

    expect(find.text('Business licence image unreadable.'), findsWidgets);
  });

  testWidgets('renders packet-level rejection fallback guidance when structured document feedback is unavailable', (
    tester,
  ) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'trucker-1',
        'user_role_type': 'trucker',
        'verification_status': 'rejected',
        'verification_rejection_reason': 'A document requires correction before approval.',
        'verification_feedback_json': {
          'summary': 'A document requires correction before approval.',
        },
        'aadhaar_front_document_path': 'trucker-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'trucker-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'trucker-1/pan/pan.jpg',
        'profile_photo_document_path': 'trucker-1/profile_photo/profile_photo.jpg',
        'aadhaar_number': '123412341234',
        'aadhaar_last4': '1234',
        'pan_number': 'ABCDE1234F',
      }
      ..approvedTruckCount = 1;

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'trucker-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verification needs attention'), findsOneWidget);
    expect(
      find.text('Review the rejection summary, replace any affected documents, and resubmit the packet when ready.'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Latest rejection reason').first);
    await tester.pumpAndSettle();

    expect(find.text('Latest rejection reason'), findsOneWidget);
    expect(
      find.text(
        'A document requires correction before approval.\n\nCurrent review feedback is returned as one packet-level reason when document-specific review markers are not provided.',
      ),
      findsOneWidget,
    );
    expect(find.text('Next step'), findsNothing);
  });

  testWidgets('renders supplier packet-level rejection fallback guidance when structured document feedback is unavailable', (
    tester,
  ) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'supplier-1',
        'user_role_type': 'supplier',
        'verification_status': 'rejected',
        'verification_rejection_reason': 'Business details require correction before approval.',
        'verification_feedback_json': {
          'summary': 'Business details require correction before approval.',
        },
        'aadhaar_front_document_path': 'supplier-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'supplier-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'supplier-1/pan/pan.jpg',
        'profile_photo_document_path': 'supplier-1/profile_photo/profile_photo.jpg',
        'aadhaar_number': '123412341234',
        'aadhaar_last4': '1234',
        'pan_number': 'ABCDE1234F',
      }
      ..supplierMap = {
        'id': 'supplier-1',
        'company_name': 'North Hub Logistics',
        'business_licence_document_path': 'supplier-1/business_licence/business_licence.jpg',
        'gst_certificate_document_path': null,
        'verification_location_city': 'Mumbai',
        'verification_location_state': 'Maharashtra',
        'verification_location_lat': 19.076,
        'verification_location_lng': 72.8777,
        'business_licence_number': 'BL-7788',
      };

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'supplier-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verification needs attention'), findsOneWidget);
    expect(
      find.text('Review the rejection summary, replace any affected documents, and resubmit the packet when ready.'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Latest rejection reason').first);
    await tester.pumpAndSettle();

    expect(find.text('Latest rejection reason'), findsOneWidget);
    expect(
      find.text(
        'Business details require correction before approval.\n\nCurrent review feedback is returned as one packet-level reason when document-specific review markers are not provided.',
      ),
      findsOneWidget,
    );
    expect(find.text('Next step'), findsNothing);
  });

  testWidgets('resubmits rejected verification from the screen and shows success feedback', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'trucker-1',
        'user_role_type': 'trucker',
        'verification_status': 'rejected',
        'verification_rejection_reason': 'Two items need correction',
        'verification_feedback_json': {
          'summary': 'Two items need correction',
          'next_step': 'Replace the PAN image before resubmitting.',
          'documents': {
            'pan': {
              'status': 'rejected',
              'reason': 'PAN image is unreadable.',
            },
          },
        },
        'aadhaar_front_document_path': 'trucker-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'trucker-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'trucker-1/pan/pan.jpg',
        'profile_photo_document_path': 'trucker-1/profile_photo/profile_photo.jpg',
        'aadhaar_number': '123412341234',
        'aadhaar_last4': '1234',
        'pan_number': 'ABCDE1234F',
      }
      ..approvedTruckCount = 1;

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'trucker-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resubmit for review'), findsOneWidget);

    await tester.ensureVisible(find.text('Resubmit for review').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Resubmit for review'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(backend.resubmitCalls, 1);
    expect(backend.submitCalls, 0);
    expect(find.text('Verification resubmitted for review'), findsOneWidget);
  });

  testWidgets('shows editable packet fields for rejected trucker verification before resubmission', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'trucker-1',
        'user_role_type': 'trucker',
        'verification_status': 'rejected',
        'verification_rejection_reason': 'PAN details need correction',
        'verification_feedback_json': {
          'summary': 'PAN details need correction',
          'next_step': 'Correct the PAN details and resubmit.',
        },
        'aadhaar_number': '123412341234',
        'aadhaar_last4': '1234',
        'pan_number': 'ABCDE1234F',
        'aadhaar_front_document_path': 'trucker-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'trucker-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'trucker-1/pan/pan.jpg',
        'profile_photo_document_path': 'trucker-1/profile_photo/profile_photo.jpg',
      }
      ..approvedTruckCount = 1
      ..verificationReadyTruckCount = 1;

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'trucker-1',
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save details').first);
    await tester.pumpAndSettle();

    expect(find.text('Aadhaar number'), findsWidgets);
    expect(find.text('PAN number'), findsWidgets);
    expect(find.text('Save details'), findsOneWidget);
    expect(find.text('Resubmit for review'), findsOneWidget);
    expect(
      find.text('Enter your identity details and keep at least one truck ready for verification.'),
      findsOneWidget,
    );
  });

  testWidgets('shows supplier company field inside editable supplier verification packet details', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'supplier-1',
        'user_role_type': 'supplier',
        'verification_status': 'rejected',
        'verification_rejection_reason': 'Company details need correction',
        'verification_feedback_json': {
          'summary': 'Update supplier packet details.',
          'next_step': 'Correct the supplier packet details and resubmit.',
        },
        'aadhaar_number': '123412341234',
        'aadhaar_last4': '1234',
        'pan_number': 'ABCDE1234F',
        'aadhaar_front_document_path': 'supplier-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'supplier-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'supplier-1/pan/pan.jpg',
        'profile_photo_document_path': 'supplier-1/profile_photo/profile_photo.jpg',
      }
      ..supplierMap = {
        'id': 'supplier-1',
        'company_name': 'North Hub Logistics',
        'business_licence_number': 'BL-7788',
        'business_licence_document_path': 'supplier-1/business_licence/business_licence.jpg',
        'gst_certificate_document_path': null,
        'verification_location_city': 'Mumbai',
        'verification_location_state': 'Maharashtra',
        'verification_location_lat': 19.076,
        'verification_location_lng': 72.8777,
      };

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'supplier-1',
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save details').first);
    await tester.pumpAndSettle();

    expect(find.text('Company name'), findsWidgets);
    expect(find.text('Business licence number'), findsWidgets);
    expect(
      find.text('Enter your business and identity details, then upload the required documents.'),
      findsOneWidget,
    );
  });

  testWidgets('resubmits rejected supplier verification from the screen and shows success feedback', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'supplier-1',
        'user_role_type': 'supplier',
        'verification_status': 'rejected',
        'verification_rejection_reason': 'Business licence image unreadable',
        'verification_feedback_json': {
          'summary': 'Replace the business licence image.',
          'next_step': 'Update the rejected business licence and resubmit for review.',
          'documents': {
            'business_licence': {
              'status': 'rejected',
              'reason': 'Business licence image unreadable.',
            },
          },
        },
        'aadhaar_front_document_path': 'supplier-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'supplier-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'supplier-1/pan/pan.jpg',
        'profile_photo_document_path': 'supplier-1/profile_photo/profile_photo.jpg',
        'aadhaar_number': '123412341234',
        'aadhaar_last4': '1234',
        'pan_number': 'ABCDE1234F',
      }
      ..supplierMap = {
        'id': 'supplier-1',
        'company_name': 'North Hub Logistics',
        'business_licence_document_path': 'supplier-1/business_licence/business_licence.jpg',
        'gst_certificate_document_path': 'supplier-1/gst_certificate/gst_certificate.jpg',
        'verification_location_city': 'Mumbai',
        'verification_location_state': 'Maharashtra',
        'verification_location_lat': 19.076,
        'verification_location_lng': 72.8777,
        'business_licence_number': 'BL-7788',
      };

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'supplier-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resubmit for review'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Resubmit for review'),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Resubmit for review'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(backend.resubmitCalls, 1);
    expect(backend.submitCalls, 0);
    expect(find.text('Verification resubmitted for review'), findsOneWidget);
  });

  testWidgets('renders trucker verification checklist and truck readiness warning', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'trucker-1',
        'user_role_type': 'trucker',
        'verification_status': 'unverified',
        'verification_rejection_reason': null,
        'aadhaar_front_document_path': 'trucker-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'trucker-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'trucker-1/pan/pan.jpg',
        'profile_photo_document_path': 'trucker-1/profile_photo/profile_photo.jpg',
        'aadhaar_number': '123412341234',
        'aadhaar_last4': '1234',
        'pan_number': 'ABCDE1234F',
      }
      ..approvedTruckCount = 0
      ..verificationReadyTruckCount = 0;

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'trucker-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trucker Verification'), findsOneWidget);
    expect(find.text('Submit for review'), findsOneWidget);

    await tester.ensureVisible(find.text('Aadhaar front uploaded').first);
    await tester.pumpAndSettle();

    expect(find.text('Aadhaar front uploaded'), findsOneWidget);
    expect(find.text('Aadhaar back uploaded'), findsOneWidget);
    expect(find.text('PAN card uploaded'), findsOneWidget);

    await tester.ensureVisible(find.text('Open fleet').first);
    await tester.pumpAndSettle();

    expect(find.text('Open fleet'), findsOneWidget);
  });

  testWidgets('renders blocked-submit guidance when trucker verification is missing a ready truck packet', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'trucker-1',
        'user_role_type': 'trucker',
        'verification_status': 'unverified',
        'verification_rejection_reason': null,
        'aadhaar_front_document_path': 'trucker-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'trucker-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'trucker-1/pan/pan.jpg',
        'profile_photo_document_path': 'trucker-1/profile_photo/profile_photo.jpg',
        'aadhaar_number': '123412341234',
        'aadhaar_last4': '1234',
        'pan_number': 'ABCDE1234F',
      }
      ..approvedTruckCount = 0
      ..verificationReadyTruckCount = 0;

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'trucker-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add at least one truck before submitting verification.'), findsOneWidget);
  });

  testWidgets('renders blocked-submit guidance when supplier verification is missing location capture', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'supplier-1',
        'user_role_type': 'supplier',
        'verification_status': 'unverified',
        'verification_rejection_reason': null,
        'aadhaar_front_document_path': 'supplier-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'supplier-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'supplier-1/pan/pan.jpg',
        'profile_photo_document_path': 'supplier-1/profile_photo/profile_photo.jpg',
        'aadhaar_number': '123412341234',
        'aadhaar_last4': '1234',
        'pan_number': 'ABCDE1234F',
      }
      ..supplierMap = {
        'id': 'supplier-1',
        'company_name': 'North Hub Logistics',
        'business_licence_document_path': 'supplier-1/business_licence/business_licence.jpg',
        'gst_certificate_document_path': null,
        'verification_location_city': null,
        'verification_location_state': null,
        'verification_location_lat': null,
        'verification_location_lng': null,
        'business_licence_number': 'BL-7788',
      };

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'supplier-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add your verification location first.'), findsOneWidget);
  });

  testWidgets('renders blocked-submit guidance when trucker verification is missing a required document', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'trucker-1',
        'user_role_type': 'trucker',
        'verification_status': 'unverified',
        'verification_rejection_reason': null,
        'aadhaar_front_document_path': null,
        'aadhaar_back_document_path': 'trucker-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'trucker-1/pan/pan.jpg',
        'profile_photo_document_path': 'trucker-1/profile_photo/profile_photo.jpg',
        'aadhaar_number': '123412341234',
        'aadhaar_last4': '1234',
        'pan_number': 'ABCDE1234F',
      }
      ..approvedTruckCount = 1;

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'trucker-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Upload Aadhaar front to continue.'), findsOneWidget);
  });

  testWidgets('renders blocked-submit guidance when supplier verification is missing business licence', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'supplier-1',
        'user_role_type': 'supplier',
        'verification_status': 'unverified',
        'verification_rejection_reason': null,
        'aadhaar_front_document_path': 'supplier-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'supplier-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'supplier-1/pan/pan.jpg',
        'profile_photo_document_path': 'supplier-1/profile_photo/profile_photo.jpg',
        'aadhaar_number': '123412341234',
        'aadhaar_last4': '1234',
        'pan_number': 'ABCDE1234F',
      }
      ..supplierMap = {
        'id': 'supplier-1',
        'company_name': 'North Hub Logistics',
        'business_licence_document_path': null,
        'gst_certificate_document_path': null,
        'verification_location_city': 'Mumbai',
        'verification_location_state': 'Maharashtra',
        'verification_location_lat': 19.076,
        'verification_location_lng': 72.8777,
        'business_licence_number': null,
      };

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'supplier-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enter your business licence details first.'), findsOneWidget);
  });

  testWidgets('renders blocked-submit guidance when supplier verification is missing company name', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'supplier-1',
        'user_role_type': 'supplier',
        'verification_status': 'unverified',
        'verification_rejection_reason': null,
        'aadhaar_front_document_path': 'supplier-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'supplier-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'supplier-1/pan/pan.jpg',
        'profile_photo_document_path': 'supplier-1/profile_photo/profile_photo.jpg',
        'aadhaar_number': '123412341234',
        'aadhaar_last4': '1234',
        'pan_number': 'ABCDE1234F',
      }
      ..supplierMap = {
        'id': 'supplier-1',
        'company_name': null,
        'business_licence_document_path': 'supplier-1/business_licence/business_licence.jpg',
        'gst_certificate_document_path': null,
        'verification_location_city': 'Mumbai',
        'verification_location_state': 'Maharashtra',
        'verification_location_lat': 19.076,
        'verification_location_lng': 72.8777,
        'business_licence_number': 'BL-7788',
      };

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'supplier-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enter your company name first.'), findsOneWidget);
  });

  testWidgets('truck readiness warning opens fleet from verification screen', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'trucker-1',
        'user_role_type': 'trucker',
        'verification_status': 'unverified',
        'verification_rejection_reason': null,
        'aadhaar_front_document_path': 'trucker-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'trucker-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'trucker-1/pan/pan.jpg',
        'profile_photo_document_path': 'trucker-1/profile_photo/profile_photo.jpg',
        'aadhaar_number': '123412341234',
        'aadhaar_last4': '1234',
        'pan_number': 'ABCDE1234F',
      }
      ..approvedTruckCount = 0
      ..verificationReadyTruckCount = 0;

    await tester.pumpWidget(
      _buildRoutedApp(
        backend: backend,
        currentUserId: 'trucker-1',
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Open fleet').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open fleet'));
    await tester.pumpAndSettle();

    expect(find.text('Fleet opened'), findsOneWidget);
  });

  testWidgets('submits trucker verification for review from the screen and shows success feedback', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'trucker-1',
        'user_role_type': 'trucker',
        'verification_status': 'unverified',
        'verification_rejection_reason': null,
        'aadhaar_front_document_path': 'trucker-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'trucker-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'trucker-1/pan/pan.jpg',
        'profile_photo_document_path': 'trucker-1/profile_photo/profile_photo.jpg',
        'aadhaar_number': '123412341234',
        'aadhaar_last4': '1234',
        'pan_number': 'ABCDE1234F',
      }
      ..approvedTruckCount = 1;

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'trucker-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Submit for review'), findsOneWidget);

    await tester.ensureVisible(find.text('Submit for review').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit for review'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(backend.submitCalls, 1);
    expect(backend.resubmitCalls, 0);
    expect(find.text('Verification submitted for review'), findsOneWidget);
  });

  testWidgets('submits supplier verification for review from the screen and shows success feedback', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'supplier-1',
        'user_role_type': 'supplier',
        'verification_status': 'unverified',
        'verification_rejection_reason': null,
        'aadhaar_front_document_path': 'supplier-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'supplier-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'supplier-1/pan/pan.jpg',
        'profile_photo_document_path': 'supplier-1/profile_photo/profile_photo.jpg',
        'aadhaar_number': '123412341234',
        'aadhaar_last4': '1234',
        'pan_number': 'ABCDE1234F',
      }
      ..supplierMap = {
        'id': 'supplier-1',
        'company_name': 'North Hub Logistics',
        'business_licence_document_path': 'supplier-1/business_licence/business_licence.jpg',
        'gst_certificate_document_path': null,
        'verification_location_city': 'Mumbai',
        'verification_location_state': 'Maharashtra',
        'verification_location_lat': 19.076,
        'verification_location_lng': 72.8777,
        'business_licence_number': 'BL-7788',
      };

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'supplier-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Submit for review'), findsOneWidget);

    await tester.ensureVisible(find.text('Submit for review').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit for review'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(backend.submitCalls, 1);
    expect(backend.resubmitCalls, 0);
    expect(find.text('Verification submitted for review'), findsOneWidget);
  });

  testWidgets('renders verified trucker verification state without a submit action', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'trucker-1',
        'user_role_type': 'trucker',
        'verification_status': 'verified',
        'verification_rejection_reason': null,
        'aadhaar_front_document_path': 'trucker-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'trucker-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'trucker-1/pan/pan.jpg',
        'profile_photo_document_path': 'trucker-1/profile_photo/profile_photo.jpg',
        'aadhaar_number': '123412341234',
        'aadhaar_last4': '1234',
        'pan_number': 'ABCDE1234F',
      }
      ..approvedTruckCount = 1;

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'trucker-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trucker Verification'), findsOneWidget);
    expect(find.text('Verification complete'), findsOneWidget);
    expect(
      find.text('Your account is already verified. You can still review the uploaded document checklist below.'),
      findsOneWidget,
    );
    expect(find.text('Submit for review'), findsNothing);
    expect(find.text('Resubmit for review'), findsNothing);
  });

  testWidgets('renders verified supplier verification state without a submit action', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'supplier-1',
        'user_role_type': 'supplier',
        'verification_status': 'verified',
        'verification_rejection_reason': null,
        'aadhaar_front_document_path': 'supplier-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'supplier-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'supplier-1/pan/pan.jpg',
        'profile_photo_document_path': 'supplier-1/profile_photo/profile_photo.jpg',
        'aadhaar_number': '123412341234',
        'aadhaar_last4': '1234',
        'pan_number': 'ABCDE1234F',
      }
      ..supplierMap = {
        'id': 'supplier-1',
        'company_name': 'North Hub Logistics',
        'business_licence_document_path': 'supplier-1/business_licence/business_licence.jpg',
        'gst_certificate_document_path': null,
        'verification_location_city': 'Mumbai',
        'verification_location_state': 'Maharashtra',
        'verification_location_lat': 19.076,
        'verification_location_lng': 72.8777,
        'business_licence_number': 'BL-7788',
      };

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'supplier-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Supplier Verification'), findsOneWidget);
    expect(find.text('Verification complete'), findsOneWidget);
    expect(
      find.text('Your account is already verified. You can still review the uploaded document checklist below.'),
      findsOneWidget,
    );
    expect(find.text('Submit for review'), findsNothing);
    expect(find.text('Resubmit for review'), findsNothing);
  });

  testWidgets('renders unknown fallback for unsupported verification status', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'supplier-1',
        'user_role_type': 'supplier',
        'verification_status': 'mystery_flag',
        'verification_rejection_reason': null,
        'aadhaar_front_document_path': 'supplier-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'supplier-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'supplier-1/pan/pan.jpg',
        'profile_photo_document_path': 'supplier-1/profile_photo/profile_photo.jpg',
        'aadhaar_number': '123412341234',
        'aadhaar_last4': '1234',
        'pan_number': 'ABCDE1234F',
      }
      ..supplierMap = {
        'id': 'supplier-1',
        'company_name': 'North Hub Logistics',
        'business_licence_document_path': 'supplier-1/business_licence/business_licence.jpg',
        'gst_certificate_document_path': null,
        'verification_location_city': 'Mumbai',
        'verification_location_state': 'Maharashtra',
        'verification_location_lat': 19.076,
        'verification_location_lng': 72.8777,
        'business_licence_number': 'BL-7788',
      };

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'supplier-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Supplier Verification'), findsOneWidget);
    expect(find.text('Verification not submitted yet'), findsOneWidget);
    expect(
      find.text('Upload Aadhaar, PAN, profile photo, and business licence before submitting supplier verification.'),
      findsOneWidget,
    );
    expect(find.text('Mystery Flag'), findsNothing);
  });

  testWidgets('pending supplier verification keeps the user on the verification screen', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'supplier-1',
        'user_role_type': 'supplier',
        'verification_status': 'pending',
        'verification_rejection_reason': null,
        'aadhaar_front_document_path': 'supplier-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'supplier-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'supplier-1/pan/pan.jpg',
        'profile_photo_document_path': 'supplier-1/profile_photo/profile_photo.jpg',
        'aadhaar_number': '123412341234',
        'aadhaar_last4': '1234',
        'pan_number': 'ABCDE1234F',
      }
      ..supplierMap = {
        'id': 'supplier-1',
        'company_name': 'North Hub Logistics',
        'business_licence_document_path': 'supplier-1/business_licence/business_licence.jpg',
        'gst_certificate_document_path': null,
        'verification_location_city': 'Mumbai',
        'verification_location_state': 'Maharashtra',
        'verification_location_lat': 19.076,
        'verification_location_lng': 72.8777,
        'business_licence_number': 'BL-7788',
      };

    await tester.pumpWidget(
      _buildRoutedApp(
        backend: backend,
        currentUserId: 'supplier-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Supplier Verification'), findsOneWidget);
    expect(find.text('Back to account'), findsNothing);
    expect(find.text('Account opened'), findsNothing);
  });

  testWidgets('verified trucker verification stays on the verification screen summary', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'trucker-1',
        'user_role_type': 'trucker',
        'verification_status': 'verified',
        'verification_rejection_reason': null,
        'aadhaar_front_document_path': 'trucker-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'trucker-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'trucker-1/pan/pan.jpg',
        'profile_photo_document_path': 'trucker-1/profile_photo/profile_photo.jpg',
        'aadhaar_number': '123412341234',
        'aadhaar_last4': '1234',
        'pan_number': 'ABCDE1234F',
      }
      ..approvedTruckCount = 1;

    await tester.pumpWidget(
      _buildRoutedApp(
        backend: backend,
        currentUserId: 'trucker-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trucker Verification'), findsOneWidget);
    expect(find.text('Back to account'), findsNothing);
    expect(find.text('Account opened'), findsNothing);
  });

  testWidgets('captures supplier location from verification screen and shows success feedback', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'supplier-1',
        'user_role_type': 'supplier',
        'verification_status': 'unverified',
        'verification_rejection_reason': null,
        'aadhaar_front_document_path': 'supplier-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'supplier-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'supplier-1/pan/pan.jpg',
        'profile_photo_document_path': 'supplier-1/profile_photo/profile_photo.jpg',
      }
      ..supplierMap = {
        'id': 'supplier-1',
        'company_name': 'North Hub Logistics',
        'business_licence_document_path': 'supplier-1/business_licence/business_licence.jpg',
        'gst_certificate_document_path': null,
        'verification_location_city': null,
        'verification_location_state': null,
        'verification_location_lat': null,
        'verification_location_lng': null,
      };

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'supplier-1',
        locationService: _FakeVerificationLocationService(
          location: const VerificationLocation(
            city: 'Mumbai',
            state: 'Maharashtra',
            latitude: 19.076,
            longitude: 72.8777,
            source: 'test',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Capture location').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Capture location'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Verification location captured'), findsOneWidget);
    expect(find.text('Mumbai, Maharashtra'), findsOneWidget);
  });

  testWidgets('shows action-failure warning when supplier location capture fails', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'supplier-1',
        'user_role_type': 'supplier',
        'verification_status': 'unverified',
        'verification_rejection_reason': null,
        'aadhaar_front_document_path': 'supplier-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'supplier-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'supplier-1/pan/pan.jpg',
        'profile_photo_document_path': 'supplier-1/profile_photo/profile_photo.jpg',
      }
      ..supplierMap = {
        'id': 'supplier-1',
        'company_name': 'North Hub Logistics',
        'business_licence_document_path': 'supplier-1/business_licence/business_licence.jpg',
        'gst_certificate_document_path': null,
        'verification_location_city': null,
        'verification_location_state': null,
        'verification_location_lat': null,
        'verification_location_lng': null,
      };

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'supplier-1',
        locationService: _FakeVerificationLocationService(location: null),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Capture location').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Capture location'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Verification action needs attention'), findsOneWidget);
    expect(
      find.text('The latest verification action could not be completed right now. Review the current checklist and retry shortly.'),
      findsOneWidget,
    );
  });

  testWidgets('uploads a verification document from the screen via gallery selection', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'trucker-1',
        'user_role_type': 'trucker',
        'verification_status': 'unverified',
        'verification_rejection_reason': null,
        'aadhaar_front_document_path': 'trucker-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'trucker-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': null,
        'profile_photo_document_path': null,
      }
      ..approvedTruckCount = 1;
    final uploadService = _FakeVerificationUploadService(
      storagePath: 'trucker-1/pan/pan.jpg',
    );

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'trucker-1',
        uploadService: uploadService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.textContaining('PAN card').first);
    await tester.pumpAndSettle();

    await tester.tap(
      find.text('Upload document'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose from gallery'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(uploadService.lastType, VerificationDocumentType.pan);
    expect(uploadService.lastSource, ImageSource.gallery);
    expect(backend.profileMap?['pan_document_path'], 'trucker-1/pan/pan.jpg');
  });

  testWidgets('uploads supplier business licence from the verification screen via gallery selection', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'supplier-1',
        'user_role_type': 'supplier',
        'verification_status': 'unverified',
        'verification_rejection_reason': null,
        'aadhaar_front_document_path': 'supplier-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'supplier-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'supplier-1/pan/pan.jpg',
        'profile_photo_document_path': 'supplier-1/profile_photo/profile_photo.jpg',
      }
      ..supplierMap = {
        'id': 'supplier-1',
        'company_name': 'North Hub Logistics',
        'business_licence_document_path': null,
        'gst_certificate_document_path': null,
        'verification_location_city': 'Mumbai',
        'verification_location_state': 'Maharashtra',
        'verification_location_lat': 19.076,
        'verification_location_lng': 72.8777,
      };
    final uploadService = _FakeVerificationUploadService(
      storagePath: 'supplier-1/business_licence/business_licence.jpg',
    );

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'supplier-1',
        uploadService: uploadService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Business licence').first);
    await tester.pumpAndSettle();

    final businessLicenceCard = find.ancestor(
      of: find.text('Business licence'),
      matching: find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == 'StandardListCard',
      ),
    );

    await tester.tap(
      find.descendant(
        of: businessLicenceCard,
        matching: find.text('Upload document'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose from gallery'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(uploadService.lastType, VerificationDocumentType.businessLicence);
    expect(uploadService.lastSource, ImageSource.gallery);
    expect(backend.supplierMap?['business_licence_document_path'], 'supplier-1/business_licence/business_licence.jpg');
  });

  testWidgets('uploads optional supplier gst certificate from the verification screen via camera selection', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'supplier-1',
        'user_role_type': 'supplier',
        'verification_status': 'unverified',
        'verification_rejection_reason': null,
        'aadhaar_front_document_path': 'supplier-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'supplier-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'supplier-1/pan/pan.jpg',
        'profile_photo_document_path': 'supplier-1/profile_photo/profile_photo.jpg',
      }
      ..supplierMap = {
        'id': 'supplier-1',
        'company_name': 'North Hub Logistics',
        'business_licence_document_path': 'supplier-1/business_licence/business_licence.jpg',
        'gst_certificate_document_path': null,
        'verification_location_city': 'Mumbai',
        'verification_location_state': 'Maharashtra',
        'verification_location_lat': 19.076,
        'verification_location_lng': 72.8777,
      };
    final uploadService = _FakeVerificationUploadService(
      storagePath: 'supplier-1/gst_certificate/gst_certificate.jpg',
    );

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'supplier-1',
        uploadService: uploadService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('GST certificate').first);
    await tester.pumpAndSettle();

    final gstCard = find.ancestor(
      of: find.text('GST certificate'),
      matching: find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == 'StandardListCard',
      ),
    );

    await tester.tap(
      find.descendant(
        of: gstCard,
        matching: find.text('Upload document'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Take photo'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(uploadService.lastType, VerificationDocumentType.gstCertificate);
    expect(uploadService.lastSource, ImageSource.camera);
    expect(backend.supplierMap?['gst_certificate_document_path'], 'supplier-1/gst_certificate/gst_certificate.jpg');
  });

  testWidgets('replaces a rejected supplier business licence from the verification screen', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'supplier-1',
        'user_role_type': 'supplier',
        'verification_status': 'rejected',
        'verification_rejection_reason': 'Business licence image unreadable',
        'verification_feedback_json': {
          'summary': 'Replace the business licence image.',
          'documents': {
            'business_licence': {
              'status': 'rejected',
              'reason': 'Business licence image unreadable.',
            },
          },
        },
        'aadhaar_front_document_path': 'supplier-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'supplier-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'supplier-1/pan/pan.jpg',
        'profile_photo_document_path': 'supplier-1/profile_photo/profile_photo.jpg',
      }
      ..supplierMap = {
        'id': 'supplier-1',
        'company_name': 'North Hub Logistics',
        'business_licence_document_path': 'supplier-1/business_licence/old-business-licence.jpg',
        'gst_certificate_document_path': null,
        'verification_location_city': 'Mumbai',
        'verification_location_state': 'Maharashtra',
        'verification_location_lat': 19.076,
        'verification_location_lng': 72.8777,
      };
    final uploadService = _FakeVerificationUploadService(
      storagePath: 'supplier-1/business_licence/new-business-licence.jpg',
    );

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'supplier-1',
        uploadService: uploadService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Business licence').first);
    await tester.pumpAndSettle();

    final businessLicenceCard = find.ancestor(
      of: find.text('Business licence'),
      matching: find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == 'StandardListCard',
      ),
    );

    await tester.tap(
      find.descendant(
        of: businessLicenceCard,
        matching: find.text('Replace document'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Take photo'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(uploadService.lastType, VerificationDocumentType.businessLicence);
    expect(uploadService.lastSource, ImageSource.camera);
    expect(
      backend.supplierMap?['business_licence_document_path'],
      'supplier-1/business_licence/new-business-licence.jpg',
    );
  });

  testWidgets('replaces a rejected supplier gst certificate from the verification screen', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'supplier-1',
        'user_role_type': 'supplier',
        'verification_status': 'rejected',
        'verification_rejection_reason': 'GST certificate image unreadable',
        'verification_feedback_json': {
          'summary': 'Replace the GST certificate image.',
          'documents': {
            'gst_certificate': {
              'status': 'rejected',
              'reason': 'GST certificate image unreadable.',
            },
          },
        },
        'aadhaar_front_document_path': 'supplier-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'supplier-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'supplier-1/pan/pan.jpg',
        'profile_photo_document_path': 'supplier-1/profile_photo/profile_photo.jpg',
      }
      ..supplierMap = {
        'id': 'supplier-1',
        'company_name': 'North Hub Logistics',
        'business_licence_document_path': 'supplier-1/business_licence/business_licence.jpg',
        'gst_certificate_document_path': 'supplier-1/gst_certificate/old-gst-certificate.jpg',
        'verification_location_city': 'Mumbai',
        'verification_location_state': 'Maharashtra',
        'verification_location_lat': 19.076,
        'verification_location_lng': 72.8777,
      };
    final uploadService = _FakeVerificationUploadService(
      storagePath: 'supplier-1/gst_certificate/new-gst-certificate.jpg',
    );

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'supplier-1',
        uploadService: uploadService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('GST certificate').first);
    await tester.pumpAndSettle();

    final gstCard = find.ancestor(
      of: find.text('GST certificate'),
      matching: find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == 'StandardListCard',
      ),
    );

    await tester.tap(
      find.descendant(
        of: gstCard,
        matching: find.text('Replace document'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose from gallery'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(uploadService.lastType, VerificationDocumentType.gstCertificate);
    expect(uploadService.lastSource, ImageSource.gallery);
    expect(
      backend.supplierMap?['gst_certificate_document_path'],
      'supplier-1/gst_certificate/new-gst-certificate.jpg',
    );
  });

  testWidgets('replaces a rejected verification document from the screen via camera selection', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'trucker-1',
        'user_role_type': 'trucker',
        'verification_status': 'rejected',
        'verification_rejection_reason': 'PAN image unreadable',
        'verification_feedback_json': {
          'summary': 'Replace the PAN image.',
          'documents': {
            'pan': {
              'status': 'rejected',
              'reason': 'PAN image unreadable.',
            },
          },
        },
        'aadhaar_front_document_path': 'trucker-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'trucker-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'trucker-1/pan/old-pan.jpg',
        'profile_photo_document_path': 'trucker-1/profile_photo/profile_photo.jpg',
      }
      ..approvedTruckCount = 1;
    final uploadService = _FakeVerificationUploadService(
      storagePath: 'trucker-1/pan/new-pan.jpg',
    );

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'trucker-1',
        uploadService: uploadService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.textContaining('PAN card').first);
    await tester.pumpAndSettle();

    final panInlineRow = find.ancestor(
      of: find.text('PAN card uploaded'),
      matching: find.byType(Row),
    );

    await tester.tap(
      find.descendant(
        of: panInlineRow,
        matching: find.text('Replace document'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Take photo'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(uploadService.lastType, VerificationDocumentType.pan);
    expect(uploadService.lastSource, ImageSource.camera);
    expect(backend.profileMap?['pan_document_path'], 'trucker-1/pan/new-pan.jpg');
  });

  testWidgets('renders supplier verification checklist including optional gst', (tester) async {
    final backend = _FakeVerificationBackend()
      ..profileMap = {
        'id': 'supplier-1',
        'user_role_type': 'supplier',
        'verification_status': 'pending',
        'verification_rejection_reason': null,
        'aadhaar_front_document_path': 'supplier-1/aadhaar_front/aadhaar_front.jpg',
        'aadhaar_back_document_path': 'supplier-1/aadhaar_back/aadhaar_back.jpg',
        'pan_document_path': 'supplier-1/pan/pan.jpg',
        'profile_photo_document_path': 'supplier-1/profile_photo/profile_photo.jpg',
      }
      ..supplierMap = {
        'id': 'supplier-1',
        'company_name': 'North Hub Logistics',
        'business_licence_document_path': 'supplier-1/business_licence/business_licence.jpg',
        'gst_certificate_document_path': null,
        'verification_location_city': 'Mumbai',
        'verification_location_state': 'Maharashtra',
        'verification_location_lat': 19.076,
        'verification_location_lng': 72.8777,
      };

    await tester.pumpWidget(
      _buildApp(
        backend: backend,
        currentUserId: 'supplier-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Supplier Verification'), findsOneWidget);
    expect(find.text('Verification pending'), findsOneWidget);
    expect(find.text('Your verification packet is already under review. You can keep browsing while review is pending.'), findsOneWidget);
    expect(find.text('What happens next'), findsOneWidget);
    expect(find.text('Packet submitted'), findsOneWidget);
    expect(find.text('Review in progress'), findsOneWidget);
    expect(find.text('You will be notified'), findsOneWidget);

    await tester.ensureVisible(find.text('Location captured').first);
    await tester.pumpAndSettle();

    expect(find.text('Location captured'), findsOneWidget);
    expect(find.text('Mumbai, Maharashtra'), findsOneWidget);

    await tester.ensureVisible(find.text('Aadhaar back').first);
    await tester.pumpAndSettle();

    expect(find.text('Aadhaar back'), findsOneWidget);
    expect(find.text('Business licence'), findsOneWidget);
    expect(find.text('GST certificate'), findsOneWidget);
    expect(find.text('North Hub Logistics'), findsWidgets);
  });
}
