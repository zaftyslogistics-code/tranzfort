import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'verification_wizard_draft.dart';

/// Secure encrypted storage for verification wizard drafts.
///
/// Replaces [SharedPreferences] for draft persistence because the draft
/// contains sensitive PII (Aadhaar, PAN numbers) and document paths that
/// must not be stored in plaintext on the device.
///
/// Uses platform-specific secure storage:
/// - iOS: Keychain (kSecClassGenericPassword)
/// - Android: EncryptedSharedPreferences (Android keystore-backed)
class VerificationDraftSecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  String _key(String userId, String roleName) =>
      'verification_wizard_draft_v1_secure:$userId:$roleName';

  /// Persist [draft] for the given user. If [draft] is empty, clears storage.
  Future<void> save({
    required String? userId,
    required String roleName,
    required VerificationDraft draft,
  }) async {
    final key = _key(userId ?? roleName, roleName);
    if (draft.isEmpty) {
      await _storage.delete(key: key);
      return;
    }
    await _storage.write(key: key, value: jsonEncode(draft.toJson()));
  }

  /// Load the previously persisted draft, or `null` if none exists.
  Future<VerificationDraft?> load({
    required String? userId,
    required String roleName,
  }) async {
    final key = _key(userId ?? roleName, roleName);
    final encoded = await _storage.read(key: key);
    if (encoded == null || encoded.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) {
        await _storage.delete(key: key);
        return null;
      }
      return VerificationDraft.fromJson(decoded);
    } catch (_) {
      await _storage.delete(key: key);
      return null;
    }
  }

  /// Remove any stored draft for the given user.
  Future<void> clear({
    required String? userId,
    required String roleName,
  }) async {
    final key = _key(userId ?? roleName, roleName);
    await _storage.delete(key: key);
  }
}
