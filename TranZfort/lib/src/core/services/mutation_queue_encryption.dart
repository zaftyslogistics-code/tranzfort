import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

/// Encryption service for mutation queue payloads.
///
/// Uses AES-256-GCM with a random key stored in flutter_secure_storage.
/// Each payload is encrypted with a random IV that is prepended to the ciphertext.
class MutationQueueEncryption {
  static const _keyStorageKey = 'mutation_queue_encryption_key';
  static const _keyLength = 32; // 256 bits
  static const _ivLength = 12; // 96 bits for GCM
  static const _tagLength = 16; // 128 bits authentication tag

  final FlutterSecureStorage _secureStorage;

  MutationQueueEncryption({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Encrypt a plaintext payload string.
  /// Returns base64-encoded ciphertext with IV prepended.
  Future<String> encrypt(String plaintext) async {
    final key = await _getOrCreateKey();
    final iv = _generateRandomBytes(_ivLength);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(key),
          _tagLength * 8,
          iv,
          Uint8List(0),
        ),
      );

    final plainBytes = Uint8List.fromList(utf8.encode(plaintext));
    final encrypted = cipher.process(plainBytes);

    // Prepend IV to ciphertext
    final result = Uint8List(iv.length + encrypted.length);
    result.setAll(0, iv);
    result.setAll(iv.length, encrypted);

    return base64.encode(result);
  }

  /// Decrypt a base64-encoded ciphertext with prepended IV.
  /// Returns the original plaintext string.
  Future<String?> decrypt(String encryptedBase64) async {
    try {
      final key = await _getOrCreateKey();
      final combined = base64.decode(encryptedBase64);

      if (combined.length < _ivLength + _tagLength) {
        return null;
      }

      final iv = combined.sublist(0, _ivLength);
      final ciphertext = combined.sublist(_ivLength);

      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          false,
          AEADParameters(
            KeyParameter(key),
            _tagLength * 8,
            iv,
            Uint8List(0),
          ),
        );

      final decrypted = cipher.process(ciphertext);
      return utf8.decode(decrypted);
    } catch (_) {
      return null;
    }
  }

  /// Delete the encryption key (e.g., on logout).
  Future<void> deleteKey() async {
    await _secureStorage.delete(key: _keyStorageKey);
  }

  Future<Uint8List> _getOrCreateKey() async {
    final existingKey = await _secureStorage.read(key: _keyStorageKey);
    if (existingKey != null) {
      return base64.decode(existingKey);
    }

    final newKey = _generateRandomBytes(_keyLength);
    await _secureStorage.write(
      key: _keyStorageKey,
      value: base64.encode(newKey),
    );
    return newKey;
  }

  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }
}
