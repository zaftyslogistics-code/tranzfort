import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/app_failure.dart';
import '../error/result.dart';

typedef PickImageFn = Future<XFile?> Function(ImageSource source);
typedef ReadBytesFn = Future<Uint8List> Function(XFile file);
typedef CompressImageFn = Uint8List? Function(Uint8List bytes);
typedef UploadBinaryFn = Future<void> Function(SupabaseClient client, String storagePath, Uint8List bytes);

class ImageUploadServiceDefaults {
  ImageUploadServiceDefaults._();

  static const int maxImageDimension = 1200;
  static const int jpegQuality = 85;

  static Future<XFile?> pickImage(ImageSource source) {
    return ImagePicker().pickImage(source: source);
  }

  static Future<Uint8List> readBytes(XFile file) {
    return file.readAsBytes();
  }

  /// Gallery picks on Android often omit [XFile.mimeType]; infer from bytes/name.
  static String? resolveImageMimeType(
    XFile file,
    Uint8List bytes, {
    List<String> allowedMimeTypes = const ['image/jpeg', 'image/png'],
  }) {
    final fromPicker = file.mimeType?.trim().toLowerCase();
    if (fromPicker != null && allowedMimeTypes.contains(fromPicker)) {
      return fromPicker;
    }

    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }

    final name = file.name.trim().toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (name.endsWith('.png')) {
      return 'image/png';
    }

    return fromPicker;
  }

  static Uint8List? compressImage(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return null;
    }

    final resized = decoded.width >= decoded.height
        ? img.copyResize(decoded, width: decoded.width > maxImageDimension ? maxImageDimension : decoded.width)
        : img.copyResize(decoded, height: decoded.height > maxImageDimension ? maxImageDimension : decoded.height);

    return Uint8List.fromList(img.encodeJpg(resized, quality: jpegQuality));
  }
}

class ImageUploadWorkflow {
  ImageUploadWorkflow._();

  static Future<Result<String?>> pickCompressAndUpload({
    required SupabaseClient? client,
    required ImageSource source,
    required PickImageFn pickImage,
    required ReadBytesFn readBytes,
    required CompressImageFn compressImage,
    required UploadBinaryFn uploadBinary,
    required String storagePath,
    required String invalidImageMessage,
    required String storageFailureFallbackMessage,
  }) async {
    try {
      final file = await pickImage(source);
      if (file == null) {
        return const Success<String?>(null);
      }

      final originalBytes = await readBytes(file);
      final compressedBytes = compressImage(originalBytes);
      if (compressedBytes == null || compressedBytes.isEmpty) {
        return Failure<String?>(BusinessRuleFailure(message: invalidImageMessage));
      }

      if (client == null) {
        return const Failure<String?>(UnauthorizedFailure());
      }

      await uploadBinary(client, storagePath, compressedBytes);
      return Success<String?>(storagePath);
    } on StorageException catch (error) {
      return Failure<String?>(
        ServerFailure(
          message: error.message.trim().isEmpty ? storageFailureFallbackMessage : error.message.trim(),
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
}
