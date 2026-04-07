import 'package:admin/src/core/repositories/admin_verification_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('verification detail/document models', () {
    test('VerificationDocument stores label/url fields', () {
      const doc = VerificationDocument(
        label: 'PAN Card',
        url: 'https://example.com/pan.jpg',
      );

      expect(doc.label, 'PAN Card');
      expect(doc.url, contains('pan.jpg'));
    });

    test('VerificationDetail stores metadata and document collection', () {
      const docs = [
        VerificationDocument(
          label: 'Aadhaar Front',
          url: 'https://example.com/aadhaar-front.jpg',
        ),
        VerificationDocument(
          label: 'Aadhaar Back',
          url: 'https://example.com/aadhaar-back.jpg',
        ),
      ];

      const detail = VerificationDetail(
        id: 'supplier-1',
        type: VerificationEntityType.supplier,
        title: 'Supplier One',
        status: 'pending',
        rejectionReason: '',
        metadata: {
          'Company': 'S1 Logistics',
          'GST': 'GST123',
        },
        documents: docs,
      );

      expect(detail.id, 'supplier-1');
      expect(detail.type, VerificationEntityType.supplier);
      expect(detail.metadata['Company'], 'S1 Logistics');
      expect(detail.documents.length, 2);
      expect(detail.documents.first.label, 'Aadhaar Front');
    });

    test('VerificationDetail supports rejected status and reason', () {
      const detail = VerificationDetail(
        id: 'truck-1',
        type: VerificationEntityType.truck,
        title: 'MH12AB1234',
        status: 'rejected',
        rejectionReason: 'invalid RC image',
        metadata: {
          'Body Type': 'open_body',
          'Tyres': '10',
        },
        documents: [],
      );

      expect(detail.status, 'rejected');
      expect(detail.rejectionReason, contains('invalid'));
      expect(detail.documents, isEmpty);
    });
  });
}
