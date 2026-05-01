import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';

/// Attachment metadata model
class TicketAttachmentMetadata {
  final String id;
  final String ticketId;
  final String uploadedBy;
  final String fileName;
  final String filePath;
  final int fileSize;
  final String mimeType;
  final String? fileHash;
  final String uploadStatus; // 'pending', 'uploading', 'uploaded', 'failed'
  final String? uploadErrorMessage;
  final int retryCount;
  final int maxRetries;
  final String scanStatus; // 'pending', 'scanning', 'clean', 'infected', 'failed'
  final String? scanResult;
  final DateTime? scannedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  TicketAttachmentMetadata({
    required this.id,
    required this.ticketId,
    required this.uploadedBy,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.mimeType,
    this.fileHash,
    required this.uploadStatus,
    this.uploadErrorMessage,
    this.retryCount = 0,
    this.maxRetries = 3,
    required this.scanStatus,
    this.scanResult,
    this.scannedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TicketAttachmentMetadata.fromMap(Map<String, dynamic> map) {
    return TicketAttachmentMetadata(
      id: map['id'] as String,
      ticketId: map['ticket_id'] as String,
      uploadedBy: map['uploaded_by'] as String,
      fileName: map['file_name'] as String,
      filePath: map['file_path'] as String,
      fileSize: map['file_size'] as int,
      mimeType: map['mime_type'] as String,
      fileHash: map['file_hash'] as String?,
      uploadStatus: map['upload_status'] as String,
      uploadErrorMessage: map['upload_error_message'] as String?,
      retryCount: map['retry_count'] as int? ?? 0,
      maxRetries: map['max_retries'] as int? ?? 3,
      scanStatus: map['scan_status'] as String,
      scanResult: map['scan_result'] as String?,
      scannedAt: map['scanned_at'] != null ? DateTime.parse(map['scanned_at'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class SupportAttachmentUploadService {
  final SupabaseClient? _client;
  final DateTime Function() _now;
  final Future<XFile?> Function(ImageSource source) _pickImage;
  final Future<Uint8List> Function(XFile file) _readBytes;
  final Uint8List? Function(Uint8List bytes) _compressImage;
  final Future<void> Function(SupabaseClient client, String storagePath, Uint8List bytes) _uploadBinary;
  final Future<void> Function(SupabaseClient client, String oldPath, String newPath) _moveFile;

  SupportAttachmentUploadService(
    this._client, {
    DateTime Function()? nowFn,
    Future<XFile?> Function(ImageSource source)? pickImageFn,
    Future<Uint8List> Function(XFile file)? readBytesFn,
    Uint8List? Function(Uint8List bytes)? compressImageFn,
    Future<void> Function(SupabaseClient client, String storagePath, Uint8List bytes)? uploadBinaryFn,
    Future<void> Function(SupabaseClient client, String oldPath, String newPath)? moveFileFn,
  })  : _now = nowFn ?? DateTime.now,
        _pickImage = pickImageFn ?? _defaultPickImage,
        _readBytes = readBytesFn ?? _defaultReadBytes,
        _compressImage = compressImageFn ?? _defaultCompressImage,
        _uploadBinary = uploadBinaryFn ?? _defaultUploadBinary,
        _moveFile = moveFileFn ?? _defaultMoveFile;

  /// Upload multiple attachments with metadata, scan status tracking, and retry logic
  Future<Result<List<TicketAttachmentMetadata>>> uploadMultipleAttachments({
    required String ticketId,
    required String profileId,
    required List<ImageSource> sources,
    String pathSegment = 'support_ticket',
  }) async {
    final normalizedTicketId = ticketId.trim();
    final normalizedProfileId = profileId.trim();
    final normalizedPathSegment = pathSegment.trim().isEmpty ? 'support_ticket' : pathSegment.trim();

    if (normalizedTicketId.isEmpty || normalizedProfileId.isEmpty) {
      return const Failure<List<TicketAttachmentMetadata>>(
        ValidationFailure(
          message: 'Ticket ID and profile ID are required',
          fieldErrors: {'ticket_id': 'Ticket ID is required', 'profile_id': 'Profile ID is required'},
        ),
      );
    }

    if (_client == null) {
      return const Failure<List<TicketAttachmentMetadata>>(UnauthorizedFailure());
    }

    final List<TicketAttachmentMetadata> attachments = [];
    final List<String> errors = [];

    for (final source in sources) {
      final result = await _uploadSingleAttachment(
        ticketId: normalizedTicketId,
        profileId: normalizedProfileId,
        source: source,
        pathSegment: normalizedPathSegment,
      );

      result.when(
        success: (attachment) => attachments.add(attachment),
        failure: (failure) => errors.add(failure.message),
      );
    }

    if (attachments.isEmpty && errors.isNotEmpty) {
      return Failure<List<TicketAttachmentMetadata>>(
        ServerFailure(message: 'Failed to upload all attachments: ${errors.join(", ")}'),
      );
    }

    return Success<List<TicketAttachmentMetadata>>(attachments);
  }

  /// Upload a single attachment with retry logic
  Future<Result<TicketAttachmentMetadata>> _uploadSingleAttachment({
    required String ticketId,
    required String profileId,
    required ImageSource source,
    required String pathSegment,
    int retryCount = 0,
    int maxRetries = 3,
  }) async {
    try {
      // Create attachment record in pending state
      final attachmentId = await _createAttachmentRecord(
        ticketId: ticketId,
        profileId: profileId,
        uploadStatus: 'uploading',
        retryCount: retryCount,
        maxRetries: maxRetries,
      );

      if (attachmentId == null) {
        return const Failure<TicketAttachmentMetadata>(
          ServerFailure(message: 'Failed to create attachment record'),
        );
      }

      // Pick, compress, and upload the file
      final file = await _pickImage(source);
      if (file == null) {
        await _updateAttachmentStatus(attachmentId, 'failed', 'No file selected');
        return const Failure<TicketAttachmentMetadata>(
          ValidationFailure(message: 'No file selected'),
        );
      }

      final originalBytes = await _readBytes(file);
      final compressedBytes = _compressImage(originalBytes);
      if (compressedBytes == null || compressedBytes.isEmpty) {
        await _updateAttachmentStatus(attachmentId, 'failed', 'Image compression failed');
        return const Failure<TicketAttachmentMetadata>(
          BusinessRuleFailure(message: 'We could not prepare the evidence image. Please try another photo.'),
        );
      }

      // Calculate file hash for deduplication
      final fileHash = sha256.convert(compressedBytes).toString();

      // Upload to storage
      final timestamp = _now().toUtc().millisecondsSinceEpoch;
      final storagePath = '$profileId/$pathSegment/$ticketId/attachment_$timestamp.jpg';
      
      await _uploadBinary(_client!, storagePath, compressedBytes);

      // Update attachment record with success
      final success = await _updateAttachmentWithMetadata(
        attachmentId: attachmentId,
        fileName: file.name,
        filePath: storagePath,
        fileSize: compressedBytes.length,
        mimeType: 'image/jpeg',
        fileHash: fileHash,
        uploadStatus: 'uploaded',
      );

      if (!success) {
        return const Failure<TicketAttachmentMetadata>(
          ServerFailure(message: 'Failed to update attachment metadata'),
        );
      }

      // Fetch the updated attachment record
      final attachment = await _fetchAttachmentById(attachmentId);
      if (attachment == null) {
        return const Failure<TicketAttachmentMetadata>(
          ServerFailure(message: 'Failed to fetch attachment record'),
        );
      }

      return Success<TicketAttachmentMetadata>(attachment);
    } catch (error, stackTrace) {
      // Retry logic
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 1)); // Exponential backoff
        return _uploadSingleAttachment(
          ticketId: ticketId,
          profileId: profileId,
          source: source,
          pathSegment: pathSegment,
          retryCount: retryCount + 1,
          maxRetries: maxRetries,
        );
      }

      return Failure<TicketAttachmentMetadata>(
        ServerFailure(
          message: 'Failed to upload attachment after $maxRetries retries',
          debugInfo: '$error\n$stackTrace',
        ),
      );
    }
  }

  /// Create attachment record in database
  Future<String?> _createAttachmentRecord({
    required String ticketId,
    required String profileId,
    required String uploadStatus,
    required int retryCount,
    required int maxRetries,
  }) async {
    try {
      final response = await _client!.from('ticket_attachments').insert({
        'ticket_id': ticketId,
        'uploaded_by': profileId,
        'file_name': '',
        'file_path': '',
        'file_size': 0,
        'mime_type': '',
        'upload_status': uploadStatus,
        'retry_count': retryCount,
        'max_retries': maxRetries,
        'scan_status': 'pending',
      }).select('id').single();

      return response['id'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Update attachment status
  Future<bool> _updateAttachmentStatus(
    String attachmentId,
    String status,
    String? errorMessage,
  ) async {
    try {
      await _client!.from('ticket_attachments').update({
        'upload_status': status,
        'upload_error_message': errorMessage,
        'updated_at': _now().toIso8601String(),
      }).eq('id', attachmentId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update attachment with metadata after successful upload
  Future<bool> _updateAttachmentWithMetadata({
    required String attachmentId,
    required String fileName,
    required String filePath,
    required int fileSize,
    required String mimeType,
    required String fileHash,
    required String uploadStatus,
  }) async {
    try {
      await _client!.from('ticket_attachments').update({
        'file_name': fileName,
        'file_path': filePath,
        'file_size': fileSize,
        'mime_type': mimeType,
        'file_hash': fileHash,
        'upload_status': uploadStatus,
        'updated_at': _now().toIso8601String(),
      }).eq('id', attachmentId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetch attachment by ID
  Future<TicketAttachmentMetadata?> _fetchAttachmentById(String attachmentId) async {
    try {
      final response = await _client!.from('ticket_attachments').select('*').eq('id', attachmentId).single();
      return TicketAttachmentMetadata.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Fetch all attachments for a ticket
  Future<Result<List<TicketAttachmentMetadata>>> fetchTicketAttachments(String ticketId) async {
    if (_client == null) {
      return const Failure<List<TicketAttachmentMetadata>>(UnauthorizedFailure());
    }

    try {
      final response = await _client!.rpc('get_ticket_attachments', params: {'p_ticket_id': ticketId});
      
      if (response == null || response is! List) {
        return const Success<List<TicketAttachmentMetadata>>([]);
      }

      final attachments = (response as List)
          .map((item) => TicketAttachmentMetadata.fromMap(item as Map<String, dynamic>))
          .toList();

      return Success<List<TicketAttachmentMetadata>>(attachments);
    } catch (e, stackTrace) {
      return Failure<List<TicketAttachmentMetadata>>(
        ServerFailure(message: 'Failed to fetch attachments', debugInfo: '$e\n$stackTrace'),
      );
    }
  }

  /// Delete an attachment
  Future<Result<bool>> deleteAttachment(String attachmentId) async {
    if (_client == null) {
      return const Failure<bool>(UnauthorizedFailure());
    }

    try {
      // Fetch attachment to get file path
      final attachment = await _fetchAttachmentById(attachmentId);
      if (attachment == null) {
        return const Failure<bool>(NotFoundFailure());
      }

      // Delete from storage
      await _client!.storage.from('support-attachments').remove([attachment.filePath]);

      // Delete from database
      await _client!.from('ticket_attachments').delete().eq('id', attachmentId);

      return const Success<bool>(true);
    } catch (e, stackTrace) {
      return Failure<bool>(
        ServerFailure(message: 'Failed to delete attachment', debugInfo: '$e\n$stackTrace'),
      );
    }
  }

  /// Retry failed attachment upload
  Future<Result<TicketAttachmentMetadata>> retryAttachmentUpload({
    required String attachmentId,
    required String profileId,
    required ImageSource source,
    required String pathSegment,
  }) async {
    if (_client == null) {
      return const Failure<TicketAttachmentMetadata>(UnauthorizedFailure());
    }

    try {
      // Fetch attachment to get ticket ID
      final attachment = await _fetchAttachmentById(attachmentId);
      if (attachment == null) {
        return const Failure<TicketAttachmentMetadata>(NotFoundFailure());
      }

      // Check if max retries exceeded
      if (attachment.retryCount >= attachment.maxRetries) {
        return const Failure<TicketAttachmentMetadata>(
          BusinessRuleFailure(message: 'Maximum retry attempts exceeded'),
        );
      }

      // Retry upload with incremented retry count
      return _uploadSingleAttachment(
        ticketId: attachment.ticketId,
        profileId: profileId,
        source: source,
        pathSegment: pathSegment,
        retryCount: attachment.retryCount + 1,
        maxRetries: attachment.maxRetries,
      );
    } catch (e, stackTrace) {
      return Failure<TicketAttachmentMetadata>(
        ServerFailure(message: 'Failed to retry attachment upload', debugInfo: '$e\n$stackTrace'),
      );
    }
  }

  Future<Result<String?>> pickCompressAndUploadAttachment({
    required String profileId,
    required ImageSource source,
    String pathSegment = 'report_issue',
  }) async {
    final normalizedProfileId = profileId.trim();
    final normalizedPathSegment = pathSegment.trim().isEmpty ? 'report_issue' : pathSegment.trim();
    if (normalizedProfileId.isEmpty) {
      return const Failure<String?>(
        ValidationFailure(
          message: 'Profile id is required',
          fieldErrors: {'profile_id': 'Profile id is required'},
        ),
      );
    }

    try {
      final file = await _pickImage(source);
      if (file == null) {
        return const Success<String?>(null);
      }

      final originalBytes = await _readBytes(file);
      final compressedBytes = _compressImage(originalBytes);
      if (compressedBytes == null || compressedBytes.isEmpty) {
        return const Failure<String?>(
          BusinessRuleFailure(message: 'We could not prepare the evidence image. Please try another photo.'),
        );
      }

      if (_client == null) {
        return const Failure<String?>(UnauthorizedFailure());
      }

      final timestamp = _now().toUtc().millisecondsSinceEpoch;
      final storagePath = '$normalizedProfileId/$normalizedPathSegment/evidence_$timestamp.jpg';
      await _uploadBinary(_client, storagePath, compressedBytes);
      return Success<String?>(storagePath);
    } on StorageException catch (error) {
      return Failure<String?>(
        ServerFailure(
          message: error.message.trim().isEmpty
              ? 'Unable to upload the report evidence right now. Please try again.'
              : error.message.trim(),
          debugInfo: error.toString(),
        ),
      );
    } on FileSystemException catch (error) {
      return Failure<String?>(NetworkFailure(debugInfo: error.toString()));
    } on TimeoutException catch (error) {
      return Failure<String?>(NetworkFailure(debugInfo: error.toString()));
    } catch (error) {
      return Failure<String?>(UnknownFailure(debugInfo: error.toString()));
    }
  }

  Future<Result<String>> relocateAttachment({
    required String currentPath,
    required String targetPathSegment,
  }) async {
    final normalizedCurrentPath = currentPath.trim();
    final normalizedTargetSegment = targetPathSegment.trim();
    
    if (normalizedCurrentPath.isEmpty || normalizedTargetSegment.isEmpty) {
      return const Failure<String>(
        ValidationFailure(
          message: 'Both current path and target segment are required',
          fieldErrors: {'paths': 'Both current path and target segment are required'},
        ),
      );
    }

    if (_client == null) {
      return const Failure<String>(UnauthorizedFailure());
    }

    final parts = normalizedCurrentPath.split('/');
    if (parts.length < 3) {
      return const Failure<String>(
        BusinessRuleFailure(message: 'Cannot relocate an attachment with an invalid path format'),
      );
    }

    final profileId = parts[0];
    final filename = parts.last;
    final newPath = '$profileId/$normalizedTargetSegment/$filename';

    try {
      await _moveFile(_client, normalizedCurrentPath, newPath);
      return Success<String>(newPath);
    } on StorageException catch (error) {
      return Failure<String>(
        ServerFailure(
          message: error.message.trim().isEmpty
              ? 'Unable to finalize the attachment right now. Please try again.'
              : error.message.trim(),
          debugInfo: error.toString(),
        ),
      );
    } on FileSystemException catch (error) {
      return Failure<String>(NetworkFailure(debugInfo: error.toString()));
    } on TimeoutException catch (error) {
      return Failure<String>(NetworkFailure(debugInfo: error.toString()));
    } catch (error) {
      return Failure<String>(UnknownFailure(debugInfo: error.toString()));
    }
  }

  static Future<XFile?> _defaultPickImage(ImageSource source) {
    return ImagePicker().pickImage(source: source);
  }

  static Future<Uint8List> _defaultReadBytes(XFile file) {
    return file.readAsBytes();
  }

  static Uint8List? _defaultCompressImage(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return null;
    }

    final resized = decoded.width >= decoded.height
        ? img.copyResize(decoded, width: decoded.width > 1600 ? 1600 : decoded.width)
        : img.copyResize(decoded, height: decoded.height > 1600 ? 1600 : decoded.height);

    final encoded = img.encodeJpg(resized, quality: 85);
    return Uint8List.fromList(encoded);
  }

  static Future<void> _defaultUploadBinary(
    SupabaseClient client,
    String storagePath,
    Uint8List bytes,
  ) {
    return client.storage.from('support-attachments').uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );
  }

  static Future<void> _defaultMoveFile(
    SupabaseClient client,
    String oldPath,
    String newPath,
  ) {
    return client.storage.from('support-attachments').move(oldPath, newPath);
  }
}

final supportAttachmentUploadServiceProvider = Provider<SupportAttachmentUploadService>((ref) {
  return SupportAttachmentUploadService(ref.watch(supabaseClientProvider));
});
