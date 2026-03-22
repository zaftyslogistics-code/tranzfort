import 'package:admin/src/core/repositories/admin_verification_repository.dart';
import 'package:admin/src/features/verification/presentation/admin_verification_detail_screen.dart';
import 'package:admin/src/features/verification/providers/admin_verification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminVerificationActionController extends AdminVerificationActionController {
  bool called = false;
  VerificationReviewDecision? lastDecision;
  String? lastReason;
  VerificationReviewFeedbackPayload? lastFeedback;

  @override
  Future<bool> submitReviewDecision({
    required AdminVerificationDetail detail,
    required VerificationReviewDecision decision,
    String? reason,
    VerificationReviewFeedbackPayload? feedback,
  }) async {
    called = true;
    lastDecision = decision;
    lastReason = reason;
    lastFeedback = feedback;
    return true;
  }
}

void main() {
  testWidgets('verification detail screen renders sections and document action', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminVerificationDetailProvider('case-1').overrideWith((ref) async {
            return AdminVerificationDetail(
              caseId: 'case-1',
              subjectId: 'user-1',
              subjectType: 'supplier_profile',
              subjectTypeLabel: 'Supplier',
              displayName: 'S1 Logistics',
              subjectLabel: 'Supplier profile verification case',
              profileLinkId: 'user-1',
              profileLinkLabel: 'Open subject profile',
              caseStatus: 'waiting_for_resubmission',
              submittedAt: null,
              lastReviewedAt: null,
              decisionSummary: 'Documents need correction',
              reviewFeedbackSummary: 'Business licence mismatch',
              reviewFeedbackNextStep: 'Upload corrected licence copy',
              reviewFeedbackDocumentReasons: const {
                'pan': 'PAN image unreadable',
              },
              isClaimed: true,
              assignedAdminUserId: 'admin-1',
              assignedAdminLabel: 'Ops One (ops_admin)',
              slaLabel: '12h left',
              subjectMetadata: const {
                'Name': 'Supplier One',
                'Mobile': '9999999999',
                'Email': 'supplier@example.com',
                'Verification status': 'pending',
                'Aadhaar number': '123412341234',
                'Aadhaar last 4': '1234',
                'PAN number': 'ABCDE1234F',
                'Registered': '2026-03-01 09:30',
                'Verification coordinates': '19.076, 72.8777',
              },
              documents: const [
                VerificationDocument(
                  label: 'PAN Card',
                  backendKey: 'pan',
                  path: 'user-1/pan.jpg',
                  signedUrl: 'https://signed/pan',
                  feedbackReason: 'PAN image unreadable',
                ),
              ],
              events: [
                VerificationCaseEvent(
                  id: 'event-1',
                  eventType: 'case_submitted',
                  summary: 'Verification submitted',
                  internalNote: 'Initial admin review requested clearer PAN evidence',
                  createdAt: DateTime(2026, 3, 12, 18, 40),
                ),
              ],
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AdminVerificationDetailScreen(caseId: 'case-1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('S1 Logistics'), findsOneWidget);
    expect(find.text('Case summary'), findsOneWidget);
    expect(find.text('case-1'), findsOneWidget);
    expect(find.text('user-1'), findsWidgets);
    expect(find.text('Supplier'), findsWidgets);
    expect(find.text('Ops One (ops_admin) • admin-1'), findsOneWidget);
    expect(find.text('Subject context'), findsOneWidget);
    expect(find.text('Business licence mismatch'), findsOneWidget);
    expect(find.text('pending'), findsOneWidget);
    expect(find.text('123412341234'), findsOneWidget);
    expect(find.text('1234'), findsOneWidget);
    expect(find.text('ABCDE1234F'), findsOneWidget);
    expect(find.text('2026-03-01 09:30'), findsOneWidget);
    expect(find.text('19.076, 72.8777'), findsOneWidget);
    expect(find.text('Linked profile id'), findsOneWidget);
    expect(find.byKey(const ValueKey('verification-open-subject-profile-button')), findsOneWidget);
    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Verification documents'),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    expect(find.text('Verification documents'), findsOneWidget);
    expect(find.text('View document'), findsOneWidget);
    expect(find.text('Feedback PAN image unreadable'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Review timeline'),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    expect(find.text('Review timeline'), findsOneWidget);
    expect(find.text('Verification submitted'), findsOneWidget);
    expect(find.text('Event event-1'), findsOneWidget);
    expect(find.text('Created 2026-03-12 18:40'), findsOneWidget);
    expect(find.text('Internal note Initial admin review requested clearer PAN evidence'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Review actions'),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    expect(find.text('Review actions'), findsOneWidget);
    expect(find.byKey(const ValueKey('verification-approve-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('verification-reject-button')), findsOneWidget);
    expect(find.text('Current review contract'), findsOneWidget);
    expect(find.textContaining('structured feedback is the canonical correction path'), findsOneWidget);
    expect(find.byKey(const ValueKey('verification-feedback-summary-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('verification-feedback-next-step-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('verification-document-feedback-pan')), findsOneWidget);
  });

  testWidgets('verification detail screen renders missing document rows with pending copy', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminVerificationDetailProvider('case-missing-docs').overrideWith((ref) async {
            return const AdminVerificationDetail(
              caseId: 'case-missing-docs',
              subjectId: 'user-2',
              subjectType: 'supplier_profile',
              subjectTypeLabel: 'Supplier',
              displayName: 'S2 Logistics',
              subjectLabel: 'Supplier profile verification case',
              caseStatus: 'submitted',
              submittedAt: null,
              lastReviewedAt: null,
              decisionSummary: '',
              reviewFeedbackSummary: '',
              reviewFeedbackNextStep: '',
              reviewFeedbackDocumentReasons: {},
              isClaimed: false,
              assignedAdminUserId: '',
              assignedAdminLabel: '',
              slaLabel: '12h left',
              subjectMetadata: {},
              documents: [
                VerificationDocument(
                  label: 'Aadhaar Front',
                  backendKey: 'aadhaar_front',
                  path: 'user-2/aadhaar-front.jpg',
                  signedUrl: 'https://signed/aadhaar-front',
                ),
                VerificationDocument(
                  label: 'PAN Card',
                  backendKey: 'pan',
                  path: '',
                ),
              ],
              events: [],
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AdminVerificationDetailScreen(caseId: 'case-missing-docs'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Verification documents'),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();

    expect(find.text('Document not uploaded yet.'), findsOneWidget);
    expect(find.text('user-2/aadhaar-front.jpg'), findsOneWidget);
    expect(find.text('Document not uploaded yet.'), findsOneWidget);
    expect(find.text('View document'), findsOneWidget);
  });

  testWidgets('verification detail screen validates reject reason and dispatches review action', (tester) async {
    late _FakeAdminVerificationActionController actionController;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminVerificationDetailProvider('case-1').overrideWith((ref) async {
            return const AdminVerificationDetail(
              caseId: 'case-1',
              subjectId: 'user-1',
              subjectType: 'supplier_profile',
              subjectTypeLabel: 'Supplier',
              displayName: 'S1 Logistics',
              subjectLabel: 'Supplier profile verification case',
              caseStatus: 'submitted',
              submittedAt: null,
              lastReviewedAt: null,
              decisionSummary: '',
              reviewFeedbackSummary: '',
              reviewFeedbackNextStep: '',
              reviewFeedbackDocumentReasons: {},
              isClaimed: false,
              assignedAdminUserId: '',
              assignedAdminLabel: '',
              slaLabel: '12h left',
              subjectMetadata: {},
              documents: [
                VerificationDocument(
                  label: 'PAN Card',
                  backendKey: 'pan',
                  path: 'user-1/pan.jpg',
                ),
              ],
              events: [],
            );
          }),
          adminVerificationActionProvider.overrideWith(() {
            actionController = _FakeAdminVerificationActionController();
            return actionController;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AdminVerificationDetailScreen(caseId: 'case-1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Review actions'),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('verification-reject-button')));
    await tester.pumpAndSettle();
    expect(find.text('Enter at least 10 characters so the rejection reason is properly recorded.'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('verification-reject-reason-field')), 'Documents are mismatched');
    await tester.enterText(find.byKey(const ValueKey('verification-feedback-summary-field')), 'Two items need correction');
    await tester.enterText(find.byKey(const ValueKey('verification-feedback-next-step-field')), 'Replace the rejected documents and resubmit.');
    await tester.enterText(find.byKey(const ValueKey('verification-document-feedback-pan')), 'PAN image unreadable');
    await tester.tap(find.byKey(const ValueKey('verification-reject-button')));
    await tester.pumpAndSettle();

    expect(actionController.called, isTrue);
    expect(actionController.lastDecision, VerificationReviewDecision.reject);
    expect(actionController.lastReason, 'Documents are mismatched');
    expect(actionController.lastFeedback, isNotNull);
    expect(actionController.lastFeedback!.summary, 'Two items need correction');
    expect(actionController.lastFeedback!.nextStep, 'Replace the rejected documents and resubmit.');
    expect(actionController.lastFeedback!.documentReasons['pan'], 'PAN image unreadable');
  });

  testWidgets('verification detail renders truck owner metadata and owner profile action', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminVerificationDetailProvider('case-truck-1').overrideWith((ref) async {
            return const AdminVerificationDetail(
              caseId: 'case-truck-1',
              subjectId: 'truck-1',
              subjectType: 'truck',
              subjectTypeLabel: 'Truck',
              displayName: 'MH12AB1234',
              subjectLabel: 'Truck verification case',
              profileLinkId: 'trucker-1',
              profileLinkLabel: 'Open owner profile',
              caseStatus: 'submitted',
              submittedAt: null,
              lastReviewedAt: null,
              decisionSummary: '',
              reviewFeedbackSummary: 'RC image needs a clearer upload',
              reviewFeedbackNextStep: 'Upload a clearer RC document.',
              reviewFeedbackDocumentReasons: {
                'rc_document': 'RC edges are cut off',
              },
              isClaimed: false,
              assignedAdminUserId: '',
              assignedAdminLabel: '',
              slaLabel: '12h left',
              subjectMetadata: {
                'Truck number': 'MH12AB1234',
                'Owner profile id': 'trucker-1',
                'Owner': 'Trucker One',
                'Owner mobile': '8888888888',
                'Owner verification': 'approved',
                'Owner registered': '2026-02-28 07:45',
                'Verified at': '2026-03-10 13:20',
              },
              documents: [
                VerificationDocument(
                  label: 'RC Document',
                  backendKey: 'rc_document',
                  path: 'truck-1/rc.jpg',
                  signedUrl: 'https://signed/rc',
                  feedbackReason: 'RC edges are cut off',
                ),
              ],
              events: [],
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AdminVerificationDetailScreen(caseId: 'case-truck-1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('MH12AB1234'), findsWidgets);
    expect(find.text('Trucker One'), findsOneWidget);
    expect(find.text('approved'), findsOneWidget);
    expect(find.text('2026-02-28 07:45'), findsOneWidget);
    expect(find.text('2026-03-10 13:20'), findsOneWidget);
    expect(find.text('Linked profile id'), findsOneWidget);
    expect(find.byKey(const ValueKey('verification-open-subject-profile-button')), findsOneWidget);
    expect(find.text('Open owner profile'), findsOneWidget);
    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Verification documents'),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    expect(find.text('Feedback RC edges are cut off'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Current review contract'),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('verification-feedback-summary-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('verification-feedback-next-step-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('verification-document-feedback-rc_document')), findsOneWidget);
    expect(find.textContaining('structured feedback can now capture document-aware correction guidance'), findsOneWidget);
  });

  testWidgets('verification detail dispatches structured feedback for truck rejections', (tester) async {
    late _FakeAdminVerificationActionController actionController;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminVerificationDetailProvider('case-truck-2').overrideWith((ref) async {
            return const AdminVerificationDetail(
              caseId: 'case-truck-2',
              subjectId: 'truck-2',
              subjectType: 'truck',
              subjectTypeLabel: 'Truck',
              displayName: 'MH14CD5678',
              subjectLabel: 'Truck verification case',
              caseStatus: 'submitted',
              submittedAt: null,
              lastReviewedAt: null,
              decisionSummary: '',
              reviewFeedbackSummary: '',
              reviewFeedbackNextStep: '',
              reviewFeedbackDocumentReasons: {},
              isClaimed: false,
              assignedAdminUserId: '',
              assignedAdminLabel: '',
              slaLabel: '12h left',
              subjectMetadata: {},
              documents: [
                VerificationDocument(
                  label: 'RC Document',
                  backendKey: 'rc_document',
                  path: 'truck-2/rc.jpg',
                ),
              ],
              events: [],
            );
          }),
          adminVerificationActionProvider.overrideWith(() {
            actionController = _FakeAdminVerificationActionController();
            return actionController;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AdminVerificationDetailScreen(caseId: 'case-truck-2'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Review actions'),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('verification-reject-reason-field')), 'RC document needs correction');
    await tester.enterText(find.byKey(const ValueKey('verification-feedback-summary-field')), 'Truck verification needs one corrected document');
    await tester.enterText(find.byKey(const ValueKey('verification-feedback-next-step-field')), 'Upload a clearer full-frame RC image and resubmit.');
    await tester.enterText(find.byKey(const ValueKey('verification-document-feedback-rc_document')), 'RC edges are cut off');
    await tester.tap(find.byKey(const ValueKey('verification-reject-button')));
    await tester.pumpAndSettle();

    expect(actionController.called, isTrue);
    expect(actionController.lastDecision, VerificationReviewDecision.reject);
    expect(actionController.lastReason, 'RC document needs correction');
    expect(actionController.lastFeedback, isNotNull);
    expect(actionController.lastFeedback!.summary, 'Truck verification needs one corrected document');
    expect(actionController.lastFeedback!.nextStep, 'Upload a clearer full-frame RC image and resubmit.');
    expect(actionController.lastFeedback!.documentReasons['rc_document'], 'RC edges are cut off');
  });
}
