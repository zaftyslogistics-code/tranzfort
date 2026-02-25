import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

import '../error/app_failure.dart';
import '../error/result.dart';

class StorageService {
  final SupabaseClient _supabase;

  StorageService(this._supabase);

  /// Uploads a file to a specific bucket and folder, returns the public URL.
  Future<Result<String>> uploadFile({
    required String bucketName,
    required String folderPath, // e.g., userId
    required File file,
    required String fileNamePrefix, // e.g., 'aadhaar_front'
  }) async {
    try {
      final ext = p.extension(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${fileNamePrefix}_$timestamp$ext';
      final fullPath = '$folderPath/$fileName';

      await _supabase.storage
          .from(bucketName)
          .upload(
            fullPath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final String publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(fullPath);
      return Success(publicUrl);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  /// Deletes a file from storage.
  Future<Result<void>> deleteFile({
    required String bucketName,
    required String filePath,
  }) async {
    try {
      await _supabase.storage.from(bucketName).remove([filePath]);
      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  /// Uploads a file to a precomputed path, e.g. `truck_id/rc.jpg`.
  Future<Result<String>> uploadFileAtPath({
    required String bucketName,
    required String fullPath,
    required File file,
  }) async {
    try {
      await _supabase.storage
          .from(bucketName)
          .upload(
            fullPath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(fullPath);
      return Success(publicUrl);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }
}
