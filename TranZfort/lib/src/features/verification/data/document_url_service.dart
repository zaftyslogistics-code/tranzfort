import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for creating signed URLs for document images.
/// Extracted to allow mocking in tests.
class DocumentUrlService {
  final SupabaseClient? _client;

  const DocumentUrlService(this._client);

  /// Creates a signed URL for accessing a document image.
  /// Returns null if the client is not available or if the operation fails.
  Future<String?> createSignedUrl(String path) async {
    if (_client == null) {
      return null;
    }

    try {
      // Try verification-documents bucket first
      try {
        return await _client.storage
            .from('verification-documents')
            .createSignedUrl(path, 3600);
      } catch (_) {
        // Fallback to truck-documents bucket
        return await _client.storage
            .from('truck-documents')
            .createSignedUrl(path, 3600);
      }
    } catch (_) {
      return null;
    }
  }
}

/// Provider for the document URL service.
final documentUrlServiceProvider = Provider<DocumentUrlService>((ref) {
  // Get Supabase client from the context - this will be null in tests
  final client = Supabase.instance.client;
  return DocumentUrlService(client);
});
