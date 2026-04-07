import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:admin/src/core/config/supabase_config.dart';
import 'package:admin/src/core/repositories/admin_verification_repository.dart';
import 'package:admin/src/features/verification/providers/verification_detail_provider.dart';
import 'package:admin/src/features/verification/providers/verification_queue_provider.dart';
import 'package:admin/src/features/verification/presentation/verification_queue_screen.dart';
import 'package:admin/src/features/verification/presentation/verification_detail_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Admin verification integration tests', () {
    testWidgets('A-VER-01: verification queue render with pending supplier item', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [supabaseConfiguredProvider.overrideWithValue(false)],
          child: const MaterialApp(home: VerificationQueueScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Verification Queue'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('A-VER-02: open supplier verification case from queue', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            verificationQueuesProvider.overrideWith(
              () => _FakeVerificationQueuesNotifier(
                const VerificationQueues(
                  suppliers: [
                    VerificationQueueItem(
                      id: 'user-123',
                      type: VerificationEntityType.supplier,
                      primaryLabel: 'Test Supplier',
                      secondaryLabel: 'Test Company',
                      submittedAt: null,
                    ),
                  ],
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: VerificationQueueScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Supplier'));
      await tester.pumpAndSettle();

      expect(find.byType(VerificationDetailScreen), findsOneWidget);
    });

    testWidgets('A-VER-02A: admin can preview uploaded supplier document', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            verificationDetailProvider(
              const VerificationDetailArgs(VerificationEntityType.supplier, 'ver-123'),
            ).overrideWith(
              (ref) async => const VerificationDetail(
                id: 'ver-123',
                type: VerificationEntityType.supplier,
                title: 'Test Supplier',
                status: 'pending',
                rejectionReason: '',
                metadata: {'Company': 'Test Company'},
                documents: [
                  VerificationDocument(
                    label: 'GST Certificate',
                    url: 'https://example.com/gst.pdf',
                  ),
                ],
              ),
            ),
          ],
          child: const MaterialApp(
            home: VerificationDetailScreen(
              type: VerificationEntityType.supplier,
              id: 'ver-123',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('GST Certificate'), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('A-VER-02B: missing document URL shows safe fallback state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            verificationDetailProvider(
              const VerificationDetailArgs(VerificationEntityType.supplier, 'ver-123'),
            ).overrideWith(
              (ref) async => const VerificationDetail(
                id: 'ver-123',
                type: VerificationEntityType.supplier,
                title: 'Test Supplier',
                status: 'pending',
                rejectionReason: '',
                metadata: {'Company': 'Test Company'},
                documents: [
                  VerificationDocument(
                    label: 'GST Certificate',
                    url: '',
                  ),
                ],
              ),
            ),
          ],
          child: const MaterialApp(
            home: VerificationDetailScreen(
              type: VerificationEntityType.supplier,
              id: 'ver-123',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Document not available'), findsOneWidget);
    });

    testWidgets('A-VER-05: open trucker verification case from queue', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            verificationQueuesProvider.overrideWith(
              () => _FakeVerificationQueuesNotifier(
                const VerificationQueues(
                  truckers: [
                    VerificationQueueItem(
                      id: 'user-456',
                      type: VerificationEntityType.trucker,
                      primaryLabel: 'Test Trucker',
                      secondaryLabel: '',
                      submittedAt: null,
                    ),
                  ],
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: VerificationQueueScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Trucker'));
      await tester.pumpAndSettle();

      expect(find.byType(VerificationDetailScreen), findsOneWidget);
    });

    testWidgets('A-VER-05A: admin can preview uploaded trucker document', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            verificationDetailProvider(
              const VerificationDetailArgs(VerificationEntityType.trucker, 'ver-456'),
            ).overrideWith(
              (ref) async => const VerificationDetail(
                id: 'ver-456',
                type: VerificationEntityType.trucker,
                title: 'Test Trucker',
                status: 'pending',
                rejectionReason: '',
                metadata: {'DL Number': 'DL-123'},
                documents: [
                  VerificationDocument(
                    label: 'Driving License',
                    url: 'https://example.com/license.jpg',
                  ),
                ],
              ),
            ),
          ],
          child: const MaterialApp(
            home: VerificationDetailScreen(
              type: VerificationEntityType.trucker,
              id: 'ver-456',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Driving License'), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

  });
}

class _FakeVerificationQueuesNotifier extends VerificationQueuesNotifier {
  _FakeVerificationQueuesNotifier(this._value);

  final VerificationQueues _value;

  @override
  Future<VerificationQueues> build() async => _value;
}
