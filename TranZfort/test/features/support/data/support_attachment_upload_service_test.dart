import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/features/support/data/support_attachment_upload_service.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  test('support attachment upload returns null success when user cancels image picking', () async {
    final service = SupportAttachmentUploadService(
      null,
      pickImageFn: (_) async => null,
      readBytesFn: (_) async => throw StateError('unused'),
      compressImageFn: (_) => throw StateError('unused'),
      uploadBinaryFn: (client, storagePath, bytes) async => throw StateError('unused'),
    );

    final result = await service.pickCompressAndUploadAttachment(
      profileId: 'profile-1',
      source: ImageSource.gallery,
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isNull);
  });

  test('support attachment upload writes deterministic storage path for report evidence', () async {
    String? capturedPath;
    final client = _MockSupabaseClient();
    final service = SupportAttachmentUploadService(
      client,
      nowFn: () => DateTime.utc(2026, 3, 10, 16, 0, 0),
      pickImageFn: (_) async => XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'evidence.jpg', mimeType: 'image/jpeg'),
      readBytesFn: (_) async => Uint8List.fromList([1, 2, 3]),
      compressImageFn: (bytes) => bytes,
      uploadBinaryFn: (client, storagePath, bytes) async {
        capturedPath = storagePath;
      },
    );

    final result = await service.pickCompressAndUploadAttachment(
      profileId: 'user-77',
      source: ImageSource.camera,
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 'user-77/report_issue/evidence_1773158400000.jpg');
    expect(capturedPath, 'user-77/report_issue/evidence_1773158400000.jpg');
  });

  test('support attachment upload supports ticket-scoped path segments', () async {
    String? capturedPath;
    final client = _MockSupabaseClient();
    final service = SupportAttachmentUploadService(
      client,
      nowFn: () => DateTime.utc(2026, 3, 10, 16, 0, 0),
      pickImageFn: (_) async => XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'evidence.jpg', mimeType: 'image/jpeg'),
      readBytesFn: (_) async => Uint8List.fromList([1, 2, 3]),
      compressImageFn: (bytes) => bytes,
      uploadBinaryFn: (client, storagePath, bytes) async {
        capturedPath = storagePath;
      },
    );

    final result = await service.pickCompressAndUploadAttachment(
      profileId: 'user-77',
      source: ImageSource.gallery,
      pathSegment: 'support_ticket/ticket-9',
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 'user-77/support_ticket/ticket-9/evidence_1773158400000.jpg');
    expect(capturedPath, 'user-77/support_ticket/ticket-9/evidence_1773158400000.jpg');
  });

  test('relocateAttachment moves file to target ticket-scoped path', () async {
    String? capturedOldPath;
    String? capturedNewPath;
    final client = _MockSupabaseClient();
    
    final service = SupportAttachmentUploadService(
      client,
      moveFileFn: (client, oldPath, newPath) async {
        capturedOldPath = oldPath;
        capturedNewPath = newPath;
      },
    );

    final result = await service.relocateAttachment(
      currentPath: 'user-77/report_issue/evidence_1773158400000.jpg',
      targetPathSegment: 'support_ticket/ticket-123',
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 'user-77/support_ticket/ticket-123/evidence_1773158400000.jpg');
    expect(capturedOldPath, 'user-77/report_issue/evidence_1773158400000.jpg');
    expect(capturedNewPath, 'user-77/support_ticket/ticket-123/evidence_1773158400000.jpg');
  });

  test('relocateAttachment fails if current path has invalid format', () async {
    final client = _MockSupabaseClient();
    final service = SupportAttachmentUploadService(
      client,
      moveFileFn: (client, oldPath, newPath) async {},
    );

    final result = await service.relocateAttachment(
      currentPath: 'invalid_path.jpg',
      targetPathSegment: 'support_ticket/ticket-123',
    );

    expect(result.isFailure, isTrue);
  });
}
