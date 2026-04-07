import 'package:admin/src/core/repositories/admin_user_management_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('admin user detail models', () {
    test('VerificationDocument stores label and url', () {
      const document = VerificationDocument(
        label: 'Aadhaar Front',
        url: 'https://example.com/aadhaar-front.jpg',
      );

      expect(document.label, 'Aadhaar Front');
      expect(document.url, contains('aadhaar-front'));
    });

    test('AdminUserDetail stores profile metadata and related collections', () {
      const profile = AdminUserListItem(
        id: 'user-1',
        fullName: 'Supplier One',
        mobile: '9999999999',
        email: 'supplier@example.com',
        role: 'supplier',
        verificationStatus: 'approved',
        isBanned: false,
        banReason: '',
        loadsCount: 12,
      );
      final recentItems = [
        AdminRecentItem(
          id: 'load-1',
          title: 'Mumbai -> Pune',
          status: 'active',
          createdAt: DateTime(2026, 2, 27),
        ),
      ];
      const docs = [
        VerificationDocument(
          label: 'PAN Card',
          url: 'https://example.com/pan.jpg',
        ),
      ];

      final detail = AdminUserDetail(
        profile: profile,
        roleMetadata: const {
          'Company': 'S1 Logistics',
          'GST': 'GST123',
        },
        documents: docs,
        recentItems: recentItems,
      );

      expect(detail.profile.id, 'user-1');
      expect(detail.profile.loadsCount, 12);
      expect(detail.roleMetadata['Company'], 'S1 Logistics');
      expect(detail.documents.single.label, 'PAN Card');
      expect(detail.recentItems.single.title, contains('Mumbai'));
    });

    test('AdminRecentItem supports null createdAt for fallback rendering', () {
      const item = AdminRecentItem(
        id: 'trip-1',
        title: 'Trip abc123',
        status: 'processing',
        createdAt: null,
      );

      expect(item.id, 'trip-1');
      expect(item.status, 'processing');
      expect(item.createdAt, isNull);
    });
  });
}
